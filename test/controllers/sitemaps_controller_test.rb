require "test_helper"

class SitemapsControllerTest < ActionDispatch::IntegrationTest
  test "serves sitemap with locale and rate type urls" do
    get sitemap_path

    assert_response :success
    assert_includes response.media_type, "application/xml"

    assert_includes response.body, root_url(only_path: false)
    assert_includes response.body, root_url(locale: :en, only_path: false)
    assert_includes response.body, root_url(locale: :ua, only_path: false)
    assert_includes response.body, loan_comparison_url(locale: nil, rate_type_slug: "oprocentowanie-zmienne", only_path: false)
    assert_includes response.body, loan_comparison_url(locale: nil, rate_type_slug: "oprocentowanie-stale", only_path: false)
    assert_includes response.body, loan_comparison_url(locale: :en, rate_type_slug: "variable-rate", only_path: false)
    assert_includes response.body, loan_comparison_url(locale: :en, rate_type_slug: "fixed-period", only_path: false)
    assert_includes response.body, loan_comparison_url(locale: :ua, rate_type_slug: "zminna-stavka", only_path: false)
    assert_includes response.body, loan_comparison_url(locale: :ua, rate_type_slug: "fiksovana-stavka", only_path: false)
    refute_includes response.body, root_url(locale: :pl, only_path: false)
    refute_includes response.body, loan_comparison_url(locale: :pl, rate_type_slug: "oprocentowanie-zmienne", only_path: false)
    assert_includes response.body, 'hreflang="pl"'
    assert_includes response.body, 'hreflang="en"'
    assert_includes response.body, 'hreflang="uk"'
    refute_includes response.body, 'hreflang="ua"'
    assert_includes response.body, 'hreflang="x-default"'
    refute_includes response.body, "/admin"
  end
end
