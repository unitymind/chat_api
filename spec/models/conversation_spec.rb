require 'spec_helper'

describe ChatApi::Conversation do
  it { should be_timestamped_document.with(:updated) }
  it { should_not be_timestamped_document.with(:created) }

  it { should embed_many(:messages).of_type(ChatApi::Message) }
  it { should belong_to(:author).of_type(ChatApi::User).as_inverse_of(:outbound_conversations).with_foreign_key(:author_id).with_index }
  it { should have_and_belong_to_many(:recipients).of_type(ChatApi::User).as_inverse_of(:inbound_conversations).with_index }

  it { should validate_associated(:messages) }
end
