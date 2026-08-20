# == Schema Information
#
# Table name: wibor_snapshots
#
#  id             :bigint           not null, primary key
#  effective_date :date             not null
#  fetched_at     :datetime         not null
#  payload        :jsonb            not null
#  source_url     :string           not null
#  wibor_1m       :decimal(6, 3)    not null
#  wibor_3m       :decimal(6, 3)    not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#
# Indexes
#
#  index_wibor_snapshots_on_effective_date  (effective_date) UNIQUE
#
class WiborSnapshot < ApplicationRecord
	validates :effective_date, :fetched_at, :source_url, presence: true
	validates :wibor_1m, :wibor_3m, numericality: { greater_than: 0 }
	validates :effective_date, uniqueness: true

	scope :recent, -> { order(effective_date: :desc) }

	def self.latest
		recent.first
	end

	def previous
		self.class.where("effective_date < ?", effective_date).order(effective_date: :desc).first
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
