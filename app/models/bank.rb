class Bank < ApplicationRecord
  has_one_attached :logo

  has_many :loan_offers, dependent: :destroy

  validates :title, presence: true

  scope :alphabetical, -> { order(:title) }
end
