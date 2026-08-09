require "test_helper"

class LoanCalculatorTest < ActiveSupport::TestCase
  test "returns expected result keys" do
    result = LoanCalculator.new(
      loan_net: 400_000,
      months: 300,
      bank_margin_percent: 1.8,
      wibor_percent: 3.8,
      bank_commission_percentage: 0,
      insurance: {
        life_insurance_percent: 0.04,
        life_insurance_years: 3,
        property_insurance_monthly: 30
      }
    ).call

    assert result[:monthly_principal_interest].positive?
    assert result[:total_paid].positive?
    assert result[:bank_interest_total].positive?
    assert result[:months_paid].positive?
    assert_kind_of Array, result[:notes]
  end

  test "absolute overpayment shortens repayment period" do
    baseline = LoanCalculator.new(
      loan_net: 400_000,
      months: 300,
      bank_margin_percent: 1.8,
      wibor_percent: 3.8,
      insurance: {
        property_insurance_monthly: 0
      }
    ).call

    accelerated = LoanCalculator.new(
      loan_net: 400_000,
      months: 300,
      bank_margin_percent: 1.8,
      wibor_percent: 3.8,
      insurance: {
        property_insurance_monthly: 0
      },
      overpayment_mode: :absolute,
      overpayment_amount: 1500,
      overpayment_penalty_years: 2,
      overpayment_penalty_percent: 5,
      overpayment_penalty_min_amount: 200
    ).call

    assert_operator accelerated[:months_paid], :<, baseline[:months_paid]
    assert_operator accelerated[:overpayment_penalty_total], :>, 0
  end

  test "fixed life insurance total overrides monthly percent calculation" do
    fixed = LoanCalculator.new(
      loan_net: 300_000,
      months: 240,
      bank_margin_percent: 1.6,
      wibor_percent: 3.7,
      insurance: {
        life_insurance_total: 9000,
        property_insurance_monthly: 20
      }
    ).call

    assert_equal 9000, fixed[:life_insurance_total]
    assert_equal fixed[:monthly_principal_interest] + 20, fixed[:first_month_payment]
  end
end
