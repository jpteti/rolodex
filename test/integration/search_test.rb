require "test_helper"

class SearchTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as users(:owner)
    @ada = create_contact(given_name: "Ada", family_name: "Lovelace", organization: "Analytical Engines",
      emails: [ "ada@example.com" ], phones: [ "+1 (555) 010-2030" ])
    @grace = create_contact(given_name: "Grace", family_name: "Hopper", organization: "US Navy", phones: [ "555.999.1234" ])
    @alan = create_contact(given_name: "Alan", family_name: "Turing", emails: [ "alan@bletchley.example" ])
  end

  def results(**params)
    get contacts_url, params: params
    css_select("#contacts .contact-name").map(&:text)
  end

  test "matches name, organization, and email, ignoring case" do
    assert_equal [ "Ada Lovelace" ], results(q: "LOVE")
    assert_equal [ "Grace Hopper" ], results(q: "navy")
    assert_equal [ "Alan Turing" ], results(q: "Bletchley")
    assert_equal [ "Grace Hopper", "Ada Lovelace", "Alan Turing" ], results(q: "")
  end

  test "matches phone numbers ignoring spaces, dashes, dots, and parentheses" do
    assert_equal [ "Ada Lovelace" ], results(q: "5550102030")
    assert_equal [ "Ada Lovelace" ], results(q: "010-2030")
    assert_equal [ "Grace Hopper" ], results(q: "(555) 999")
  end

  test "LIKE wildcards in the query are literal" do
    assert_empty results(q: "%")
    assert_empty results(q: "_")
  end

  test "search covers active contacts unless archived ones are included" do
    @ada.archive!

    assert_empty results(q: "lovelace")
    assert_equal [ "Ada Lovelace" ], results(q: "lovelace", archived: "1")
    assert_select ".badge", "Archived"
  end

  test "trashed contacts never appear" do
    @ada.trash!

    assert_empty results(q: "lovelace")
    assert_empty results(q: "lovelace", archived: "1")
    assert_equal [ "Grace Hopper", "Alan Turing" ], results(q: "")
  end

  test "the search form updates a Turbo frame as the user types" do
    get contacts_url
    assert_select "form[data-controller=search][data-turbo-frame=contact_results] input[type=search][data-action='input->search#search']"
    assert_select "turbo-frame#contact_results[target=_top]"
  end

  test "device edits update the search columns" do
    @alan.update!(vcard: @alan.vcard.sub("alan@bletchley.example", "turing@manchester.example"))
    assert_equal [ "Alan Turing" ], results(q: "manchester")
    assert_empty results(q: "bletchley")
  end
end
