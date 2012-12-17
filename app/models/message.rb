class Message
  include Mongoid::Document
  include Mongoid::Timestamps::Created
  field :text, type: String
  embedded_in :conversation
  belongs_to :author, class_name: "User"

  validates_presence_of :text
  validate :author_allowed

  def author_allowed
    if conversation.author != author && ! conversation.recipients.include?(author)
      errors.add(:author, 'not associated with conversation')
    end
  end
end