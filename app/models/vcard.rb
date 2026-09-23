# Parses and writes vCard text (RFC 2426 / RFC 6350). A card keeps every property in order, with its
# group, parameters, and raw (still escaped) value, so a card that is parsed and written back loses nothing.
module Vcard
  class ParseError < StandardError; end

  CRLF = "\r\n".freeze

  # Splits text that holds one or more vCards. Returns the raw text of each card.
  def self.split(text)
    cards = []
    current = nil

    unfold(text).each do |line|
      if line.match?(/\ABEGIN:VCARD\z/i)
        current = [ line ]
      elsif current
        current << line
        if line.match?(/\AEND:VCARD\z/i)
          cards << current.join(CRLF) + CRLF
          current = nil
        end
      end
    end

    cards
  end

  def self.unfold(text)
    text.to_s.sub(/\A﻿/, "").gsub(/\r?\n[ \t]/, "").split(/\r?\n/).reject(&:empty?)
  end

  # Backslash escaping for TEXT values.
  def self.escape(value)
    value.to_s.gsub(/\r\n?/, "\n").gsub(/[\\\n,;]/) { |char| char == "\n" ? "\\n" : "\\#{char}" }
  end

  def self.unescape(value)
    value.to_s.gsub(/\\([\\nN,;:])/) { %w[n N].include?($1) ? "\n" : $1 }
  end

  # Splits a raw value on unescaped separators (";" for structured values, "," for lists).
  def self.split_raw(value, separator)
    parts = [ +"" ]
    escaped = false

    value.to_s.each_char do |char|
      if escaped
        parts.last << "\\" << char
        escaped = false
      elsif char == "\\"
        escaped = true
      elsif char == separator
        parts << +""
      else
        parts.last << char
      end
    end
    parts.last << "\\" if escaped

    parts
  end

  class Property
    attr_accessor :group, :name, :params, :value

    # params is an ordered array of [NAME, value] pairs; a parameter may repeat.
    def initialize(name, value, params: [], group: nil)
      @name = name.upcase
      @value = value.to_s
      @params = params
      @group = group
    end

    def self.parse(line)
      head, value = split_head(line)
      raise ParseError, "Missing ':' in line: #{line.truncate(60)}" unless value

      name_part, *param_parts = split_params(head)
      group, name = name_part.include?(".") ? name_part.split(".", 2) : [ nil, name_part ]
      raise ParseError, "Invalid property name: #{name_part.truncate(40)}" unless name.match?(/\A[A-Za-z0-9-]+\z/)

      params = param_parts.flat_map do |part|
        key, raw = part.split("=", 2)
        if raw.nil?
          [ [ "TYPE", key ] ] # vCard 2.1 bare parameter, such as TEL;CELL
        else
          split_param_values(raw).map { |v| [ key.upcase, v ] }
        end
      end

      new(name, value, params: params, group: group)
    end

    # Text of the value with escapes removed.
    def text
      Vcard.unescape(value)
    end

    # Unescaped components of a structured value such as N or ADR.
    def components
      Vcard.split_raw(value, ";").map { |part| Vcard.unescape(part) }
    end

    def param(key)
      params.find { |k, _| k == key.upcase }&.last
    end

    def param_values(key)
      params.select { |k, _| k == key.upcase }.flat_map { |_, v| v.split(",") }
    end

    def types
      param_values("TYPE").map(&:downcase)
    end

    def to_s
      head = [ group, name ].compact.join(".")
      params.each { |key, v| head << ";#{key}=#{quote_param(v)}" }
      Vcard.fold("#{head}:#{value}")
    end

    private
      def quote_param(value)
        value.match?(/[:;,]/) ? %("#{value.delete('"')}") : value
      end

      class << self
        private
          # Finds the first ":" outside double quotes.
          def split_head(line)
            quoted = false
            line.each_char.with_index do |char, index|
              quoted = !quoted if char == '"'
              return [ line[0...index], line[(index + 1)..] ] if char == ":" && !quoted
            end
            [ line, nil ]
          end

          def split_params(head)
            parts = [ +"" ]
            quoted = false
            head.each_char do |char|
              quoted = !quoted if char == '"'
              if char == ";" && !quoted
                parts << +""
              else
                parts.last << char
              end
            end
            parts
          end

          def split_param_values(raw)
            raw.scan(/"[^"]*"|[^,]+/).map { |v| v.delete('"') }
          end
      end
  end

  # Folds a content line at 75 octets without splitting a UTF-8 character.
  def self.fold(line)
    return line if line.bytesize <= 75

    lines = [ +"" ]
    limit = 75
    line.each_char do |char|
      if lines.last.bytesize + char.bytesize > limit
        lines << +" "
        limit = 75
      end
      lines.last << char
    end
    lines.join(CRLF)
  end

  class Card
    attr_reader :properties

    def self.parse(text)
      lines = Vcard.unfold(text)
      raise ParseError, "Expected BEGIN:VCARD" unless lines.first&.match?(/\ABEGIN:VCARD\z/i)
      raise ParseError, "Expected END:VCARD" unless lines.last&.match?(/\AEND:VCARD\z/i)
      raise ParseError, "Expected exactly one vCard" if lines.count { |l| l.match?(/\ABEGIN:VCARD\z/i) } != 1

      new(lines[1..-2].map { |line| Property.parse(line) })
    end

    def initialize(properties = [])
      @properties = properties
    end

    def [](name)
      properties.find { |p| p.name == name.upcase }
    end

    def all(name)
      properties.select { |p| p.name == name.upcase }
    end

    def value(name)
      self[name]&.text
    end

    def version
      value("VERSION")
    end

    def uid
      value("UID")&.delete_prefix("urn:uuid:")
    end

    # Replaces every property with this name. Keeps the position of the first one, or appends.
    def set(name, value, params: [])
      replace_all(name, [ Property.new(name, value, params: params) ])
    end

    def replace_all(name, new_properties)
      index = properties.index { |p| p.name == name.upcase } || properties.size
      properties.reject! { |p| p.name == name.upcase }
      properties.insert([ index, properties.size ].min, *new_properties)
      self
    end

    def delete(name)
      properties.reject! { |p| p.name == name.upcase }
      self
    end

    # The label of a property: an Apple X-ABLabel on the same group, else its TYPE.
    def label_for(property)
      Vcard::Label.read(self, property)
    end

    def to_s
      [ "BEGIN:VCARD", *properties.map(&:to_s), "END:VCARD" ].join(CRLF) + CRLF
    end
  end
end
