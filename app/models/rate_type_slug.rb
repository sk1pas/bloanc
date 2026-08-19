class RateTypeSlug
  RATE_TYPES = %w[variable fixed_period].freeze
  DEFAULT_LOCALE = "pl".freeze

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

    def sitemap_entries
      entries = MAP.keys.map do |locale|
        {
          locale: locale,
          rate_type: "variable",
          locale_in_path: canonical_locale_in_path?(locale),
          rate_type_in_path: false
        }
      end

      each_page.each do |page|
        entries << {
          locale: page[:locale],
          rate_type: page[:rate_type],
          locale_in_path: canonical_locale_in_path?(page[:locale]),
          rate_type_in_path: true
        }
      end

      entries.uniq
    end

    def comparison_path(locale:, rate_type:, locale_in_path:, rate_type_in_path:, **options)
      normalized_locale = normalize_locale(locale)
      normalized_rate_type = normalize_rate_type(rate_type)
      path_options = options.except(:only_path)

      if rate_type_in_path
        slug = slug_for(locale: normalized_locale, rate_type: normalized_rate_type)
        locale_option = locale_in_path ? normalized_locale : nil
        route_helpers.loan_comparison_path(locale: locale_option, rate_type_slug: slug, **path_options)
      elsif locale_in_path
        route_helpers.root_path(locale: normalized_locale, **path_options)
      else
        route_helpers.root_path(locale: nil, **path_options)
      end
    end

    def comparison_url(locale:, rate_type:, locale_in_path:, rate_type_in_path:, **options)
      normalized_locale = normalize_locale(locale)
      normalized_rate_type = normalize_rate_type(rate_type)
      url_options = default_url_options.merge(options.except(:only_path))

      if rate_type_in_path
        slug = slug_for(locale: normalized_locale, rate_type: normalized_rate_type)
        locale_option = locale_in_path ? normalized_locale : nil
        route_helpers.loan_comparison_url(locale: locale_option, rate_type_slug: slug, **url_options)
      elsif locale_in_path
        route_helpers.root_url(locale: normalized_locale, **url_options)
      else
        route_helpers.root_url(locale: nil, **url_options)
      end
    end

    def locale_prefix_in_url?(target_locale, locale_in_path:)
      locale_in_path || canonical_locale_in_path?(target_locale)
    end

    def canonical_locale_in_path?(locale)
      normalize_locale(locale) != DEFAULT_LOCALE
    end

    private

    def default_url_options
      Rails.application.routes.default_url_options.presence ||
        Rails.application.config.action_mailer.default_url_options
    end

    def route_helpers
      Rails.application.routes.url_helpers
    end

    def normalize_locale(locale)
      key = locale.to_s
      MAP.key?(key) ? key : DEFAULT_LOCALE
    end

    def normalize_rate_type(rate_type)
      type = rate_type.to_s
      RATE_TYPES.include?(type) ? type : "variable"
    end
  end
end
