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
    life_insurance_total.nil? && life_insurance_percent.nil? && life_insurance_years.nil?
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
