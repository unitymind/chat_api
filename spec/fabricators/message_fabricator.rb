Fabricator(:message, class_name: ChatApi::Mongoid::Message) do
  text { Faker::Lorem.sentence }
end
