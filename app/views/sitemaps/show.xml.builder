xml.instruct! :xml, version: "1.0", encoding: "UTF-8"
xml.urlset xmlns: "http://www.sitemaps.org/schemas/sitemap/0.9",
           "xmlns:xhtml" => "http://www.w3.org/1999/xhtml" do
  @pages.each do |page|
    xml.url do
      xml.loc loan_comparison_absolute_url(
        locale: page[:locale],
        rate_type: page[:rate_type],
        locale_in_path: page[:locale_in_path],
        rate_type_in_path: page[:rate_type_in_path]
      )
      RateTypeSlug::MAP.keys.each do |locale|
        xml.tag!(
          "xhtml:link",
          rel: "alternate",
          hreflang: hreflang_for(locale),
          href: loan_comparison_absolute_url(
            locale: locale,
            rate_type: page[:rate_type],
            locale_in_path: RateTypeSlug.canonical_locale_in_path?(locale),
            rate_type_in_path: page[:rate_type_in_path]
          )
        )
      end
      xml.tag!(
        "xhtml:link",
        rel: "alternate",
        hreflang: "x-default",
        href: loan_comparison_absolute_url(
          locale: RateTypeSlug::DEFAULT_LOCALE,
          rate_type: page[:rate_type],
          locale_in_path: RateTypeSlug.canonical_locale_in_path?(RateTypeSlug::DEFAULT_LOCALE),
          rate_type_in_path: page[:rate_type_in_path]
        )
      )
      xml.lastmod @lastmod
      xml.changefreq "weekly"
      xml.priority(page[:rate_type] == "variable" && page[:rate_type_in_path] == false ? "1.0" : "0.9")
    end
  end
end
