require "test_helper"

# == Schema Information
#
# Table name: loan_offers
#
#  id                             :bigint           not null, primary key
#  active                         :boolean          default(TRUE), not null
#  bank_commission_percent        :decimal(6, 3)    default(0.0), not null
#  bank_margin_percent            :decimal(6, 3)    not null
#  description                    :text
#  fixed_rate_percent             :decimal(6, 3)
#  fixed_rate_years               :integer
#  life_insurance_full_term       :boolean          default(FALSE), not null
#  life_insurance_one_time        :boolean          default(FALSE), not null
#  life_insurance_percent         :decimal(8, 4)
#  life_insurance_total           :decimal(12, 2)
#  life_insurance_years           :integer
#  overpayment_amount             :decimal(12, 2)   default(0.0), not null
#  overpayment_coef               :decimal(8, 3)    default(1.0), not null
#  overpayment_grace_years        :integer          default(0), not null
#  overpayment_mode               :integer          default(0), not null
#  overpayment_penalty_min_amount :decimal(12, 2)   default(0.0), not null
#  overpayment_penalty_percent    :decimal(6, 3)    default(0.0), not null
#  overpayment_penalty_years      :integer          default(0), not null
#  promoted_from                  :date
#  promoted_until                 :date
#  property_insurance_monthly     :decimal(12, 2)
#  rate_type                      :integer          default(0), not null
#  title                          :string
#  url                            :string
#  wibor_kind                     :integer          default(1), not null
#  created_at                     :datetime         not null
#  updated_at                     :datetime         not null
#  bank_id                        :bigint           not null
#
# Indexes
#
#  index_loan_offers_on_active     (active)
#  index_loan_offers_on_bank_id    (bank_id)
#  index_loan_offers_on_rate_type  (rate_type)
#
# Foreign Keys
#
#  fk_rails_...  (bank_id => banks.id)
#
class LoanOfferTest < ActiveSupport::TestCase
  test "monthly life insurance covers whole loan period when full term is set" do
    offer = loan_offers(:one)
    offer.update!(
      life_insurance_percent: 0.04,
      life_insurance_years: nil,
      life_insurance_total: nil,
      life_insurance_full_term: true
    )

    assert offer.monthly_life_insurance?
    assert_equal 300, offer.life_insurance_months_for(300)
    refute offer.life_insurance_unknown?
  end

  test "one-time life insurance percent is not treated as monthly" do
    offer = loan_offers(:one)
    offer.update!(
      life_insurance_percent: 1.5,
      life_insurance_years: 5,
      life_insurance_total: nil,
      life_insurance_full_term: false,
      life_insurance_one_time: true
    )

    assert offer.one_time_life_insurance_percent?
    refute offer.monthly_life_insurance?
    refute offer.life_insurance_unknown?
    assert_equal 6_000, offer.one_time_life_insurance_amount_for(400_000)
  end
end
