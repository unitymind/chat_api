require 'spec_helper'

describe User do
  it { should have_fields(:nickname, :email).of_type(String) }
  it { should validate_presence_of (:nickname) }
  it { should validate_presence_of (:email) }
  it { should validate_uniqueness_of(:email).case_insensitive }

  it { should have_and_belong_to_many(:inbound_conversations).of_type(Conversation).as_inverse_of(:recipients) }
  it { should have_many(:outbound_conversations).of_type(Conversation).as_inverse_of(:author).with_foreign_key(:author_id) }
end
