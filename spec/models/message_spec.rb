require 'spec_helper'

describe Message do
  it { should be_timestamped_document.with(:created) }
  it { should_not be_timestamped_document.with(:updated) }
  it { should have_field(:text).of_type(String) }
  it { should be_embedded_in(:conversation).of_type(Conversation) }
  it { should belong_to(:author).of_type(User).with_foreign_key(:author_id) }
end
