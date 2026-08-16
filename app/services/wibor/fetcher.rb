require "json"
require "net/http"
require "uri"

module Wibor
  class Fetcher
    class FetchError < StandardError; end

    Result = Struct.new(:snapshot, :status, keyword_init: true) do
      def unchanged?
        status == :unchanged
      end
    end

    LOOKBACK_DAYS = 14
    SOURCE_TEMPLATE = "https://www.mbank.pl/api/libor/libor_date_%<date>s.json".freeze

    def call(reference_date: Date.current)
      data = fetch_latest_data(reference_date: reference_date)
      latest = WiborSnapshot.latest

      if latest && rates_unchanged?(latest, data)
        latest.touch(:fetched_at)
        return Result.new(snapshot: latest, status: :unchanged)
      end

      snapshot = WiborSnapshot.find_or_initialize_by(effective_date: data.fetch(:effective_date))
      status = snapshot.new_record? ? :created : :updated
      snapshot.assign_attributes(
        fetched_at: Time.current,
        wibor_1m: data.fetch(:wibor_1m),
        wibor_3m: data.fetch(:wibor_3m),
        source_url: data.fetch(:source_url),
        payload: data.fetch(:payload)
      )
      snapshot.save!

      Result.new(snapshot: snapshot, status: status)
    end

    private

    def fetch_latest_data(reference_date:)
      0.upto(LOOKBACK_DAYS) do |days_back|
        date = reference_date - days_back
        source_url = format(SOURCE_TEMPLATE, date: date.iso8601)

        payload = fetch_payload(source_url)
        next if payload.blank?

        wibor_item = payload.fetch("items", []).find do |item|
          item["currency"] == "PLN" && item["rate"] == "WIBOR"
        end
        next if wibor_item.blank?

        return {
          effective_date: Date.parse(payload["date"] || date.to_s),
          wibor_1m: wibor_item.fetch("m1"),
          wibor_3m: wibor_item.fetch("m3"),
          source_url: source_url,
          payload: payload
        }
      rescue StandardError => e
        Rails.logger.warn("WIBOR fetch failed for #{source_url}: #{e.class} #{e.message}")
        next
      end

      raise FetchError, "Unable to fetch WIBOR values for the last #{LOOKBACK_DAYS + 1} days"
    end

    def rates_unchanged?(snapshot, data)
      snapshot.wibor_1m.to_d == BigDecimal(data.fetch(:wibor_1m).to_s) &&
        snapshot.wibor_3m.to_d == BigDecimal(data.fetch(:wibor_3m).to_s)
    end

    def fetch_payload(source_url)
      uri = URI.parse(source_url)
      request = Net::HTTP::Get.new(uri)
      request["accept"] = "*/*"
      request["referer"] = "https://www.mbank.pl/serwis-ekonomiczny/miedzybankowe-stopy-procentowe/"
      request["user-agent"] = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36"

      response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https", open_timeout: 5, read_timeout: 10) do |http|
        http.request(request)
      end
      return nil unless response.is_a?(Net::HTTPSuccess)

      JSON.parse(response.body)
    end
  end
end
