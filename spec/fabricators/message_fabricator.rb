Fabricator(:message, class_name: ChatApi::Message) do
  text { Faker::Lorem.sentence }
end
