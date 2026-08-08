require "digest"

class Admin::BaseController < ApplicationController
  layout "admin"
  skip_before_action :set_locale
  before_action :authenticate_admin
  before_action :force_admin_locale

  private

  def authenticate_admin
    authenticate_or_request_with_http_basic("Admin area") do |username, password|
      secure_compare(username, admin_username) && secure_compare(password, admin_password)
    end
  end

  def admin_username
    ENV.fetch("ADMIN_USERNAME", Rails.env.development? || Rails.env.test? ? "admin" : "")
  end

  def admin_password
    ENV.fetch("ADMIN_PASSWORD", Rails.env.development? || Rails.env.test? ? "admin123" : "")
  end

  def secure_compare(value, expected)
    return false if expected.blank?

    ActiveSupport::SecurityUtils.secure_compare(
      Digest::SHA256.hexdigest(value.to_s),
      Digest::SHA256.hexdigest(expected.to_s)
    )
  end

  def force_admin_locale
    I18n.locale = :en
  end
end
