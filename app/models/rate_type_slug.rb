class RateTypeSlug
  RATE_TYPES = %w[variable fixed_period].freeze

  MAP = {
    "pl" => {
      "variable" => "oprocentowanie-zmienne",
      "fixed_period" => "oprocentowanie-stale"
    },
    "en" => {
      "variable" => "variable-rate",
      "fixed_period" => "fixed-period"
    },
    "ua" => {
      "variable" => "zminna-stavka",
      "fixed_period" => "fiksovana-stavka"
    }
  }.freeze

  class << self
    def slug_for(locale:, rate_type:)
      MAP.fetch(normalize_locale(locale)).fetch(normalize_rate_type(rate_type))
    end

    def rate_type_for(locale:, slug:)
      MAP.fetch(normalize_locale(locale)).key(slug.to_s)
    end

    def valid_slug?(locale:, slug:)
      rate_type_for(locale: locale, slug: slug).present?
    end

    def all_slugs
      MAP.values.flat_map(&:values).uniq
    end

    def constraint
      Regexp.union(all_slugs.map { |slug| Regexp.new(Regexp.escape(slug)) })
    end

    def each_page
      MAP.flat_map do |locale, rate_types|
        rate_types.map do |rate_type, slug|
          { locale: locale, rate_type: rate_type, slug: slug }
        end
      end
    end

    private

    def normalize_locale(locale)
      key = locale.to_s
      MAP.key?(key) ? key : "pl"
    end

    def normalize_rate_type(rate_type)
      type = rate_type.to_s
      RATE_TYPES.include?(type) ? type : "variable"
    end
  end
end
