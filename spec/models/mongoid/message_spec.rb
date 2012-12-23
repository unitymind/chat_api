require "spec_helper"

describe ChatApi::Mongoid::Message do
  it { should be_timestamped_document.with(:created) }
  it { should_not be_timestamped_document.with(:updated) }

  it { should have_field(:text).of_type(String) }

  it { should be_embedded_in(:conversation).of_type(ChatApi::Mongoid::Conversation) }
  it { should belong_to(:author).of_type(ChatApi::Mongoid::User).with_foreign_key(:author_id) }

  it { should validate_presence_of (:text) }

  describe 'additional logic' do
    include_context "shared models context"

    #it '#created_timestamp' do
    #  message = Fabricate.build(:message, author: @user_1)
    #  @conversation.messages << message
    #  Time.at(message.created_timestamp).utc.to_f.should eq message.created_at.to_f
    #end

    context 'custom validations' do
      it 'should not allow author that not associated with conversation as author or recipients' do
        # Valid cases
        @conversation.messages << Fabricate.build(:message, author: @user_1)
        @conversation.should be_valid

        @conversation.messages << Fabricate.build(:message, author: @user_2)
        @conversation.should be_valid

        @conversation.messages << Fabricate.build(:message, author: @user_3)
        @conversation.should be_valid

        # Invalid case
        invalid_message = Fabricate.build(:message, author: @user_4)
        @conversation.messages << invalid_message
        @conversation.should_not be_valid
        invalid_message.should_not be_valid
        invalid_message.errors[:author].should be_include 'not associated with conversation'
      end
    end

    context 'callbacks' do
      it 'should set created_timestamp after created based on created_at value' do
        message = Fabricate.build(:message, author: @user_1)
        @conversation.messages << message
        message.created_at_timestamp.should_not be_nil
        Time.at(message.created_at_timestamp).utc.to_f.should eq message.created_at.to_f
      end
    end

    context 'scopes' do
      before(:each) do
        @message_1 = Fabricate.build(:message, author: @user_1)
        @conversation.messages << @message_1

        @message_2 = Fabricate.build(:message, author: @user_2)
        @conversation.messages << @message_2

        @message_3 = Fabricate.build(:message, author: @user_1)
        @conversation.messages << @message_3
        @conversation.save
      end

      it 'should order_by created_at ASC by default' do
        @conversation.messages.should eq [@message_1, @message_2, @message_3]
      end

      it 'should be scope by_author using parameter' do
        @conversation.messages.by_author(@user_1).to_a.should eq [@message_1, @message_3]
        @conversation.messages.by_author(@user_2).to_a.should eq [@message_2]
      end

      it 'should return messages only after parametrized timestamp' do
        after_timestamp = @message_3.created_at_timestamp

        sleep(0.02)

        message_4 = Fabricate.build(:message, author: @user_2)
        @conversation.messages << message_4

        message_5 = Fabricate.build(:message, author: @user_1)
        @conversation.messages << message_5

        @conversation.messages.after_timestamp(after_timestamp).to_a.should eq [message_4, message_5]
      end
    end
  end


end
