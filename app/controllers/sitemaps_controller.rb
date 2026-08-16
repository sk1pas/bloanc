class SitemapsController < ActionController::Base
  helper_method :locale_root_url

  def show
    @locales = %w[pl en ua]
    @lastmod = Time.current.utc.iso8601

    response.headers['Cache-Control'] = 'public, max-age=3600'
    render formats: :xml, layout: false
  end

  private

  def locale_root_url(locale)
    root_url(locale: locale, only_path: false)
  end
end
