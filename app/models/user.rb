class User
  include Mongoid::Document
  field :nickname, type: String
  field :email, type: String

  has_many :outbound_conversations, class_name: "Conversation", inverse_of: :author
  has_and_belongs_to_many :inbound_conversations, class_name: "Conversation", inverse_of: :recipients

  validates_presence_of :nickname, :email
  validates_uniqueness_of :email, case_sensitive: false
end