require "spec_helper"

describe ChatApi::Endpoints do
  include Rack::Test::Methods

  def app
    ChatApi::Endpoints
  end

  before(:each) do
    @account = Fabricate(:account, password: '1dJbGd6wnd')
    @account.user.update_attribute(:location, [37.613138, 55.756969])
  end

  def perform_request(method, uri, params = {})
    params[:auth_token] = @auth_token unless @auth_token.nil?
    send(method, uri, params)
    @last_response_status = last_response.status
    @last_response_parsed = JSON.parse(last_response.body)
  end

  def login_default!
    post '/accounts/login', email: @account.email, password: '1dJbGd6wnd'
    @auth_token = JSON.parse(last_response.body)['token']
  end

  def login_as!(account)
    post '/accounts/login', email: account.email, password: '1dJbGd6wnd'
    @auth_token = JSON.parse(last_response.body)['token']
  end

  describe 'accounts' do
    it 'POST /accounts/login should return access token' do
      # Try with invalid email and password
      perform_request(:post, '/accounts/login', email: 'wrong@mail.com', password: 'bullshit')

      @last_response_status.should eq 401
      @last_response_parsed.should have_key('error')
      @last_response_parsed['error'].should eq 'Invalid email or password.'

      # Try with invalid password
      perform_request(:post, '/accounts/login', email: @account.email, password: 'bullshit')

      @last_response_status.should eq 401
      @last_response_parsed.should have_key('error')
      @last_response_parsed['error'].should eq 'Invalid email or password.'

      # Use valid credentials
      perform_request(:post, '/accounts/login', email: @account.email, password: '1dJbGd6wnd')

      @last_response_status.should eq 201
      @last_response_parsed.should have_key('message')
      @last_response_parsed['message'].should eq 'Logged in.'

      # Should have token in response
      @last_response_parsed.should have_key('token')
    end

    it 'DELETE /accounts/logout should reset access token' do
      # Do login
      perform_request(:post, '/accounts/login', email: @account.email, password: '1dJbGd6wnd')
      @last_response_status.should eq 201

      # Save token
      auth_token = @last_response_parsed['token']

      # Try to invalidate missing token
      perform_request(:delete, '/accounts/logout', auth_token: 'bullshit_token')

      @last_response_status.should eq  404
      @last_response_parsed.should have_key('error')
      @last_response_parsed['error'].should eq 'Invalid token.'

      # Invalidate saved token
      perform_request(:delete, '/accounts/logout', auth_token: auth_token)

      @last_response_status.should eq 200
      @last_response_parsed.should have_key('message')
      @last_response_parsed['message'].should eq 'Logged out.'

      # Try to invalidate saved token twice
      perform_request(:delete, '/accounts/logout', auth_token: auth_token)

      @last_response_status.should eq  404
      @last_response_parsed.should have_key('error')
      @last_response_parsed['error'].should eq 'Invalid token.'
    end

    it 'GET /accounts/info should returns only for authenticated user' do
      perform_request(:post, '/accounts/login', email: @account.email, password: '1dJbGd6wnd')

      first_auth_token = @last_response_parsed['token']

      perform_request(:get, '/accounts/info', auth_token: first_auth_token)
      @last_response_status.should eq 200
      @last_response_parsed['id'].should eq @account.user.id.to_s
      @last_response_parsed['email'].should eq @account.user.email
      @last_response_parsed['nickname'].should eq @account.user.nickname

      perform_request(:delete, '/accounts/logout', auth_token: first_auth_token)

      perform_request(:get, '/accounts/info', auth_token: first_auth_token)
      @last_response_status.should eq 401
      @last_response_parsed.should have_key('error')
      @last_response_parsed['error'].should eq 'Unauthorized.'

      # And try again
      perform_request(:post, '/accounts/login', email: @account.email, password: '1dJbGd6wnd')

      second_auth_token = @last_response_parsed['token']

      # Using new token after logout -> login actions
      first_auth_token.should_not eq second_auth_token

      perform_request(:get, '/accounts/info', auth_token: second_auth_token)
      @last_response_status.should eq 200
    end
  end

  describe 'user' do
    before(:each) do
        # Fabricate additional accounts
        @account_1 = Fabricate(:account, password: '1dJbGd6wnd')
        @account_1.user.update_attribute(:location, [37.615954, 55.755366])

        @account_2 = Fabricate(:account, password: '1dJbGd6wnd')
        @account_2.user.update_attribute(:location, [37.618443, 55.758173])

        @account_3 = Fabricate(:account, password: '1dJbGd6wnd')
        @account_3.user.update_attribute(:location, [37.61029, 55.75706])

        @account_4 = Fabricate(:account, password: '1dJbGd6wnd')
        @account_4.user.update_attribute(:location, [37.602538, 55.650797])

        # And login using @account
        login_default!
    end

    it 'GET /user/find_nearest should return nearest users in desired radius (but exclude current user)' do
      # Find nearest Ohotnyi ryad
      perform_request(:get, '/user/find_nearest', radius: 1000)
      @last_response_status.should eq 200
      @last_response_parsed.should have(3).items

      @last_response_parsed.each {|user| user['id'].should_not eq @account.user.id.to_s }

      # Expand radius to 30 km. and find all
      perform_request(:get, '/user/find_nearest', radius: 30000)
      @last_response_status.should eq 200
      @last_response_parsed.should have(4).items

      @last_response_parsed.each {|user| user['id'].should_not eq @account.user.id.to_s }

      # Reduce radius to 100 meters - should return no users
      perform_request(:get, '/user/find_nearest', radius: 100)
      @last_response_status.should eq 200
      @last_response_parsed.should have(0).items
    end

    context 'conversations' do
      before(:each) do
        # Strange bug with using Fabricate(:conversation) then assign recipients as Array [User]
        @conversation_1 = ChatApi::Mongoid::Conversation.new()
        @conversation_1.author = @account.user
        @conversation_1.recipient_ids = [@account_1.user.id, @account_2.user.id]
        @conversation_1.save

        @conversation_2 = ChatApi::Mongoid::Conversation.new()
        @conversation_2.author = @account_1.user
        @conversation_2.recipient_ids = [@account.user.id, @account_2.user.id, @account_3.user.id]
        @conversation_2.save

        @conversation_3 = ChatApi::Mongoid::Conversation.new()
        @conversation_3.author = @account_2.user
        @conversation_3.recipient_ids = [@account.user.id]
        @conversation_3.save

        @conversation_4 = ChatApi::Mongoid::Conversation.new()
        @conversation_4.author = @account_1.user
        @conversation_4.recipient_ids = [@account_2.user.id, @account_3.user.id, @account_4.user.id]
        @conversation_4.save
      end

      it 'GET /user/conversations/list' do
        # Add message only to one conversation
        @conversation_3.messages << Fabricate.build(:message, author: @account_2.user)

        perform_request(:get, '/user/conversations/list')
        @last_response_status.should eq 200

        @last_response_parsed.each do |conversation|
          # Check common fields exists
          conversation.should have_key('id')
          conversation.should have_key('author')
          conversation.should have_key('datetime')
          conversation.should have_key('recipients')
          conversation.should have_key('messages_count')

          conversation['recipients'].should have_at_least(1).items

          # But only @conversation_3 should have last_message from @account_2.user and messages_count is 1, otherwise 0
          if conversation['id'] == @conversation_3.id.to_s
            conversation['last_message']['author']['id'].should eq @account_2.user.id.to_s
            conversation['last_message'].should have_key('timestamp')
            conversation['messages_count'].should eq 1
          else
            conversation.should_not have_key('last_message')
            conversation['messages_count'].should eq 0
          end
        end

        # Add new message to the same conversation
        text = Faker::Lorem.sentence
        @conversation_3.messages << Fabricate.build(:message, author: @account.user, text: text)

        perform_request(:get, '/user/conversations/list')
        @last_response_status.should eq 200

        # Check that last_messages is changed and messages_count is 2
        @last_response_parsed.each do |conversation|
          if conversation['id'] == @conversation_3.id.to_s
            conversation['last_message']['author']['id'].should eq @account.user.id.to_s
            conversation['last_message']['text'].should eq text
            conversation['messages_count'].should eq 2
          end
        end
      end

      it 'GET /user/conversations/:id' do
        # Add messages
        @conversation_3.messages << Fabricate.build(:message, author: @account_2.user)
        @conversation_3.messages << Fabricate.build(:message, author: @account.user)
        last_message = Faker::Lorem.sentence
        @conversation_3.messages << Fabricate.build(:message, author: @account_2.user, text: last_message)

        # Try to request with not exists conversation id
        perform_request(:get, "/user/conversations/illegal_id")
        @last_response_status.should eq 404
        @last_response_parsed['error'].should eq 'Conversation not found.'

        # Try to request with exists, but not associated with user, conversation id
        perform_request(:get, "/user/conversations/#{@conversation_4.id.to_s}")
        @last_response_status.should eq 404
        @last_response_parsed['error'].should eq 'Conversation not found.'

        # Get exists and associated conversation
        perform_request(:get, "/user/conversations/#{@conversation_3.id.to_s}")
        @last_response_status.should eq 200
        # Check response
        @last_response_parsed.should have_key('id')
        @last_response_parsed.should have_key('datetime')
        @last_response_parsed.should have_key('author')
        @last_response_parsed.should have_key('recipients')
        @last_response_parsed.should have_key('messages_count')
        @last_response_parsed.should have_key('last_message')
        @last_response_parsed.should have_key('messages')
        # Check messages order
        @last_response_parsed['messages'].last['text'].should eq last_message
        @last_response_parsed['messages'].last['author']['id'].should eq @account_2.user.id.to_s
      end

      it 'POST /user/conversations/:id' do
        # Try to post using not exists conversation id
        perform_request(:post, "/user/conversations/illegal_id", text: 'Some text')
        @last_response_status.should eq 500
        @last_response_parsed['error'].should eq 'Conversation not found.'

        # Try to post using exists, but not associated with user, conversation id
        perform_request(:post, "/user/conversations/#{@conversation_4.id.to_s}", text: 'Some text')
        @last_response_status.should eq 500
        @last_response_parsed['error'].should eq 'Conversation not found.'

        # Try to post only spaces
        perform_request(:post, "/user/conversations/#{@conversation_3.id.to_s}", text: '    ')
        @last_response_status.should eq 500
        @last_response_parsed['error'].should eq 'Empty messages not allowed.'

        # No messages yet
        @conversation_3.messages_count.should eq 0
        new_message = Faker::Lorem.sentence
        # Post new message
        perform_request(:post, "/user/conversations/#{@conversation_3.id.to_s}", text: new_message)

        # Check response
        @last_response_status.should eq 201
        @last_response_parsed.should have_key('id')
        @last_response_parsed.should have_key('datetime')
        @last_response_parsed.should have_key('timestamp')
        @last_response_parsed.should have_key('author')
        @last_response_parsed.should have_key('text')

        # Check message
        @last_response_parsed['author']['id'].should eq @account.user.id.to_s
        @last_response_parsed['author'].should_not have_key('nickname')
        @last_response_parsed['text'].should eq new_message

        # Direct check in DB
        @conversation_3.reload
        @conversation_3.messages_count.should eq 1
      end

      it 'GET /user/conversations/:id/updates' do
        first_message = Faker::Lorem.sentence

        # Post first message
        perform_request(:post, "/user/conversations/#{@conversation_3.id.to_s}", text: first_message)
        @last_response_status.should eq 201

        timestamp = @last_response_parsed['timestamp']

        # Change user
        login_as!(@account_2)

        last_message = Faker::Lorem.sentence

        # Post first message
        perform_request(:post, "/user/conversations/#{@conversation_3.id.to_s}", text: last_message)
        @last_response_status.should eq 201

        last_message_hash = @last_response_parsed

        login_default!

        # Get updates
        perform_request(:get, "/user/conversations/#{@conversation_3.id.to_s}/updates", timestamp: timestamp)
        @last_response_status.should eq 200

        last_message_hash['id'].should eq @last_response_parsed[0]['id']
        last_message_hash['datetime'].should eq @last_response_parsed[0]['datetime']
        last_message_hash['text']['id'].should eq @last_response_parsed[0]['text']['id']
        last_message_hash['author']['id'].should eq @last_response_parsed[0]['author']['id']
      end
    end

  end
end