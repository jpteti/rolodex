require "test_helper"
require "rake"

class SetupLinkTaskTest < ActiveSupport::TestCase
  setup do
    Rails.application.load_tasks if Rake::Task.tasks.empty?
    Rake::Task["rolodex:setup_link"].reenable
  end

  test "creates the user if missing and prints a setup URL" do
    output = with_env("ROLODEX_USER" => "newperson") do
      capture_io { Rake::Task["rolodex:setup_link"].invoke }.first
    end

    user = User.find_by!(username: "newperson")
    token = output[%r{/setup/(\S+)}, 1]
    link = SetupLink.find_usable(token)
    assert_equal user, link.user
    assert_in_delta 15.minutes.from_now, link.expires_at, 5.seconds
  end

  test "prints one link per configured origin" do
    origins = Rails.configuration.x.app_origins
    Rails.configuration.x.app_origins = [ "http://localhost:3000", "https://rolodex.test" ]

    output = capture_io { Rake::Task["rolodex:setup_link"].invoke }.first
    tokens = output.scan(%r{\A|^(https?://[^/]+)/setup/(\S+)$}).reject { |match| match.compact.empty? }

    assert_equal [ "http://localhost:3000", "https://rolodex.test" ], tokens.map(&:first)
    assert_equal 1, tokens.map(&:last).uniq.size
  ensure
    Rails.configuration.x.app_origins = origins
  end

  test "reuses an existing user" do
    assert_no_difference -> { User.count } do
      with_env("ROLODEX_USER" => "owner") { capture_io { Rake::Task["rolodex:setup_link"].invoke } }
    end
  end

  private
    def with_env(vars)
      previous = vars.to_h { |key, _| [ key, ENV[key] ] }
      vars.each { |key, value| ENV[key] = value }
      yield
    ensure
      previous.each { |key, value| ENV[key] = value }
    end
end
