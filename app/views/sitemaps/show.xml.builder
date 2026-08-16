xml.instruct! :xml, version: "1.0", encoding: "UTF-8"
xml.urlset xmlns: "http://www.sitemaps.org/schemas/sitemap/0.9",
           "xmlns:xhtml" => "http://www.w3.org/1999/xhtml" do
  @pages.each do |page|
    xml.url do
      xml.loc loan_comparison_absolute_url(locale: page[:locale], rate_type: page[:rate_type])
      RateTypeSlug::MAP.keys.each do |locale|
        xml.tag!(
          "xhtml:link",
          rel: "alternate",
          hreflang: locale,
          href: loan_comparison_absolute_url(locale: locale, rate_type: page[:rate_type])
        )
      end
      xml.tag!(
        "xhtml:link",
        rel: "alternate",
        hreflang: "x-default",
        href: loan_comparison_absolute_url(locale: "pl", rate_type: page[:rate_type])
      )
      xml.lastmod @lastmod
      xml.changefreq "weekly"
      xml.priority(page[:rate_type] == "variable" ? "1.0" : "0.9")
    end
  end
end
