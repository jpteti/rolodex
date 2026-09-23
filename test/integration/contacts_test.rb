require "test_helper"

class ContactsTest < ActionDispatch::IntegrationTest
  setup { sign_in_as users(:owner) }

  test "create a contact with name, organization, and several emails and phones" do
    get new_contact_url
    assert_response :success

    assert_difference -> { Contact.count }, 1 do
      post contacts_url, params: { contact_form: {
        given_name: "Grace", family_name: "Hopper", organization: "US Navy",
        emails: [ "grace@example.com", "hopper@navy.example", "" ], phones: [ "555-0100", "555-0101" ]
      } }
    end

    contact = Contact.last
    assert_redirected_to contact_url(contact)
    assert_equal [ "grace@example.com", "hopper@navy.example" ], contact.emails
    assert_equal [ "555-0100", "555-0101" ], contact.phones

    follow_redirect!
    assert_select "h1", "Grace Hopper"
    assert_select "dd", "US Navy"
    assert_select "dd a[href='mailto:hopper@navy.example']"
    assert_select "dd a", "555-0101"
  end

  test "an empty form shows an error" do
    assert_no_difference -> { Contact.count } do
      post contacts_url, params: { contact_form: { given_name: "", emails: [ "" ] } }
    end
    assert_response :unprocessable_content
    assert_select ".errors li", "Enter a name, organization, email, or phone"
  end

  test "the list shows contacts in sort order" do
    book = users(:owner).address_book
    [ { given_name: "Amy", family_name: "Baker" }, { organization: "Acme" }, { given_name: "Bob", family_name: "Adams" } ].each do |fields|
      Contact.build_from_fields(book, fields).save!
    end

    get contacts_url
    assert_equal [ "Acme", "Bob Adams", "Amy Baker" ], css_select("#contacts .contact-name").map(&:text)
  end

  test "contacts are scoped to the signed-in user's address book" do
    other = User.create!(username: "someone")
    contact = Contact.build_from_fields(other.address_book, { given_name: "Hidden" }).tap(&:save!)

    get contact_url(contact)
    assert_response :not_found
  end
end
