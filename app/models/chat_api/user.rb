module ChatApi
  class User
    include Mongoid::Document
    field :nickname, type: String
    field :email, type: String
    field :location, type: Array

    has_many :outbound_conversations, class_name: "ChatApi::Conversation", inverse_of: :author
    has_and_belongs_to_many :inbound_conversations, class_name: "ChatApi::Conversation", inverse_of: :recipients, index: true
    belongs_to :account, index: true

    validates_presence_of :nickname, :email
    validates_uniqueness_of :email, case_sensitive: false

    index({ location: "2d" }, { background: true, bits: 32 })

    scope :in_radius, lambda  {|location, radius|
      distance = radius / 1000.0 / 6378.137
      where(location: {"$within" => {"$centerSphere" => [location, distance] }})
    }

    def conversations
      (inbound_conversations + outbound_conversations).to_a.sort { |a, b| b.updated_at <=> a.updated_at }
    end

    # TODO. Calculate distance
=begin
    def location_as_geo_point
      location.nil? ? nil: GeoPoint.new(location[1], location[0])
    end


    def distance_for(location)
      destination_geo_point = GeoPoint.new(location[1], location[0])
    end
=end
  end
end