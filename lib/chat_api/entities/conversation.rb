module ChatApi
  module Entities
    class Conversation < Grape::Entity
      expose :id, as: 'id', documentation: { type: "String", desc: "Conversation id" }
      expose :updated_at, as: 'datetime', documentation: { type: "DateTime", desc: "Updated at" }
      expose :author, using: ChatApi::Entities::User, documentation: { type: "UserEntity", desc: "Author of conversation" }
      expose :recipients, using: ChatApi::Entities::User, documentation: { type: "Array[UserEntity]", desc: "List of recipients" }
      expose :messages_count, documentation: { type: "Integer", desc: "Total messages count" }
      expose :last_message, using: ChatApi::Entities::Message, unless: lambda{ |entity, options| entity.last_message.nil? },
             documentation: { type: "MessageEntity", desc: "Last message in conversation" }
      expose :messages, using: ChatApi::Entities::Message, if: lambda { |entity, options| options[:with_messages] && entity.messages_count > 0 },
             documentation: { type: "Array[MessageEntity]", desc: "List of all messages in conversation" }
    end
  end
end