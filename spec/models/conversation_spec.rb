require 'spec_helper'

describe Conversation do
  it { should be_timestamped_document.with(:updated) }
  it { should_not be_timestamped_document.with(:created) }
  it { should embed_many(:messages).of_type(Message) }
  it { should belong_to(:author).of_type(User).as_inverse_of(:outbound_conversations).with_foreign_key(:author_id) }
  it { should have_and_belong_to_many(:recipients).of_type(User).as_inverse_of(:inbound_conversations) }

  it { should validate_associated(:messages) }
end
