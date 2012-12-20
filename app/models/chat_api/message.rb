module ChatApi
  class Message
    include Mongoid::Document
    include Mongoid::Timestamps::Created
    field :text, type: String
    field :created_at_timestamp, type: Float
    embedded_in :conversation
    belongs_to :author, class_name: "ChatApi::User"

    validates_presence_of :text
    validate :author_allowed

    default_scope order_by(:created_at.asc)

    scope :by_author, lambda  { |author| where(author: author) }
    scope :after_timestamp, lambda  { |timestamp| where(:created_at_timestamp.gt => timestamp) }

    before_create :create_timestamp

    protected
      def author_allowed
        if conversation.author != author && ! conversation.recipients.include?(author)
          errors.add(:author, 'not associated with conversation')
        end
      end

    def create_timestamp
      self.created_at_timestamp = self.created_at.to_f
    end
  end
end