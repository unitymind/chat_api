module ChatApi
  module Entities
    class Message < Grape::Entity
      expose :id, as: 'id', documentation: { type: "String", desc: "Message id" }
      expose :text, documentation: { type: "String", desc: "Message text" }
      expose :created_at, as: 'datetime', documentation: { type: "DateTime", desc: "Message datetime" }
      expose :created_at_timestamp, as: 'timestamp', documentation: { type: "Float", desc: "Message timestamp" }
      expose :author, using: ChatApi::Entities::User, documentation: { type: "UserEntity", desc: "Author of message" }
    end
  end
end