# frozen_string_literal: true

# #################################################

# # mBank
# calculate_loan(
#   loan_net: 400_000,
#   months: 120,
#   bank_margin_percent: 1.85,
#   wibor_percent: 3.86,
#   insurance: {
#     life_insurance_percent: 0.05,
#     life_insurance_years: 5,
#     property_insurance_monthly: 25
#   }
# )
# {monthly_principal_interest: 2483,
#  first_month_payment: 2693,
#  life_insurance_total: 11405,
#  total_paid_without_insurance: 744809,
#  total_paid: 759388,
#  bank_earnings: 344809}

# #################################################

# # Pekao
# LoanCalculator.new(
#   loan_net: 400_000,
#   months: 300,
#   bank_margin_percent: 1.69,
#   wibor_percent: 3.78,
#   insurance: {
#     life_insurance_percent: 0.036,
#     life_insurance_years: 5,
#     # life_insurance_total: 8640,
#     property_insurance_monthly: 34
#   },
#   overpayment_grace_years: 3,
#   overpayment_coef: 2.0
# ).call
# {monthly_principal_interest: 2449,
#  first_month_payment: 2483,
#  life_insurance_total: 8640,
#  total_paid_without_insurance: 734757,
#  total_paid: 753397,
#  bank_earnings: 334757}

# #################################################

# # [ING] Mieszkaj po swojemu - Lekka rata
# calculate_loan(
#   loan_net: 400_000,
#   months: 120,
#   bank_margin_percent: 1.70,
#   wibor_percent: 3.78,
#   insurance: {
#     life_insurance_percent: 0.035,
#     life_insurance_years: 3,
#     # life_insurance_total: 4886,
#     property_insurance_monthly: 39
#   },
#   bank_comission_percentage: 1.5
# )
# {monthly_principal_interest: 2452,
#  first_month_payment: 2630,
#  life_insurance_total: 4895,
#  total_paid_without_insurance: 735472,
#  total_paid: 757887,
#  bank_earnings: 335472}

# #################################################

# # [ING] Mieszkaj po swojemu - Latwy start
# calculate_loan(
#   loan_net: 400_000,
#   months: 120,
#   bank_margin_percent: 1.75,
#   wibor_percent: 3.78,
#   insurance: {
#     life_insurance_percent: 0.035,
#     life_insurance_years: 3,
#     # life_insurance_total: 4886,
#     property_insurance_monthly: 39
#   },
#   bank_comission_percentage: 0
# )
# {monthly_principal_interest: 2464,
#  first_month_payment: 2642,
#  life_insurance_total: 4896,
#  total_paid_without_insurance: 739056,
#  total_paid: 755472,
#  bank_earnings: 339056}

# #################################################

# # BNP Paribas
# calculate_loan(
#   loan_net: 400_000,
#   months: 120,
#   bank_margin_percent: 1.65,
#   wibor_percent: 3.84,
#   insurance: {
#     life_insurance_percent: 0.04,
#     life_insurance_years: 3,
#     # life_insurance_total: 6852,
#     property_insurance_monthly: 41
#   },
#   bank_comission_percentage: 0
# )
# {monthly_principal_interest: 2454,
#  first_month_payment: 2655,
#  life_insurance_total: 5594,
#  total_paid_without_insurance: 736189,
#  total_paid: 754045,
#  bank_earnings: 336189}

# #################################################

# # Alior Bank
# calculate_loan(
#   loan_net: 400_000,
#   months: 120,
#   bank_margin_percent: 1.69,
#   wibor_percent: 3.83,
#   insurance: {
#     # life_insurance_percent: 0.04,
#     # life_insurance_years: 3,
#     life_insurance_total: 11_840,
#     property_insurance_monthly: 39
#   },
#   bank_comission_percentage: 0
# )
# {monthly_principal_interest: 2461,
#  first_month_payment: 2500,
#  life_insurance_total: 11840,
#  total_paid_without_insurance: 738339,
#  total_paid: 761761,
#  bank_earnings: 338339}

