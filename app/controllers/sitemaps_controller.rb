class SitemapsController < ActionController::Base
  include ComparisonUrls

  helper ApplicationHelper
  helper_method :loan_comparison_absolute_url

  def show
    @pages = RateTypeSlug.sitemap_entries
    @lastmod = Time.current.utc.iso8601

    response.headers["Cache-Control"] = "public, max-age=3600"
    render formats: :xml, layout: false
  end

  private

  def loan_comparison_absolute_url(locale:, rate_type:, locale_in_path:, rate_type_in_path:)
    RateTypeSlug.comparison_url(
      locale: locale,
      rate_type: rate_type,
      locale_in_path: locale_in_path,
      rate_type_in_path: rate_type_in_path,
      only_path: false
    )
  end

  def assign_comparison_path_context!
    @on_rate_type_path = false
    @locale_in_path = false
  end
end
