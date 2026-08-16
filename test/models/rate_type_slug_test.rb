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

  test "resolves rate type from slug" do
    assert_equal "variable", RateTypeSlug.rate_type_for(locale: :en, slug: "variable-rate")
    assert_equal "fixed_period", RateTypeSlug.rate_type_for(locale: :ua, slug: "fiksovana-stavka")
    assert_nil RateTypeSlug.rate_type_for(locale: :pl, slug: "variable-rate")
  end
end
