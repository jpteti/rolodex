# Reads and writes the label of a repeated vCard property (EMAIL, TEL, ADR, URL) the way Apple Contacts does:
# standard labels as TYPE parameters, anything else as an X-ABLabel in the property's item group.
module Vcard::Label
  # Display label => TYPE values, per property.
  STANDARD = {
    "EMAIL" => { "home" => %w[HOME], "work" => %w[WORK] },
    "TEL" => {
      "mobile" => %w[CELL], "iPhone" => %w[IPHONE], "home" => %w[HOME], "work" => %w[WORK], "main" => %w[MAIN],
      "home fax" => %w[HOME FAX], "work fax" => %w[WORK FAX], "pager" => %w[PAGER]
    },
    "ADR" => { "home" => %w[HOME], "work" => %w[WORK] },
    "URL" => { "home" => %w[HOME], "work" => %w[WORK] }
  }.freeze

  # Apple's built-in labels, stored as X-ABLabel:_$!<Name>!$_
  APPLE_BUILT_IN = { "other" => "Other", "homepage" => "HomePage", "school" => "School" }.freeze

  # TYPE values that describe the value, not the label. Kept when the label changes.
  KEPT_TYPES = %w[INTERNET PREF VOICE].freeze

  module_function

  def suggestions(name)
    STANDARD.fetch(name, {}).keys + APPLE_BUILT_IN.keys
  end

  def read(card, property)
    if property.group && (custom = grouped_label(card, property))
      text = custom.text
      built_in = text[/\A_\$!<(.*)>!\$_\z/, 1]
      return built_in ? built_in.downcase : text
    end

    types = property.param_values("TYPE").map(&:upcase) - KEPT_TYPES
    STANDARD.fetch(property.name, {}).find { |_, values| values.sort == types.sort }&.first ||
      STANDARD.fetch(property.name, {}).find { |_, values| (values - types).empty? }&.first ||
      types.first&.downcase
  end

  # Changes the label of a property already in the card.
  def write(card, property, label)
    label = label.to_s.strip
    standard = STANDARD.fetch(property.name, {}).find { |key, _| key.casecmp?(label) }&.last

    kept = property.params.reject { |key, value| key == "TYPE" && !KEPT_TYPES.include?(value.upcase) }
    property.params = kept + Array(standard).map { |type| [ "TYPE", type ] }
    card.properties.delete(grouped_label(card, property)) if property.group

    return if standard || label.empty?

    property.group ||= next_group(card)
    built_in = APPLE_BUILT_IN.find { |key, _| key.casecmp?(label) }&.last
    value = built_in ? "_$!<#{built_in}>!$_" : Vcard.escape(label)
    index = card.properties.index(property) || card.properties.size - 1
    card.properties.insert(index + 1, Vcard::Property.new("X-ABLABEL", value, group: property.group))
  end

  def grouped_label(card, property)
    card.properties.find { |other| other.name == "X-ABLABEL" && other.group&.casecmp?(property.group) }
  end

  def next_group(card)
    used = card.properties.filter_map { |property| property.group.to_s[/\Aitem(\d+)\z/i, 1]&.to_i }
    "item#{(used.max || 0) + 1}"
  end
end
