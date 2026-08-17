require "test_helper"

# == Schema Information
#
# Table name: loan_offer_changes
#
#  id            :bigint           not null, primary key
#  changed_at    :datetime         not null
#  note          :string
#  snapshot      :jsonb            not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  loan_offer_id :bigint           not null
#
# Indexes
#
#  index_loan_offer_changes_on_changed_at     (changed_at)
#  index_loan_offer_changes_on_loan_offer_id  (loan_offer_id)
#
# Foreign Keys
#
#  fk_rails_...  (loan_offer_id => loan_offers.id)
#
class LoanOfferChangeTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
