shared_context "shared models context" do
  before(:all) do
    @user_1 = Fabricate(:user, location: [37.615954, 55.755366])
    @user_2 = Fabricate(:user, location: [37.618443, 55.758173])
    @user_3 = Fabricate(:user, location: [37.61029, 55.75706])
    @user_4 = Fabricate(:user, location: [37.602538, 55.650797])
  end

  before(:each) do
    @conversation = Conversation.create(author: @user_1, recipients: [@user_2, @user_3])
  end
end