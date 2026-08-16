class SitemapsController < ActionController::Base
  helper_method :loan_comparison_absolute_url

  def show
    @pages = RateTypeSlug.each_page
    @lastmod = Time.current.utc.iso8601

    response.headers["Cache-Control"] = "public, max-age=3600"
    render formats: :xml, layout: false
  end

  private

  def loan_comparison_absolute_url(locale:, rate_type:)
    loan_comparison_url(
      locale: locale,
      rate_type_slug: RateTypeSlug.slug_for(locale: locale, rate_type: rate_type),
      only_path: false
    )
  end
end
