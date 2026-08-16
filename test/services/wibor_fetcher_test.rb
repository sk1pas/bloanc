require "test_helper"

class WiborFetcherTest < ActiveSupport::TestCase
  setup do
    WiborSnapshot.delete_all
  end

  test "creates a snapshot when none exist" do
    result = fetch_with_rates(wibor_1m: "3.90", wibor_3m: "3.85", effective_date: "2026-08-16")

    assert_equal :created, result.status
    assert_equal Date.new(2026, 8, 16), result.snapshot.effective_date
    assert_equal BigDecimal("3.90"), result.snapshot.wibor_1m
    assert_equal BigDecimal("3.85"), result.snapshot.wibor_3m
    assert_equal 1, WiborSnapshot.count
  end

  test "touches latest snapshot when rates are unchanged" do
    existing = WiborSnapshot.create!(
      effective_date: Date.new(2026, 8, 15),
      fetched_at: 2.hours.ago,
      wibor_1m: 3.90,
      wibor_3m: 3.85,
      source_url: "https://example.com/old",
      payload: { source: "old" }
    )
    previous_fetched_at = existing.fetched_at

    travel 1.hour do
      result = fetch_with_rates(wibor_1m: "3.90", wibor_3m: "3.85", effective_date: "2026-08-16")

      assert_equal :unchanged, result.status
      assert_equal existing.id, result.snapshot.id
      assert_equal 1, WiborSnapshot.count
      assert_operator result.snapshot.fetched_at, :>, previous_fetched_at
      assert_equal Date.new(2026, 8, 15), result.snapshot.effective_date
    end
  end

  test "creates a new snapshot when rates change" do
    WiborSnapshot.create!(
      effective_date: Date.new(2026, 8, 15),
      fetched_at: 2.hours.ago,
      wibor_1m: 3.90,
      wibor_3m: 3.85,
      source_url: "https://example.com/old",
      payload: { source: "old" }
    )

    result = fetch_with_rates(wibor_1m: "3.91", wibor_3m: "3.86", effective_date: "2026-08-16")

    assert_equal :created, result.status
    assert_equal 2, WiborSnapshot.count
    assert_equal BigDecimal("3.91"), result.snapshot.wibor_1m
    assert_equal BigDecimal("3.86"), result.snapshot.wibor_3m
  end

  test "updates existing effective_date when rates change for that date" do
    existing = WiborSnapshot.create!(
      effective_date: Date.new(2026, 8, 16),
      fetched_at: 2.hours.ago,
      wibor_1m: 3.90,
      wibor_3m: 3.85,
      source_url: "https://example.com/old",
      payload: { source: "old" }
    )

    result = fetch_with_rates(wibor_1m: "3.95", wibor_3m: "3.88", effective_date: "2026-08-16")

    assert_equal :updated, result.status
    assert_equal existing.id, result.snapshot.id
    assert_equal 1, WiborSnapshot.count
    assert_equal BigDecimal("3.95"), result.snapshot.reload.wibor_1m
  end

  private

  def fetch_with_rates(wibor_1m:, wibor_3m:, effective_date:)
    payload = {
      "date" => effective_date,
      "items" => [
        { "currency" => "PLN", "rate" => "WIBOR", "m1" => wibor_1m, "m3" => wibor_3m }
      ]
    }

    fetcher = Wibor::Fetcher.new
    fetcher.define_singleton_method(:fetch_payload) { |_| payload }
    fetcher.call(reference_date: Date.parse(effective_date))
  end
end
