require "test_helper"

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
class BankTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
