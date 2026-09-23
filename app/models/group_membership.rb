# A contact's place in a group, keyed by the contact's vCard UID as group vCards are.
class GroupMembership < ApplicationRecord
  belongs_to :group
end
