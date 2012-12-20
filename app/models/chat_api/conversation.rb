module ChatApi
  class Conversation
    include Mongoid::Document
    include Mongoid::Timestamps::Updated
    embeds_many :messages
    has_and_belongs_to_many :recipients, class_name: "ChatApi::User", inverse_of: :inbound_conversations, index: true
    belongs_to :author, class_name: "ChatApi::User", inverse_of: :outbound_conversations, index: true

    index({"messages.created_at" => -1}, {background: true})

    def messages_count
      messages.count
    end

    def last_message
      messages.order_by(:created_at.desc).limit(1).first
    end
  end
end