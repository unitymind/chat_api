Fabricator(:user, class_name: ChatApi::User) do
  nickname { Faker::Internet.user_name }
  email { Faker::Internet.email }
end
