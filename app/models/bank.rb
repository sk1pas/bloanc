class Bank < ApplicationRecord
	has_one_attached :logo

	has_many :loan_offers, dependent: :destroy

	validates :title, presence: true
	validates :website_url,
						format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]) },
						allow_blank: true

	scope :alphabetical, -> { order(:title) }
end
