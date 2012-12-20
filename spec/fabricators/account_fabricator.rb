Fabricator(:account, class_name: ChatApi::Account) do
  email { Faker::Internet.email }
  password { Faker::Lorem.characters(12)}
end
