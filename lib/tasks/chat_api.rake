namespace :chat_api do
  def format_response_doc(is_array, success_fields, exclude = [])
    formatted = is_array ? "Response on Success as Array of: " : "Response on Success Object: "
    exclude.each { |field_key| success_fields.delete(field_key) }
    formatted += "#{success_fields}\n"
    formatted += "Response on Fail as Object: #{{ error: { type: "String", desc: "Error message" } }}\n"
  end

  desc "Describe API"
  task :describe => :environment do
    return_docs = {
        '/accounts/info(.:format)|GET' => [false, ChatApi::Entities::User, []],
        '/accounts/login(.:format)|POST' =>
            { is_array: false,
              success: { message: { type: "String", desc: "Info message" }, token: { type: "String", desc: "Valid auth token" } }
            },
        '/accounts/logout(.:format)|DELETE' =>
            { is_array: false,
              success: { message: { type: "String", desc: "Info message" } }
            },
        '/user/find_nearest(.:format)|GET' => [true, ChatApi::Entities::User, [:email]],
        '/user/conversations/list(.:format)|GET' => [true, ChatApi::Entities::Conversation, [:messages]],
        '/user/conversations/:id(.:format)|GET' => [true, ChatApi::Entities::Conversation, []],
        '/user/conversations/:id(.:format)|POST' => [false, ChatApi::Entities::Message, []],
        '/user/conversations/:id/updates(.:format)|GET' => [true, ChatApi::Entities::Message, []]
    }
    puts "ChatApi ROUTES TABLE\n\n"
    ChatApi::Endpoints.routes.each do |r|
      puts "#{r.route_method} #{r.route_path} (#{r.route_description})"
      formatted_params = ''
      if r.route_params.empty?
        formatted_params = ['Params not required']
      else
        formatted_params = []
        r.route_params.each_value { |p| formatted_params.push("#{p[:required]? 'Required' : 'Optional'} [#{p[:type]}] #{p[:full_name]} (#{p[:desc]})") }
        #r.route_params.each_value { |p| puts p  formatted_params << "[#{p[:type]}] #{p[:full_name]}"}
      end
      puts "#{formatted_params.join("\n")}"
      response_doc = ''
      unless return_docs["#{r.route_path}|#{r.route_method}"].nil?
        docs = return_docs["#{r.route_path}|#{r.route_method}"]

        response_doc = format_response_doc(docs[0], docs[1].send(:documentation), docs[2]) if docs.kind_of?(Array)
        response_doc = format_response_doc(docs[:is_array], docs[:success]) if docs.kind_of?(Hash)
      end

      puts response_doc
      puts
    end
  end


end