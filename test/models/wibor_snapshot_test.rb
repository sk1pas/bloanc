require "test_helper"

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
class WiborSnapshotTest < ActiveSupport::TestCase
  test "latest returns newest effective date" do
    assert_equal wibor_snapshots(:one), WiborSnapshot.latest
  end

  test "previous returns earlier snapshot by effective date" do
    assert_equal wibor_snapshots(:two), wibor_snapshots(:one).previous
    assert_nil wibor_snapshots(:two).previous
  end
end
