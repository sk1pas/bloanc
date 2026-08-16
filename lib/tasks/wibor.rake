# frozen_string_literal: true

namespace :wibor do
  desc "Refresh WIBOR rates from mBank. Touches the latest snapshot when rates are unchanged."
  task refresh: :environment do
    result = Wibor::Fetcher.new.call
    snapshot = result.snapshot

    case result.status
    when :unchanged
      puts "WIBOR unchanged (1M=#{snapshot.wibor_1m}%, 3M=#{snapshot.wibor_3m}%). Touched fetched_at=#{snapshot.fetched_at}."
    when :created
      puts "WIBOR created for #{snapshot.effective_date}: 1M=#{snapshot.wibor_1m}%, 3M=#{snapshot.wibor_3m}%."
    when :updated
      puts "WIBOR updated for #{snapshot.effective_date}: 1M=#{snapshot.wibor_1m}%, 3M=#{snapshot.wibor_3m}%."
    end
  rescue Wibor::Fetcher::FetchError => e
    warn "WIBOR refresh failed: #{e.message}"
    exit 1
  end
end
