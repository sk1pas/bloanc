module ComparisonUrls
  extend ActiveSupport::Concern

  included do
    helper_method :comparison_page_path,
                  :comparison_page_url,
                  :comparison_results_path,
                  :locale_switch_url,
                  :locale_home_path,
                  :rate_type_switch_path,
                  :canonical_comparison_url,
                  :hreflang_comparison_url,
                  :on_rate_type_path?,
                  :locale_in_path?
  end

  def on_rate_type_path?
    @on_rate_type_path
  end

  def locale_in_path?
    @locale_in_path
  end

  def comparison_page_path(locale: I18n.locale, rate_type: current_comparison_rate_type, **options)
    RateTypeSlug.comparison_path(
      locale: locale,
      rate_type: rate_type,
      locale_in_path: locale_in_path?,
      rate_type_in_path: on_rate_type_path?,
      **options
    )
  end

  def comparison_page_url(locale: I18n.locale, rate_type: current_comparison_rate_type, **options)
    RateTypeSlug.comparison_url(
      locale: locale,
      rate_type: rate_type,
      locale_in_path: locale_in_path?,
      rate_type_in_path: on_rate_type_path?,
      **options
    )
  end

  def comparison_results_path(rate_type: current_comparison_rate_type, **options)
    if on_rate_type_path?
      comparison_page_path(rate_type: rate_type, **options)
    else
      rate_type_switch_path("variable", **options)
    end
  end

  def locale_home_path(locale: I18n.locale, **options)
    RateTypeSlug.comparison_path(
      locale: locale,
      rate_type: "variable",
      locale_in_path: RateTypeSlug.locale_prefix_in_url?(locale, locale_in_path: locale_in_path?),
      rate_type_in_path: false,
      **options
    )
  end

  def locale_switch_url(target_locale)
    url_options = comparison_query_params.merge(only_path: false)

    if on_rate_type_path?
      RateTypeSlug.comparison_url(
        locale: target_locale,
        rate_type: current_comparison_rate_type,
        locale_in_path: RateTypeSlug.locale_prefix_in_url?(target_locale, locale_in_path: locale_in_path?),
        rate_type_in_path: true,
        **url_options
      )
    else
      RateTypeSlug.comparison_url(
        locale: target_locale,
        rate_type: "variable",
        locale_in_path: RateTypeSlug.locale_prefix_in_url?(target_locale, locale_in_path: locale_in_path?),
        rate_type_in_path: false,
        **url_options
      )
    end
  end

  def rate_type_switch_path(target_rate_type, **options)
    RateTypeSlug.comparison_path(
      locale: I18n.locale,
      rate_type: target_rate_type,
      locale_in_path: locale_in_path?,
      rate_type_in_path: true,
      **options
    )
  end

  def canonical_comparison_url
    preferred_comparison_url(
      locale: I18n.locale,
      rate_type: current_comparison_rate_type,
      rate_type_in_path: on_rate_type_path?
    )
  end

  def hreflang_comparison_url(target_locale)
    preferred_comparison_url(
      locale: target_locale,
      rate_type: current_comparison_rate_type,
      rate_type_in_path: on_rate_type_path?
    )
  end

  def comparison_query_params
    return {} unless params.is_a?(ActionController::Parameters)

    params.permit(*comparison_query_param_keys).to_h.symbolize_keys
  end

  def comparison_query_param_keys
    %i[
      loan_amount
      years
      overpayment_mode
      fixed_monthly_payment
      target_years
      fixed_monthly_overpay_during_penalty
      fixed_period_overpay_during_penalty
    ]
  end

  private

  def preferred_comparison_url(locale:, rate_type:, rate_type_in_path:)
    RateTypeSlug.comparison_url(
      locale: locale,
      rate_type: rate_type,
      locale_in_path: RateTypeSlug.canonical_locale_in_path?(locale),
      rate_type_in_path: rate_type_in_path,
      only_path: false
    )
  end

  def current_comparison_rate_type
    @rate_type.presence || "variable"
  end

  def assign_comparison_path_context!
    @on_rate_type_path = params[:rate_type_slug].present?
    @locale_in_path = params[:locale].present?
  end
end
