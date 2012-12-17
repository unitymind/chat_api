Fabricator(:user) do
  nickname { Faker::Internet.user_name }
  email { Faker::Internet.email }
end
