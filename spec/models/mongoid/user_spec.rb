require 'spec_helper'

describe ChatApi::Mongoid::User do
  it { should have_fields(:nickname, :email).of_type(String) }
  it { should have_field(:location).of_type(Array) }

  it { should have_and_belong_to_many(:inbound_conversations).of_type(ChatApi::Mongoid::Conversation).as_inverse_of(:recipients).with_index }
  it { should have_many(:outbound_conversations).of_type(ChatApi::Mongoid::Conversation).as_inverse_of(:author).with_foreign_key(:author_id) }
  it { should belong_to(:account).of_type(ChatApi::Mongoid::Account).with_foreign_key(:account_id).with_index }

  it { should validate_presence_of (:nickname) }
  it { should validate_presence_of (:email) }
  it { should validate_uniqueness_of(:email).case_insensitive }

  it { should have_index_for(location: '2d').with_options(background: true, bits: 32) }

  context 'geolocation' do
    include_context "shared models context"

    it "should include only users in desired radius (in meters) from location's center point" do
      location = [37.615482, 55.756213] # Ohotnyi ryad

      nearest_users = ChatApi::Mongoid::User.in_radius(location, 1500).to_a
      nearest_users.should be_include @user_1
      nearest_users.should be_include @user_2
      nearest_users.should be_include @user_3
      nearest_users.should_not be_include @user_4

      nearest_users = ChatApi::Mongoid::User.in_radius(location, 30000).to_a
      nearest_users.should be_include @user_1
      nearest_users.should be_include @user_2
      nearest_users.should be_include @user_3
      nearest_users.should be_include @user_4

      location = [37.608203, 55.640604] # Chertanovo
      nearest_users = ChatApi::Mongoid::User.in_radius(location, 1500).to_a
      nearest_users.should_not be_include @user_1
      nearest_users.should_not be_include @user_2
      nearest_users.should_not be_include @user_3
      nearest_users.should be_include @user_4
    end
  end
end
