# frozen_string_literal: true

require "twilio"
# A singular user of the application.  This represents either a basic user principal
# (like a user logged into the app) or the owner of a Facebook page.
class User < ApplicationRecord
  class DeletionPending < StandardError; end
  validates :facebook_id, presence: true

  has_many :sessions, dependent: :destroy
  has_many :native_login_grants, dependent: :destroy
  has_many :service_accounts, dependent: :destroy
  has_many :user_likes, dependent: :destroy
  has_many :tribe_users, dependent: :destroy
  has_many :audience_users, dependent: :destroy
  has_many :audiences, through: :audience_users

  has_many :user_rsvps, dependent: :destroy
  has_many :photographer_admins, dependent: :destroy

  # god_mode is a global superadmin; everyone else is an admin per photographer.
  def admin?
    self.god_mode
  end

  def admin_of?(photographer)
    return true if admin?
    return false unless photographer

    photographer_admins.exists?(photographer: photographer)
  end

  def update_from(graph)
    self.name ||= graph["name"]
    self.email_address ||= graph["email"]
    self.culture ||= graph["locale"]
    self.first_name ||= graph["first_name"]
    self.last_name ||= graph["last_name"]
    self.gender ||= graph["gender"]

    self.facebook_graph = graph
  end

  def self.from_facebook_graph(graph, token: nil)
    DataDeletionRequest.with_subject(graph.fetch("id").to_s) do
      raise DeletionPending if DataDeletionRequest.pending_for?(graph.fetch("id").to_s)
      user = User.find_or_create_by(facebook_id: graph["id"].to_s) do |u|
        u.facebook_token = token
        u.facebook_token_issued_at = Time.current
        u.email_address = graph["email"]
        u.culture = graph["locale"]
        u.first_name = graph["first_name"]
        u.last_name = graph["last_name"]
        u.gender = graph["gender"]

        u.facebook_graph = graph

        Twilio.send_admin_text_message "New user registered"
      end

      raise DeletionPending if user.deletion_pending_at

      if token
        user.facebook_token = token
        user.facebook_token_issued_at = Time.current
      end

      user.update_from graph

      user.save

      user
    end
  end
end
