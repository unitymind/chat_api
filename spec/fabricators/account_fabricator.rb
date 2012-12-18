Fabricator(:account) do
  email { Faker::Internet.email }
  password { Faker::Lorem.characters(12)}
end
