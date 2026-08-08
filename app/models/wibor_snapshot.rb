class WiborSnapshot < ApplicationRecord
	validates :effective_date, :fetched_at, :source_url, presence: true
	validates :wibor_1m, :wibor_3m, numericality: { greater_than: 0 }
	validates :effective_date, uniqueness: true

	scope :recent, -> { order(effective_date: :desc) }

	def self.latest
		recent.first
	end

	def rate_for(kind)
		case kind.to_s
		when "wibor_1m"
			wibor_1m.to_f
		else
			wibor_3m.to_f
		end
	end
end
