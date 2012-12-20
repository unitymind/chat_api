module ChatApi
  class Account
    include Mongoid::Document
    # Include default devise modules. Others available are:
    # :token_authenticatable, :confirmable,
    # :lockable, :timeoutable and :omniauthable

    after_create :create_user

    devise :database_authenticatable, :registerable,
           :recoverable, :rememberable, :trackable, :validatable,
           :token_authenticatable, :timeoutable

    ## Database authenticatable
    field :email,              :type => String, :default => ""
    field :encrypted_password, :type => String, :default => ""

    validates_presence_of :email
    validates_presence_of :encrypted_password

    ## Recoverable
    field :reset_password_token,   :type => String
    field :reset_password_sent_at, :type => Time

    ## Rememberable
    field :remember_created_at, :type => Time

    ## Trackable
    field :sign_in_count,      :type => Integer, :default => 0
    field :current_sign_in_at, :type => Time
    field :last_sign_in_at,    :type => Time
    field :current_sign_in_ip, :type => String
    field :last_sign_in_ip,    :type => String

    ## Confirmable
    # field :confirmation_token,   :type => String
    # field :confirmed_at,         :type => Time
    # field :confirmation_sent_at, :type => Time
    # field :unconfirmed_email,    :type => String # Only if using reconfirmable

    ## Lockable
    # field :failed_attempts, :type => Integer, :default => 0 # Only if lock strategy is :failed_attempts
    # field :unlock_token,    :type => String # Only if unlock strategy is :email or :both
    # field :locked_at,       :type => Time

    ## Token authenticatable
    field :authentication_token, :type => String

    has_one :user

    def self.find_by_email(email)
      email.nil? ? nil : ChatApi::Account.find_by(email: email.downcase)
    end

    def self.find_by_token(token)
      token.nil? ? nil : ChatApi::Account.find_by(authentication_token: token)
    end

    def self.authorize!(params)
      account = ChatApi::Account.find_by_token(params['auth_token'])
      account.nil? ? nil : account.user
    end

    protected
    def create_user
      base_nickname = /^(.+)@/.match(email)[1]
      ChatApi::User.create!(email: email, nickname: base_nickname, account: self)
    end
  end
end
