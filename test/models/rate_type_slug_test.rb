require "test_helper"

class RateTypeSlugTest < ActiveSupport::TestCase
  test "maps locales to localized slugs" do
    assert_equal "oprocentowanie-zmienne", RateTypeSlug.slug_for(locale: :pl, rate_type: "variable")
    assert_equal "oprocentowanie-stale", RateTypeSlug.slug_for(locale: :pl, rate_type: "fixed_period")
    assert_equal "variable-rate", RateTypeSlug.slug_for(locale: :en, rate_type: "variable")
    assert_equal "fixed-period", RateTypeSlug.slug_for(locale: :en, rate_type: "fixed_period")
    assert_equal "zminna-stavka", RateTypeSlug.slug_for(locale: :ua, rate_type: "variable")
    assert_equal "fiksovana-stavka", RateTypeSlug.slug_for(locale: :ua, rate_type: "fixed_period")
  end

  test "builds comparison paths for locale-only and slug routes" do
    assert_equal "/", RateTypeSlug.comparison_path(
      locale: :pl, rate_type: "variable", locale_in_path: false, rate_type_in_path: false
    )
    assert_equal "/pl", RateTypeSlug.comparison_path(
      locale: :pl, rate_type: "variable", locale_in_path: true, rate_type_in_path: false
    )
    assert_equal "/oprocentowanie-zmienne", RateTypeSlug.comparison_path(
      locale: :pl, rate_type: "variable", locale_in_path: false, rate_type_in_path: true
    )
    assert_equal "/pl/oprocentowanie-zmienne", RateTypeSlug.comparison_path(
      locale: :pl, rate_type: "variable", locale_in_path: true, rate_type_in_path: true
    )
    assert_equal "/pl/oprocentowanie-stale", RateTypeSlug.comparison_path(
      locale: :pl, rate_type: "fixed_period", locale_in_path: true, rate_type_in_path: true
    )
  end

  test "resolves rate type from slug" do
    assert_equal "variable", RateTypeSlug.rate_type_for(locale: :en, slug: "variable-rate")
    assert_equal "fixed_period", RateTypeSlug.rate_type_for(locale: :ua, slug: "fiksovana-stavka")
    assert_nil RateTypeSlug.rate_type_for(locale: :pl, slug: "variable-rate")
  end

  test "canonical locale prefix omits polish default locale only" do
    refute RateTypeSlug.canonical_locale_in_path?(:pl)
    assert RateTypeSlug.canonical_locale_in_path?(:en)
    assert RateTypeSlug.canonical_locale_in_path?(:ua)
  end

  test "sitemap lists canonical urls only" do
    entries = RateTypeSlug.sitemap_entries
    locs = entries.map do |entry|
      RateTypeSlug.comparison_path(
        locale: entry[:locale],
        rate_type: entry[:rate_type],
        locale_in_path: entry[:locale_in_path],
        rate_type_in_path: entry[:rate_type_in_path]
      )
    end

    assert_includes locs, "/"
    assert_includes locs, "/en"
    assert_includes locs, "/ua"
    assert_includes locs, "/oprocentowanie-zmienne"
    assert_includes locs, "/oprocentowanie-stale"
    assert_includes locs, "/en/variable-rate"
    assert_includes locs, "/ua/zminna-stavka"
    refute_includes locs, "/pl"
    refute_includes locs, "/pl/oprocentowanie-zmienne"
  end
end
