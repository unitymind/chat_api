class Conversation
  include Mongoid::Document
  include Mongoid::Timestamps::Updated
  embeds_many :messages
  has_and_belongs_to_many :recipients, class_name: "User", inverse_of: :inbound_conversations
  belongs_to :author, class_name: "User", inverse_of: :outbound_conversations
end