require 'spec_helper'

describe ChatApi::Account do
  it { should have_one(:user) }

  it 'should be create associated user' do
    account = Fabricate(:account)
    user = ChatApi::User.where(email: account.email).first
    account.user.should eq user
    user.account.should eq account
  end
end
