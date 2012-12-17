class Message
  include Mongoid::Document
  include Mongoid::Timestamps::Created
  field :text, type: String
  embedded_in :conversation
  belongs_to :author, class_name: "User"
end