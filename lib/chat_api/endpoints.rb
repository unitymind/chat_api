module ChatApi
  class Endpoints < Grape::API
    default_format :json

    helpers do
      def current_user
        @current_user ||= ChatApi::Mongoid::Account.authorize!(params)
      end

      def authenticate!
        error!({ error: 'Unauthorized.'}, 401) unless current_user
      end

      def find_conversation(conversation_id)
        current_user.inbound_conversations.find_by(id: conversation_id) || current_user.outbound_conversations.find_by(id: conversation_id)
      end
    end

    resource :accounts do

      desc "Get full profile info for authenticated user"
      get :info do
        authenticate!
        present current_user, with: ChatApi::Entities::User, with_email: true
      end

      desc "Return authentication token using user email/password",  {
          :object_fields => {}
      }
      params do
        requires :email, :type => String, :desc => 'Your email'
        requires :password, :type => String, :desc => 'Your password'
      end

      post :login do
        email = params[:email]
        password = params[:password]

        account = ChatApi::Mongoid::Account.find_by_email(email)

        error!({ error: 'Invalid email or password.'}, 401) if account.nil?

        account.ensure_authentication_token!

        error!({ error: 'Invalid email or password.'}, 401) unless account.valid_password?(password)

        { message: 'Logged in.', token: account.authentication_token }
      end

      desc "Invalidate authentication token"
      params do
        requires :auth_token, :type => String, :desc => 'Your authentication token'
      end

      delete :logout do
        account = ChatApi::Mongoid::Account.find_by_token(params[:auth_token])

        error!({ error: 'Invalid token.'}, 404) if account.nil?

        account.reset_authentication_token!

        { message: 'Logged out.' }
      end
    end

    resource :user do
      # Only authenticated users!
      before do
        authenticate!
      end

      desc "Find nearest users for authenticated user current location"
      params do
        requires :radius, :type => Integer, :desc => 'Search radius in meters'
      end
      get :find_nearest do
        users = (ChatApi::Mongoid::User.in_radius(current_user.location, params['radius']).to_a - [current_user])
        present users, with: ChatApi::Entities::User
      end

      resource :conversations do
        desc "Get full list of conversations"
        get :list do
          present current_user.conversations, with: ChatApi::Entities::Conversation
        end

        desc "Get conversation with full list of messages using conversation's id"
        params do
          requires :id, :type => String, :desc => 'Conversation id'
        end
        get ':id' do
          conversation = find_conversation(params[:id])

          error!({ error: 'Conversation not found.'}, 404) if conversation.nil?

          present conversation, with: ChatApi::Entities::Conversation, with_messages: true
        end

        desc "Publish new message to conversation using conversation's id"
        params do
          requires :id, :type => String, :desc => 'Conversation id'
          requires :text, :type => String, :desc => "Message text"
        end
        post ':id' do
          conversation = find_conversation(params[:id])
          error!({ error: 'Conversation not found.'}, 500) if conversation.nil?
          error!({ error: 'Empty messages not allowed.'}, 500) if params[:text].strip.size == 0

          message = ChatApi::Mongoid::Message.new(author: current_user, text: params[:text].strip)
          conversation.messages << message
          present message, with: ChatApi::Entities::Message, brief: true
        end

        desc "Get new messages after picked timestamp"
        params do
          requires :id, :type => String, :desc => 'Conversation id'
          requires :timestamp, :type => Float, :desc => 'Last message timestamp'
        end
        get ':id/updates' do
          conversation = find_conversation(params[:id])

          error!({ error: 'Conversation not found.'}, 404) if conversation.nil?

          present conversation.messages.after_timestamp(params['timestamp']),
                  with: ChatApi::Entities::Message, brief: true
        end

      end
    end
  end
end