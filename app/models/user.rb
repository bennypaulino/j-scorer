class User < ApplicationRecord
  has_many :games, dependent: :destroy
  has_many :topics, dependent: :destroy
  has_many :sixths, through: :games

  attr_accessor :remember_token, :reset_token
  before_save { email.downcase! }
  VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i
  validates :email, length: { maximum: 50 },
                    format: { with: VALID_EMAIL_REGEX },
                    uniqueness: { case_sensitive: false }
  validates_with EmailDomainValidator
  has_secure_password
  validates :password, presence: true, length: { minimum: 6 }, allow_nil: true

  # Returns the hash digest of the given string.
  def self.digest(string)
    cost = if ActiveModel::SecurePassword.min_cost
             BCrypt::Engine::MIN_COST
           else
             BCrypt::Engine.cost
           end
    BCrypt::Password.create(string, cost: cost)
  end

  # Returns a random token (22 characters long).
  def self.new_token
    SecureRandom.urlsafe_base64
  end

  # Remembers a user in the database for use in persistent sessions.
  def remember
    self.remember_token = User.new_token
    update_attribute(:remember_digest, User.digest(remember_token))
  end

  # Returns true if the given token matches the digest.
  def authenticated?(attribute, token)
    digest = send("#{attribute}_digest")
    return false if digest.nil?
    BCrypt::Password.new(digest).is_password?(token)
  end

  # Forgets a user.
  def forget
    update_attribute(:remember_digest, nil)
  end

  # Sets the password reset attributes.
  def create_reset_digest
    self.reset_token = User.new_token
    update_columns(reset_digest:  User.digest(reset_token),
                   reset_sent_at: Time.zone.now)
  end

  def send_password_reset_email
    UserMailer.password_reset(self).deliver_now
  end

  def password_reset_expired?
    reset_sent_at < 1.hour.ago
  end

  def existing_game_date?(date)
    games.find_by(show_date: date).present?
  end

  def multi_game_summary(play_types)
    @mgs ||= MultiGameSummary.new(self, play_types).stats
  end

  def topics_summary(play_types)
    @ts ||= TopicsSummary.new(self, play_types).stats
  end

  def results_by_row(play_types)
    @rbr ||= ResultsByRow.new(self, play_types).stats
  end

  def final_stats(play_types)
    @fs ||= FinalStatsReport.new(self, play_types).stats
  end

  def play_type_summary
    @pts ||= PlayTypeSummary.new(self).stats
  end
end
