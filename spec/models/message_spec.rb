require "spec_helper"

describe Message do
  it { should be_timestamped_document.with(:created) }
  it { should_not be_timestamped_document.with(:updated) }
  it { should have_field(:text).of_type(String) }
  it { should be_embedded_in(:conversation).of_type(Conversation) }
  it { should belong_to(:author).of_type(User).with_foreign_key(:author_id) }

  it { should validate_presence_of (:text) }

  context 'custom validations' do
    include_context "shared models context"

    it 'should not allow author that not associated with conversation as author or recipients' do
      # Valid cases
      @conversation.messages << Message.new(author: @user_1, text: Faker::Lorem.words)
      @conversation.should be_valid

      @conversation.messages << Message.new(author: @user_2, text: Faker::Lorem.words)
      @conversation.should be_valid

      @conversation.messages << Message.new(author: @user_3, text: Faker::Lorem.words)
      @conversation.should be_valid

      # Invalid case
      invalid_message = Message.new(author: @user_4, text: Faker::Lorem.words)
      @conversation.messages << invalid_message
      @conversation.should_not be_valid
      invalid_message.should_not be_valid
      invalid_message.errors[:author].should be_include 'not associated with conversation'
    end
  end
end
