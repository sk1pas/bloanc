class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  before_action :set_locale

  helper_method :available_locales, :loan_comparison_url_for

  def default_url_options
    return {} if request.path.start_with?("/admin")

    { locale: I18n.locale }
  end

  private

  def available_locales
    %w[pl en ua]
  end

  def set_locale
    requested_locale = params[:locale].presence
    I18n.locale = available_locales.include?(requested_locale) ? requested_locale : I18n.default_locale
  end

  def loan_comparison_url_for(locale: I18n.locale, rate_type: "variable", **options)
    loan_comparison_path(
      locale: locale,
      rate_type_slug: RateTypeSlug.slug_for(locale: locale, rate_type: rate_type),
      **options
    )
  end
end
