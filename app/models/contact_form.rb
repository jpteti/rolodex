# The web form for a new contact. Builds the contact's vCard from the submitted fields.
class ContactForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :given_name, :string
  attribute :family_name, :string
  attribute :organization, :string
  attribute :emails, default: -> { [] }
  attribute :phones, default: -> { [] }

  validate :something_to_show

  attr_reader :contact

  def save(address_book)
    return false unless valid?

    @contact = Contact.build_from_fields(address_book, fields)
    @contact.save
  end

  def emails=(values)
    super(Array(values).map(&:to_s))
  end

  def phones=(values)
    super(Array(values).map(&:to_s))
  end

  private
    def fields
      { given_name:, family_name:, organization:, emails:, phones: }
    end

    def something_to_show
      if [ given_name, family_name, organization, *emails, *phones ].all?(&:blank?)
        errors.add(:base, "Enter a name, organization, email, or phone")
      end
    end
end
