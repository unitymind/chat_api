shared_context "shared models context" do
  before(:all) do
    @user_1 = Fabricate(:user)
    @user_2 = Fabricate(:user)
    @user_3 = Fabricate(:user)
    @user_4 = Fabricate(:user)
  end

  before(:each) do
    @conversation = Conversation.create(author: @user_1, recipients: [@user_2, @user_3])
  end
end