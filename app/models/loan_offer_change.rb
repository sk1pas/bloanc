class LoanOfferChange < ApplicationRecord
  belongs_to :loan_offer

  validates :changed_at, :snapshot, presence: true

  scope :recent, -> { order(changed_at: :desc) }

  before_validation :set_changed_at

  private

  def set_changed_at
    self.changed_at ||= Time.current
  end
end
