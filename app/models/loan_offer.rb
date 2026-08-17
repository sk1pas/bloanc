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
class LoanOffer < ApplicationRecord
  belongs_to :bank

  has_many :loan_offer_changes, dependent: :destroy

  enum :rate_type, { variable: 0, fixed_period: 1 }, default: :variable, validate: true
  enum :wibor_kind, { wibor_1m: 0, wibor_3m: 1 }, default: :wibor_3m, validate: true
  enum :overpayment_mode, { no_overpayment: 0, coef: 1, absolute: 2 }, default: :no_overpayment, validate: true

  validates :title, length: { maximum: 255 }, allow_blank: true
  validates :url,
            format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]) },
            allow_blank: true
  validates :bank_margin_percent, numericality: { greater_than_or_equal_to: 0 }
  validates :fixed_rate_percent, numericality: { greater_than: 0 }, allow_nil: true
  validates :fixed_rate_years, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true
  validates :bank_commission_percent, numericality: { greater_than_or_equal_to: 0 }
  validates :life_insurance_percent, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :life_insurance_years, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
  validates :life_insurance_total, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :property_insurance_monthly, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :overpayment_grace_years, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :overpayment_coef, numericality: { greater_than_or_equal_to: 1 }
  validates :overpayment_amount, numericality: { greater_than_or_equal_to: 0 }
  validates :overpayment_penalty_years, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :overpayment_penalty_percent, numericality: { greater_than_or_equal_to: 0 }
  validates :overpayment_penalty_min_amount, numericality: { greater_than_or_equal_to: 0 }

  validates :promoted_until,
            comparison: { greater_than_or_equal_to: :promoted_from },
            allow_nil: true,
            if: -> { promoted_from.present? }
  validate :fixed_rate_configuration
  before_validation :normalize_optional_fields

  scope :active, -> { where(active: true) }
  scope :ordered, -> { joins(:bank).order("banks.title ASC, loan_offers.title ASC NULLS LAST") }

  def current_wibor_percent(snapshot = WiborSnapshot.latest)
    return 0 if snapshot.blank?

    snapshot.rate_for(wibor_kind)
  end

  def variable_rate_percent(snapshot = WiborSnapshot.latest)
    bank_margin_percent.to_f + current_wibor_percent(snapshot).to_f
  end

  def initial_rate_percent(snapshot = WiborSnapshot.latest)
    return fixed_rate_percent.to_f if fixed_period? && fixed_rate_percent.present?

    variable_rate_percent(snapshot)
  end

  def calculator_params(loan_net:, months:, wibor_snapshot: WiborSnapshot.latest)
    {
      loan_net: loan_net,
      months: months,
      rate_type: rate_type,
      fixed_rate_percent: fixed_rate_percent,
      fixed_rate_years: fixed_rate_years,
      bank_margin_percent: bank_margin_percent.to_f,
      wibor_percent: current_wibor_percent(wibor_snapshot),
      bank_commission_percentage: bank_commission_percent.to_f,
      insurance: {
        life_insurance_percent: life_insurance_percent,
        life_insurance_years: life_insurance_years,
        life_insurance_full_term: life_insurance_full_term?,
        life_insurance_one_time: life_insurance_one_time?,
        life_insurance_total: life_insurance_total,
        property_insurance_monthly: property_insurance_monthly
      },
      overpayment_grace_years: overpayment_grace_years,
      overpayment_mode: overpayment_mode,
      overpayment_coef: overpayment_coef,
      overpayment_amount: overpayment_amount,
      overpayment_penalty_years: overpayment_penalty_years,
      overpayment_penalty_percent: overpayment_penalty_percent,
      overpayment_penalty_min_amount: overpayment_penalty_min_amount
    }
  end

  def snapshot_payload
    attributes.slice(
      "title",
      "url",
      "description",
      "promoted_from",
      "promoted_until",
      "rate_type",
      "fixed_rate_percent",
      "fixed_rate_years",
      "bank_margin_percent",
      "wibor_kind",
      "bank_commission_percent",
      "life_insurance_percent",
      "life_insurance_years",
      "life_insurance_full_term",
      "life_insurance_one_time",
      "life_insurance_total",
      "property_insurance_monthly",
      "overpayment_grace_years",
      "overpayment_mode",
      "overpayment_coef",
      "overpayment_amount",
      "overpayment_penalty_years",
      "overpayment_penalty_percent",
      "overpayment_penalty_min_amount",
      "active"
    )
  end

  def life_insurance_unknown?
    life_insurance_total.nil? && life_insurance_percent.nil? && life_insurance_years.nil? && !life_insurance_full_term?
  end

  def one_time_life_insurance_percent?
    life_insurance_one_time? && life_insurance_percent.present?
  end

  def one_time_life_insurance_amount_for(loan_amount)
    return nil unless one_time_life_insurance_percent?

    loan_amount.to_f * (life_insurance_percent.to_f / 100.0)
  end

  def monthly_life_insurance?
    return false if life_insurance_one_time?

    life_insurance_percent.present? && (life_insurance_full_term? || life_insurance_years.to_i.positive?)
  end

  def life_insurance_months_for(loan_months)
    return loan_months.to_i if life_insurance_full_term?

    [life_insurance_years.to_i * 12, loan_months.to_i].min
  end

  def property_insurance_unknown?
    property_insurance_monthly.nil?
  end

  private

  def normalize_optional_fields
    self.title = title.to_s.strip.presence
    self.url = url.to_s.strip.presence

    %i[
      life_insurance_percent
      life_insurance_years
      life_insurance_total
      property_insurance_monthly
    ].each do |attribute|
      self[attribute] = nil if self[attribute].blank?
    end
  end

  def fixed_rate_configuration
    return unless fixed_period?

    errors.add(:fixed_rate_percent, :blank) if fixed_rate_percent.blank?
    errors.add(:fixed_rate_years, :blank) if fixed_rate_years.blank?
  end
end
