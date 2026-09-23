require "test_helper"

class PermanentDeleteTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as users(:owner)
    @ada = create_contact(given_name: "Ada", family_name: "Lovelace")
    @grace = create_contact(given_name: "Grace", family_name: "Hopper")
    @alan = create_contact(given_name: "Alan", family_name: "Turing")
  end

  test "delete buttons ask for confirmation" do
    @ada.trash!

    get trashed_contacts_url
    assert_select "form[action='#{empty_trashed_contacts_path}'][data-turbo-confirm*='cannot be undone']"
    assert_select "form[action='#{trashed_contact_path(@ada)}'][data-turbo-confirm*='Permanently delete Ada Lovelace']"

    get contact_url(@ada)
    assert_select "form[action='#{trashed_contact_path(@ada)}'][data-turbo-confirm]"
  end

  test "a trashed contact is permanently deleted and cannot be restored" do
    @ada.trash!

    assert_difference -> { Contact.count }, -1 do
      delete trashed_contact_url(@ada)
    end
    assert_redirected_to trashed_contacts_url
    assert_not Contact.exists?(@ada.id)

    post restore_trashed_contact_url(@ada)
    assert_response :not_found
  end

  test "Empty Trash permanently deletes every trashed contact and nothing else" do
    @ada.trash!
    @grace.trash!

    assert_difference -> { Contact.count }, -2 do
      delete empty_trashed_contacts_url
    end
    follow_redirect!
    assert_select ".flash", "Permanently deleted 2 contacts."
    assert_equal [ @alan ], Contact.all.to_a
  end

  test "contacts outside the trash cannot be permanently deleted" do
    @grace.archive!

    assert_no_difference -> { Contact.count } do
      delete trashed_contact_url(@alan)
      assert_response :not_found
      delete trashed_contact_url(@grace)
      assert_response :not_found
    end
  end

  test "another user's trashed contact cannot be deleted" do
    other = User.create!(username: "other")
    theirs = Contact.build_from_fields(other.address_book, { given_name: "Theirs" }).tap(&:save!)
    theirs.trash!

    assert_no_difference -> { Contact.count } do
      delete trashed_contact_url(theirs)
      delete empty_trashed_contacts_url
    end
  end
end
