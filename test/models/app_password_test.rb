require "test_helper"

class AppPasswordTest < ActiveSupport::TestCase
  test "authenticate compares digests with secure_compare" do
    app_password = AppPassword.generate(users(:owner), name: "Mac")
    compared = []
    original = ActiveSupport::SecurityUtils.method(:secure_compare)
    ActiveSupport::SecurityUtils.define_singleton_method(:secure_compare) { |a, b| compared << [ a, b ]; original.call(a, b) }

    assert_equal app_password, AppPassword.authenticate("owner", app_password.secret)
    assert_equal [ [ app_password.secret_digest, AppPassword.digest(app_password.secret) ] ], compared
  ensure
    ActiveSupport::SecurityUtils.define_singleton_method(:secure_compare, original)
  end

  test "stores a digest, never the secret" do
    app_password = AppPassword.generate(users(:owner), name: "Mac")
    assert_not_includes app_password.reload.attributes.values.map(&:to_s), app_password.secret
  end

  test "authenticate accepts the secret without dashes or in upper case" do
    app_password = AppPassword.generate(users(:owner), name: "Mac")
    assert_equal app_password, AppPassword.authenticate("OWNER", app_password.secret.delete("-").upcase)
  end
end
