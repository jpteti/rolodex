require "test_helper"
require "puma/configuration"

class PumaConfigTest < ActiveSupport::TestCase
  test "Puma accepts the WebDAV methods CardDAV clients send" do
    config = Puma::Configuration.new({}, {}, ENV.to_h) { |c| c.load Rails.root.join("config/puma.rb").to_s }
    config.clamp
    methods = config.options[:supported_http_methods]

    %w[ GET PUT DELETE OPTIONS PROPFIND PROPPATCH REPORT ].each { |verb| assert_includes methods, verb }
  end
end
