class LoanComparisonsController < ApplicationController
  DEFAULT_LOAN_AMOUNT = 400_000
  DEFAULT_YEARS = 25
  OVERPAYMENT_MODES = %w[none fixed_monthly fixed_period].freeze

  def index
    prepare_request
    load_offer_results
  end

  def custom_compare
    prepare_request
    load_offer_results
    @custom_offer = custom_offer_params.to_h
    @custom_result = calculate_custom_offer(@custom_offer)

    render :index
  rescue ActionController::ParameterMissing
    redirect_to root_path(locale: I18n.locale), alert: t('home.flash.custom_offer_invalid')
  end

  private

  def prepare_request
    @loan_amount = normalize_integer(params[:loan_amount], DEFAULT_LOAN_AMOUNT)
    @loan_years, @months = extract_period
    @overpayment_mode = normalize_overpayment_mode(params[:overpayment_mode])
    @fixed_monthly_payment = normalize_decimal(params[:fixed_monthly_payment], 3_000)
    @target_years = normalize_target_years(params[:target_years])
    @fixed_monthly_overpay_during_penalty = normalize_boolean(params[:fixed_monthly_overpay_during_penalty], true)
    @fixed_period_overpay_during_penalty = normalize_boolean(params[:fixed_period_overpay_during_penalty], true)
    @wibor_snapshot = WiborSnapshot.latest
    @custom_offer = {}
    @custom_result = nil
  end

  def load_offer_results
    @loan_offers = LoanOffer.active.ordered.includes(:bank)
    @results = @loan_offers.map { |offer| calculate_offer(offer) }
  end

  def calculate_offer(loan_offer)
    wibor_percent = loan_offer.current_wibor_percent(@wibor_snapshot).to_f
    rate_percent = loan_offer.bank_margin_percent.to_f + wibor_percent

    base_calculation = calculate_for_offer(
      loan_offer: loan_offer,
      overpayment_mode: 'none',
      overpayment_amount: 0
    )

    simulation = apply_overpayment_simulation(loan_offer: loan_offer, base_calculation: base_calculation)
    calculation = simulation[:calculation]

    monthly_bank_payment = calculation[:monthly_principal_interest].to_f
    monthly_user_overpayment = simulation[:monthly_overpayment].to_f
    property_insurance_monthly = loan_offer.property_insurance_monthly.to_f
    default_monthly_payment =
      if simulation[:default_monthly_payment].present?
        simulation[:default_monthly_payment].to_f
      else
        monthly_bank_payment + monthly_user_overpayment + property_insurance_monthly
      end
    loan_period_months = calculation[:months_paid]

    {
      custom: false,
      bank_title: loan_offer.bank.title,
      bank_logo: loan_offer.bank.logo,
      bank_website_url: loan_offer.bank.website_url,
      offer_title: loan_offer.title,
      offer_description: loan_offer.description,
      promoted_from: loan_offer.promoted_from,
      promoted_until: loan_offer.promoted_until,
      bank_margin_percent: loan_offer.bank_margin_percent.to_f,
      rate_percent: rate_percent,
      wibor_kind: loan_offer.wibor_kind,
      wibor_percent: wibor_percent,
      monthly_bank_payment: monthly_bank_payment,
      monthly_user_overpayment: monthly_user_overpayment,
      default_monthly_payment: default_monthly_payment,
      monthly_payment: default_monthly_payment.round,
      first_month_payment: calculation[:first_month_payment],
      loan_period_months: loan_period_months,
      loan_period_label: loan_period_label(loan_period_months),
      loan_amount: @loan_amount,
      total_paid: calculation[:total_paid],
      total_cost: calculation[:total_cost],
      bank_interest_total: calculation[:bank_interest_total],
      life_insurance_total: calculation[:life_insurance_total],
      life_insurance_details: life_insurance_detail_for_total_paid(loan_offer: loan_offer, calculation: calculation),
      property_insurance_total: calculation[:property_insurance_total],
      property_insurance_details: property_insurance_detail_for_total_paid(loan_offer: loan_offer, calculation: calculation),
      bank_commission_total: calculation[:bank_commission_total],
      overpayment_penalty_total: calculation[:overpayment_penalty_total],
      months_paid: calculation[:months_paid],
      notes: build_column_notes(
        loan_offer: loan_offer,
        calculation: calculation,
        simulation: simulation,
        rate_percent: rate_percent
      )
    }
  end

  def calculate_custom_offer(raw_offer)
    wibor_kind = raw_offer.fetch('wibor_kind', 'wibor_3m')
    wibor_percent =
      if raw_offer['wibor_percent'].present?
        normalize_decimal(raw_offer['wibor_percent'])
      else
        @wibor_snapshot&.rate_for(wibor_kind).to_f
      end

    calculation = LoanCalculator.new(
      loan_net: @loan_amount,
      months: @months,
      bank_margin_percent: normalize_decimal(raw_offer['bank_margin_percent']),
      wibor_percent: wibor_percent,
      bank_commission_percentage: normalize_decimal(raw_offer['bank_commission_percent']),
      insurance: {
        life_insurance_percent: normalize_optional_decimal(raw_offer['life_insurance_percent']),
        life_insurance_years: normalize_optional_integer(raw_offer['life_insurance_years']),
        life_insurance_total: normalize_optional_decimal(raw_offer['life_insurance_total']),
        property_insurance_monthly: normalize_decimal(raw_offer['property_insurance_monthly'])
      },
      overpayment_grace_years: normalize_integer(raw_offer['overpayment_grace_years'], 0),
      overpayment_mode: raw_offer['overpayment_mode'],
      overpayment_coef: normalize_decimal(raw_offer['overpayment_coef'], 1.0),
      overpayment_amount: normalize_decimal(raw_offer['overpayment_amount'], 0.0),
      overpayment_penalty_years: normalize_integer(raw_offer['overpayment_penalty_years'], 0),
      overpayment_penalty_percent: normalize_decimal(raw_offer['overpayment_penalty_percent'], 0.0),
      overpayment_penalty_min_amount: normalize_decimal(raw_offer['overpayment_penalty_min_amount'], 0.0)
    ).call

    {
      custom: true,
      bank_title: raw_offer['bank_title'].presence || t('home.custom.bank_fallback'),
      bank_logo: nil,
      bank_website_url: nil,
      offer_title: raw_offer['title'].presence || t('home.custom.offer_fallback'),
      offer_description: raw_offer['description'],
      promoted_from: nil,
      promoted_until: nil,
      bank_margin_percent: normalize_decimal(raw_offer['bank_margin_percent']),
      wibor_kind: wibor_kind,
      wibor_percent: wibor_percent,
      monthly_payment: calculation[:monthly_principal_interest],
      first_month_payment: calculation[:first_month_payment],
      total_paid: calculation[:total_paid],
      total_cost: calculation[:total_cost],
      bank_interest_total: calculation[:bank_interest_total],
      life_insurance_total: calculation[:life_insurance_total],
      property_insurance_total: calculation[:property_insurance_total],
      months_paid: calculation[:months_paid],
      notes: {}
    }
  end

  def calculate_for_offer(loan_offer:, overpayment_mode:, overpayment_amount:, overpayment_grace_years: 0)
    base_params = loan_offer.calculator_params(
      loan_net: @loan_amount,
      months: @months,
      wibor_snapshot: @wibor_snapshot
    )

    LoanCalculator.new(
      **base_params,
      overpayment_mode: overpayment_mode,
      overpayment_grace_years: overpayment_grace_years,
      overpayment_coef: 1.0,
      overpayment_amount: overpayment_amount
    ).call
  end

  def apply_overpayment_simulation(loan_offer:, base_calculation:)
    base_monthly_payment = base_calculation[:monthly_principal_interest].to_f

    case @overpayment_mode
    when "fixed_monthly"
      apply_fixed_monthly_overpayment(
        loan_offer: loan_offer,
        base_calculation: base_calculation,
        base_monthly_payment: base_monthly_payment
      )
    when "fixed_period"
      apply_fixed_period_overpayment(
        loan_offer: loan_offer,
        base_calculation: base_calculation,
        base_monthly_payment: base_monthly_payment
      )
    else
      {
        calculation: base_calculation,
        monthly_overpayment: 0.0,
        note: nil,
        default_monthly_payment: nil,
        overpay_during_penalty: true
      }
    end
  end

  def apply_fixed_monthly_overpayment(loan_offer:, base_calculation:, base_monthly_payment:)
    overpay_during_penalty = @fixed_monthly_overpay_during_penalty
    overpayment_grace_years = overpayment_grace_years_for_simulation(
      loan_offer: loan_offer,
      overpay_during_penalty: overpay_during_penalty
    )

    requested_total_payment = @fixed_monthly_payment.to_f
    minimum_total_payment = minimum_total_payment_for_fixed_monthly(
      loan_offer: loan_offer,
      base_monthly_payment: base_monthly_payment
    )

    if requested_total_payment <= minimum_total_payment
      return {
        calculation: base_calculation,
        monthly_overpayment: 0.0,
        note: t("home.overpayment.notes.fixed_monthly_invalid", min_payment: format_number(minimum_total_payment + 1, 0)),
        default_monthly_payment: nil,
        overpay_during_penalty: overpay_during_penalty
      }
    end

    overpayment_amount = overpayment_amount_for_target_total_payment(
      loan_offer: loan_offer,
      requested_total_payment: requested_total_payment,
      base_monthly_payment: base_monthly_payment
    )

    if overpayment_amount <= 0
      return {
        calculation: base_calculation,
        monthly_overpayment: 0.0,
        note: t("home.overpayment.notes.fixed_monthly_invalid", min_payment: format_number(minimum_total_payment + 1, 0)),
        default_monthly_payment: nil,
        overpay_during_penalty: overpay_during_penalty
      }
    end

    calculation = calculate_for_offer(
      loan_offer: loan_offer,
      overpayment_mode: "absolute",
      overpayment_amount: overpayment_amount,
      overpayment_grace_years: overpayment_grace_years
    )

    {
      calculation: calculation,
      monthly_overpayment: overpayment_amount,
      note: t("home.overpayment.notes.fixed_monthly_applied", monthly_payment: format_number(requested_total_payment, 0)),
      default_monthly_payment: requested_total_payment,
      overpay_during_penalty: overpay_during_penalty
    }
  end

  def apply_fixed_period_overpayment(loan_offer:, base_calculation:, base_monthly_payment:)
    target_months = @target_years * 12
    if target_months >= @months
      return {
        calculation: base_calculation,
        monthly_overpayment: 0.0,
        note: t("home.overpayment.notes.fixed_period_invalid", max_years: [@loan_years - 1, 1].max),
        default_monthly_payment: nil,
        overpay_during_penalty: @fixed_period_overpay_during_penalty
      }
    end

    overpay_during_penalty = @fixed_period_overpay_during_penalty
    overpayment_grace_years = overpayment_grace_years_for_simulation(
      loan_offer: loan_offer,
      overpay_during_penalty: overpay_during_penalty
    )

    overpayment_amount = overpayment_amount_for_target_period(
      loan_offer: loan_offer,
      target_months: target_months,
      overpayment_grace_years: overpayment_grace_years
    )

    if overpayment_amount <= 0
      return {
        calculation: base_calculation,
        monthly_overpayment: 0.0,
        note: t("home.overpayment.notes.fixed_period_invalid", max_years: [@loan_years - 1, 1].max),
        default_monthly_payment: nil,
        overpay_during_penalty: overpay_during_penalty
      }
    end

    calculation = calculate_for_offer(
      loan_offer: loan_offer,
      overpayment_mode: "absolute",
      overpayment_amount: overpayment_amount,
      overpayment_grace_years: overpayment_grace_years
    )

    if calculation[:months_paid].to_i > target_months
      return {
        calculation: base_calculation,
        monthly_overpayment: 0.0,
        note: t("home.overpayment.notes.fixed_period_invalid", max_years: [@loan_years - 1, 1].max),
        default_monthly_payment: nil,
        overpay_during_penalty: overpay_during_penalty
      }
    end

    required_payment = base_monthly_payment + loan_offer.property_insurance_monthly.to_f + overpayment_amount

    {
      calculation: calculation,
      monthly_overpayment: overpayment_amount,
      note: t(
        "home.overpayment.notes.fixed_period_applied",
        years: @target_years,
        monthly_payment: format_number(required_payment, 0)
      ),
      default_monthly_payment: nil,
      overpay_during_penalty: overpay_during_penalty
    }
  end

  def build_column_notes(loan_offer:, calculation:, simulation:, rate_percent:)
    monthly_overpayment = simulation[:monthly_overpayment].to_f
    overpay_during_penalty = simulation.fetch(:overpay_during_penalty, true)
    monthly_penalty = monthly_penalty_for(
      loan_offer: loan_offer,
      monthly_overpayment: monthly_overpayment,
      overpay_during_penalty: overpay_during_penalty
    )
    penalty_months = penalty_months_for(
      loan_offer: loan_offer,
      months_paid: calculation[:months_paid],
      monthly_overpayment: monthly_overpayment,
      overpay_during_penalty: overpay_during_penalty
    )

    default_payment_note_parts = []
    if monthly_overpayment.positive?
      default_payment_note_parts << t("home.notes.default_payment.user_overpayment", amount: format_number(monthly_overpayment, 0))
      if monthly_penalty.positive? && penalty_months.positive?
        default_payment_note_parts << t(
          "home.notes.default_payment.overpayment_penalty",
          amount: format_number(monthly_penalty, 0),
          months: penalty_months
        )
      end
    end

    first_month_note_parts = [
      t(
        "home.notes.first_month.base_payment",
        amount: format_number(calculation[:monthly_principal_interest].to_f + monthly_overpayment, 0)
      )
    ]

    recurring_life_insurance = recurring_life_insurance_for_offer(loan_offer)
    if recurring_life_insurance.positive?
      life_insurance_months = [loan_offer.life_insurance_years.to_i * 12, calculation[:months_paid]].min
      first_month_note_parts << t(
        "home.notes.first_month.life_insurance_recurring",
        amount: format_number(recurring_life_insurance, 0),
        months: life_insurance_months
      )
    end

    if loan_offer.property_insurance_monthly.to_f.positive?
      first_month_note_parts << t(
        "home.notes.first_month.property_insurance",
        amount: format_number(loan_offer.property_insurance_monthly, 0),
        months: calculation[:months_paid]
      )
    end

    if monthly_penalty.positive? && penalty_months.positive?
      first_month_note_parts << t(
        "home.notes.first_month.overpayment_penalty",
        amount: format_number(monthly_penalty, 0),
        months: penalty_months
      )
    end

    if simulation[:note].present?
      first_month_note_parts << simulation[:note]
    end

    {
      rate: t(
        "home.notes.rate",
        rate: format_number(rate_percent, 2),
        margin: format_number(loan_offer.bank_margin_percent, 2),
        wibor_kind: loan_offer.wibor_kind.upcase,
        wibor: format_number(loan_offer.current_wibor_percent(@wibor_snapshot), 2)
      ),
      default_monthly: default_payment_note_parts.join(". ").presence,
      first_month_lines: first_month_note_parts,
      total_paid: total_paid_note(calculation: calculation)
    }
  end

  def life_insurance_detail_for_total_paid(loan_offer:, calculation:)
    if loan_offer.life_insurance_total.present?
      return t(
        "home.results.breakdown_details.life_insurance_one_time",
        amount: format_number(loan_offer.life_insurance_total, 0)
      )
    end

    if loan_offer.life_insurance_percent.present? && loan_offer.life_insurance_years.present?
      insurance_months = [loan_offer.life_insurance_years.to_i * 12, calculation[:months_paid]].min
      first_month_insurance = recurring_life_insurance_for_offer(loan_offer)

      return t(
        "home.results.breakdown_details.life_insurance_percent",
        percent: format_number(loan_offer.life_insurance_percent, 4),
        months: insurance_months,
        first_month: format_number(first_month_insurance, 0)
      )
    end

    t("home.results.breakdown_details.life_insurance_none")
  end

  def property_insurance_detail_for_total_paid(loan_offer:, calculation:)
    monthly_cost = loan_offer.property_insurance_monthly.to_f
    return t("home.results.breakdown_details.property_insurance_none") unless monthly_cost.positive?

    t(
      "home.results.breakdown_details.property_insurance_monthly",
      monthly: format_number(monthly_cost, 0),
      months: calculation[:months_paid]
    )
  end

  def total_paid_note(calculation:)
    notes = []
    if calculation[:bank_commission_total].to_f.positive?
      notes << t("home.notes.total_paid_commission", amount: format_number(calculation[:bank_commission_total], 0))
    end
    if calculation[:overpayment_penalty_total].to_f.positive?
      notes << t("home.notes.total_paid_penalty", amount: format_number(calculation[:overpayment_penalty_total], 0))
    end

    notes.join(". ")
  end

  def minimum_total_payment_for_fixed_monthly(loan_offer:, base_monthly_payment:)
    base_monthly_payment.to_f + loan_offer.property_insurance_monthly.to_f
  end

  def recurring_life_insurance_for_offer(loan_offer)
    return 0.0 if loan_offer.life_insurance_total.present?
    return 0.0 unless loan_offer.life_insurance_percent.present? && loan_offer.life_insurance_years.to_i.positive?

    @loan_amount.to_f * (loan_offer.life_insurance_percent.to_f / 100.0)
  end

  def overpayment_amount_for_target_total_payment(loan_offer:, requested_total_payment:, base_monthly_payment:)
    available_extra_budget = requested_total_payment.to_f - base_monthly_payment.to_f - loan_offer.property_insurance_monthly.to_f
    return 0.0 if available_extra_budget <= 0

    available_extra_budget
  end

  def overpayment_amount_for_target_period(loan_offer:, target_months:, overpayment_grace_years:)
    low = 0.0
    high = [@loan_amount.to_f / [target_months, 1].max, 100.0].max
    max_high = [@loan_amount.to_f, 50_000.0].max

    high_calculation = calculate_for_offer(
      loan_offer: loan_offer,
      overpayment_mode: "absolute",
      overpayment_amount: high,
      overpayment_grace_years: overpayment_grace_years
    )

    while high_calculation[:months_paid].to_i > target_months && high < max_high
      high *= 2.0
      high_calculation = calculate_for_offer(
        loan_offer: loan_offer,
        overpayment_mode: "absolute",
        overpayment_amount: high,
        overpayment_grace_years: overpayment_grace_years
      )
    end

    return 0.0 if high_calculation[:months_paid].to_i > target_months

    24.times do
      mid = (low + high) / 2.0
      mid_calculation = calculate_for_offer(
        loan_offer: loan_offer,
        overpayment_mode: "absolute",
        overpayment_amount: mid,
        overpayment_grace_years: overpayment_grace_years
      )

      if mid_calculation[:months_paid].to_i > target_months
        low = mid
      else
        high = mid
      end
    end

    high
  end

  def monthly_penalty_for(loan_offer:, monthly_overpayment:, overpay_during_penalty:)
    return 0.0 unless monthly_overpayment.to_f.positive?
    return 0.0 unless overpay_during_penalty
    return 0.0 unless loan_offer.overpayment_penalty_years.to_i.positive?

    percent_fee = monthly_overpayment.to_f * (loan_offer.overpayment_penalty_percent.to_f / 100.0)
    [percent_fee, loan_offer.overpayment_penalty_min_amount.to_f].max
  end

  def penalty_months_for(loan_offer:, months_paid:, monthly_overpayment:, overpay_during_penalty:)
    return 0 unless monthly_overpayment.to_f.positive?
    return 0 unless overpay_during_penalty

    [loan_offer.overpayment_penalty_years.to_i * 12, months_paid.to_i].min
  end

  def overpayment_grace_years_for_simulation(loan_offer:, overpay_during_penalty:)
    return 0 if overpay_during_penalty

    [loan_offer.overpayment_penalty_years.to_i, 0].max
  end

  def extract_period
    return extract_year_period if params[:years].present?

    months = normalize_integer(params[:months], DEFAULT_YEARS * 12)
    years = [(months / 12.0).round, 1].max
    [years, months]
  end

  def extract_year_period
    years = normalize_integer(params[:years], DEFAULT_YEARS)
    [years, years * 12]
  end

  def normalize_overpayment_mode(value)
    mode = value.to_s
    OVERPAYMENT_MODES.include?(mode) ? mode : "none"
  end

  def normalize_target_years(value)
    target = normalize_integer(value, 10)
    upper_bound = [@loan_years - 1, 1].max
    [[target, upper_bound].min, 1].max
  end

  def normalize_integer(value, default)
    normalized = value.to_i
    normalized.positive? ? normalized : default
  end

  def normalize_optional_integer(value)
    return nil if value.blank?

    value.to_i
  end

  def normalize_decimal(value, default = 0.0)
    return default if value.blank?

    value.to_s.tr(",", ".").to_f
  end

  def normalize_boolean(value, default)
    return default if value.nil?

    ActiveModel::Type::Boolean.new.cast(value)
  end

  def normalize_optional_decimal(value)
    return nil if value.blank?

    normalize_decimal(value)
  end

  def format_number(value, precision)
    helpers.number_with_precision(value, precision: precision, strip_insignificant_zeros: true)
  end

  def loan_period_label(months)
    full_years = months / 12
    remaining_months = months % 12

    if remaining_months.zero?
      t("home.results.period_years_only", years: full_years)
    else
      t("home.results.period_years_months", years: full_years, months: remaining_months)
    end
  end

  def custom_offer_params
    params.require(:custom_offer).permit(
      :bank_title,
      :title,
      :description,
      :bank_margin_percent,
      :wibor_kind,
      :wibor_percent,
      :bank_commission_percent,
      :life_insurance_percent,
      :life_insurance_years,
      :life_insurance_total,
      :property_insurance_monthly,
      :overpayment_grace_years,
      :overpayment_mode,
      :overpayment_coef,
      :overpayment_amount,
      :overpayment_penalty_years,
      :overpayment_penalty_percent,
      :overpayment_penalty_min_amount
    )
  end
end
