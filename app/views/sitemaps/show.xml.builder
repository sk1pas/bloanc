xml.instruct! :xml, version: "1.0", encoding: "UTF-8"
xml.urlset xmlns: "http://www.sitemaps.org/schemas/sitemap/0.9",
           "xmlns:xhtml" => "http://www.w3.org/1999/xhtml" do
  @locales.each do |locale|
    xml.url do
      xml.loc locale_root_url(locale)
      @locales.each do |alternate|
        xml.tag!("xhtml:link", rel: "alternate", hreflang: alternate, href: locale_root_url(alternate))
      end
      xml.tag!("xhtml:link", rel: "alternate", hreflang: "x-default", href: locale_root_url("pl"))
      xml.lastmod @lastmod
      xml.changefreq "weekly"
      xml.priority "1.0"
    end
  end
end