# #################################################

# # Credit Agricole
# calculate_loan(
#   loan_net: 400_000,
#   months: 120,
#   bank_margin_percent: 1.85,
#   wibor_percent: 3.85,
#   insurance: {
#     life_insurance_percent: 0.0299,
#     life_insurance_years: 10,
#     # life_insurance_total: 6_825,
#     property_insurance_monthly: 38
#   },
#   bank_comission_percentage: 0
# )
# {monthly_principal_interest: 2541,
#  first_month_payment: 2567,
#  life_insurance_total: 27544,
#  total_paid_without_insurance: 762196,
#  total_paid: 797740,
#  bank_earnings: 362196}

class LoanCalculator
  RATE_TYPES = %w[variable fixed_period].freeze
  OVERPAYMENT_MODES = %w[none coef absolute].freeze

  def initialize(loan_net:,
                  months:,
                  rate_type: :variable,
                  fixed_rate_percent: nil,
                  fixed_rate_years: nil,
                  bank_margin_percent:,
                  wibor_percent:,
                  bank_commission_percentage: nil,
                  bank_comission_percentage: nil,
                  insurance: {
                    life_insurance_percent: nil,
                    life_insurance_years: nil,
                    life_insurance_full_term: false,
                    life_insurance_one_time: false,
                    life_insurance_total: nil,
                    property_insurance_monthly: nil
                  },
                  overpayment_grace_years: 0,
                  overpayment_mode: :none,
                  overpayment_coef: 1.0,
                  overpayment_amount: 0,
                  overpayment_penalty_years: 0,
                  overpayment_penalty_percent: 0,
                  overpayment_penalty_min_amount: 0
                 )
    @loan_net = loan_net.to_f
    @months = months.to_i
    @rate_type = normalize_rate_type(rate_type)
    @fixed_rate_percent = fixed_rate_percent.presence&.to_f
    @fixed_rate_years = fixed_rate_years.presence&.to_i
    @bank_margin_percent = bank_margin_percent.to_f
    @wibor_percent = wibor_percent.to_f
    @bank_commission_percentage = bank_commission_percentage.nil? ? bank_comission_percentage.to_f : bank_commission_percentage.to_f

    @life_insurance_percent = insurance[:life_insurance_percent].presence&.to_f
    @life_insurance_years = insurance[:life_insurance_years].presence&.to_i
    @life_insurance_full_term = ActiveModel::Type::Boolean.new.cast(insurance[:life_insurance_full_term])
    @life_insurance_one_time = ActiveModel::Type::Boolean.new.cast(insurance[:life_insurance_one_time])
    @fixed_life_insurance_total = insurance[:life_insurance_total].presence&.to_f
    @property_insurance_monthly = insurance[:property_insurance_monthly].to_f

    @overpayment_grace_years = overpayment_grace_years.to_i
    @overpayment_mode = normalize_overpayment_mode(overpayment_mode)
    @overpayment_coef = overpayment_coef.to_f
    @overpayment_amount = overpayment_amount.to_f
    @overpayment_penalty_years = overpayment_penalty_years.to_i
    @overpayment_penalty_percent = overpayment_penalty_percent.to_f
    @overpayment_penalty_min_amount = overpayment_penalty_min_amount.to_f
  end

  def call
    fixed_months = fixed_period_months
    starts_with_fixed_rate = fixed_months.positive?
    switches_to_variable_rate = starts_with_fixed_rate && fixed_months < @months

    variable_monthly_rate = ((@bank_margin_percent + @wibor_percent) / 100.0) / 12.0
    fixed_monthly_rate = (@fixed_rate_percent.to_f / 100.0) / 12.0

    phase_monthly_rate = starts_with_fixed_rate ? fixed_monthly_rate : variable_monthly_rate
    scheduled_payment = annuity_payment(
      principal: @loan_net,
      monthly_rate: phase_monthly_rate,
      months_remaining: @months
    )
    first_month_scheduled_payment = scheduled_payment
    post_fixed_monthly_payment = nil

    remaining_balance = @loan_net

    total_interest = 0.0
    total_principal_interest_paid = 0.0
    total_overpayment_penalty = 0.0
    one_time_life_insurance_total = one_time_life_insurance_from_percent
    life_insurance_total = one_time_life_insurance_total || @fixed_life_insurance_total || 0.0

    insurance_months = life_insurance_months

    overpayment_start_month = @overpayment_grace_years.to_i * 12
    overpayment_penalty_months = @overpayment_penalty_years.to_i * 12

    first_month_extra_payment = additional_overpayment(month_index: 0, scheduled_payment: first_month_scheduled_payment,
                                                       overpayment_start_month: overpayment_start_month)
    first_month_overpayment_penalty =
      if first_month_extra_payment.positive? && overpayment_penalty_months.positive?
        overpayment_penalty_for(first_month_extra_payment)
      else
        0.0
      end

    months_paid = 0

    @months.times do |month_index|
      break if remaining_balance <= 0

      if switches_to_variable_rate && month_index == fixed_months
        phase_monthly_rate = variable_monthly_rate
        scheduled_payment = annuity_payment(
          principal: remaining_balance,
          monthly_rate: phase_monthly_rate,
          months_remaining: @months - month_index
        )
        post_fixed_monthly_payment = scheduled_payment
      end

      interest_part = remaining_balance * phase_monthly_rate
      actual_monthly_payment = scheduled_payment

      additional_payment =
        additional_overpayment(
          month_index: month_index,
          scheduled_payment: scheduled_payment,
          overpayment_start_month: overpayment_start_month
        )
      actual_monthly_payment += additional_payment

      if additional_payment.positive? && month_index < overpayment_penalty_months
        total_overpayment_penalty += overpayment_penalty_for(additional_payment)
      end

      actual_principal_part = actual_monthly_payment - interest_part

      if actual_principal_part >= remaining_balance
        actual_principal_part = remaining_balance
        actual_monthly_payment = interest_part + actual_principal_part
      end

      if one_time_life_insurance_total.nil? && @fixed_life_insurance_total.nil? && @life_insurance_percent && insurance_months.to_i.positive? && month_index < insurance_months
        monthly_life_insurance = remaining_balance * (@life_insurance_percent / 100.0)
        life_insurance_total += monthly_life_insurance
      end

      remaining_balance -= actual_principal_part
      total_interest += interest_part
      total_principal_interest_paid += actual_monthly_payment
      months_paid += 1
    end

    bank_commission_total = @loan_net * (@bank_commission_percentage / 100.0)
    property_insurance_total = @property_insurance_monthly.to_f * (months_paid > 0 ? months_paid : @months)
    total_paid_with_insurance =
      total_principal_interest_paid +
      life_insurance_total +
      property_insurance_total +
      bank_commission_total +
      total_overpayment_penalty

    first_month_life_insurance =
      if one_time_life_insurance_total || @fixed_life_insurance_total || !(@life_insurance_percent && insurance_months.to_i.positive?)
        0.0
      else
        @loan_net * (@life_insurance_percent / 100.0)
      end

    notes = []
    if starts_with_fixed_rate
      if switches_to_variable_rate
        notes << "Rate base: fixed #{@fixed_rate_percent.round(3)}% for #{@fixed_rate_years} years, then margin #{@bank_margin_percent.round(3)}% + WIBOR #{@wibor_percent.round(3)}%"
      else
        notes << "Rate base: fixed #{@fixed_rate_percent.round(3)}% for full repayment period"
      end
    else
      notes << "Rate base: margin #{@bank_margin_percent.round(3)}% + WIBOR #{@wibor_percent.round(3)}%"
    end
    notes << "Bank commission: #{@bank_commission_percentage.round(3)}% of net loan" if @bank_commission_percentage.positive?
    if one_time_life_insurance_total
      notes << "Life insurance as one-time #{@life_insurance_percent.round(4)}% of loan amount"
    elsif @fixed_life_insurance_total
      notes << "Life insurance as one-time total amount"
    elsif @life_insurance_percent && insurance_months.to_i.positive?
      notes << if @life_insurance_full_term
        "Life insurance is monthly on remaining principal for the full loan term"
      else
        "Life insurance is monthly on remaining principal for #{@life_insurance_years} years"
      end
    end
    notes << "Property insurance fixed monthly amount until full repayment"

    if @overpayment_mode != "none"
      notes << "Overpayment starts after #{@overpayment_grace_years} years"
      notes << "Overpayment mode: x#{@overpayment_coef.round(3)}" if @overpayment_mode == "coef"
      notes << "Overpayment mode: +#{@overpayment_amount.round(2)} PLN monthly" if @overpayment_mode == "absolute"
      if @overpayment_penalty_years.positive?
        notes << "Overpayment fee during first #{@overpayment_penalty_years} years: #{@overpayment_penalty_percent.round(3)}% (min #{@overpayment_penalty_min_amount.round(2)} PLN)"
      end
    end

    {
      monthly_principal_interest: first_month_scheduled_payment.round,
      monthly_principal_interest_after_fixed: post_fixed_monthly_payment&.round,
      first_month_payment: (
        first_month_scheduled_payment +
        first_month_life_insurance +
        @property_insurance_monthly.to_f +
        first_month_extra_payment +
        first_month_overpayment_penalty
      ).round,
      life_insurance_total: life_insurance_total.round,
      property_insurance_total: property_insurance_total.round,
      bank_commission_total: bank_commission_total.round,
      overpayment_penalty_total: total_overpayment_penalty.round,
      total_paid: total_paid_with_insurance.round,
      total_cost: (total_paid_with_insurance - @loan_net).round,
      bank_interest_total: total_interest.round,
      bank_earnings: total_interest.round,
      months_paid: months_paid,
      notes: notes
    }
  end

  private

  def normalize_rate_type(rate_type)
    normalized = rate_type.to_s
    return normalized if RATE_TYPES.include?(normalized)

    "variable"
  end

  def normalize_overpayment_mode(mode)
    normalized = mode.to_s
    return "none" if normalized == "no_overpayment"
    return normalized if OVERPAYMENT_MODES.include?(normalized)

    "none"
  end

  def fixed_period_months
    return 0 unless @rate_type == "fixed_period"
    return 0 unless @fixed_rate_percent.to_f.positive?
    return 0 unless @fixed_rate_years.to_i.positive?

    [@fixed_rate_years * 12, @months].min
  end

  def one_time_life_insurance_from_percent
    return nil unless @life_insurance_one_time
    return nil unless @life_insurance_percent

    @loan_net * (@life_insurance_percent / 100.0)
  end

  def life_insurance_months
    return nil if @life_insurance_one_time
    return nil unless @life_insurance_percent
    return @months if @life_insurance_full_term
    return nil unless @life_insurance_years.to_i.positive?

    @life_insurance_years * 12
  end

  def annuity_payment(principal:, monthly_rate:, months_remaining:)
    return 0.0 if months_remaining.to_i <= 0

    if monthly_rate.zero?
      principal.to_f / months_remaining
    else
      factor = (1 + monthly_rate)**months_remaining
      (principal.to_f * monthly_rate * factor) / (factor - 1)
    end
  end

  def additional_overpayment(month_index:, scheduled_payment:, overpayment_start_month:)
    return 0.0 if month_index < overpayment_start_month

    case @overpayment_mode
    when "coef"
      [(scheduled_payment * (@overpayment_coef - 1.0)), 0.0].max
    when "absolute"
      [@overpayment_amount, 0.0].max
    else
      0.0
    end
  end

  def overpayment_penalty_for(additional_payment)
    return 0.0 if additional_payment <= 0
    return 0.0 if @overpayment_penalty_percent <= 0 && @overpayment_penalty_min_amount <= 0

    percent_fee = additional_payment * (@overpayment_penalty_percent / 100.0)
    [percent_fee, @overpayment_penalty_min_amount].max
  end
end
