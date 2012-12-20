module ChatApi
  module Entities
    class User < Grape::Entity
      expose :id, as: 'id', documentation: { type: "String", desc: "User id" }
      expose :nickname, :location, unless: { brief: true }, documentation: { type: "String", desc: "User nickname" }
      expose :location, unless: { brief: true }, documentation: { type: "Array[Float, Float]", desc: "User current location [Float(long), Float(lat)]" }
      expose :email, if: { with_email: true }, documentation: { type: "String", desc: "User email" }
    end
  end
end