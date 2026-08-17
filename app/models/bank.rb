# == Schema Information
#
# Table name: banks
#
#  id          :bigint           not null, primary key
#  description :text
#  title       :string           not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
# Indexes
#
#  index_banks_on_title  (title)
#
class Bank < ApplicationRecord
  has_one_attached :logo

  has_many :loan_offers, dependent: :destroy

  validates :title, presence: true

  scope :alphabetical, -> { order(:title) }
end
