module ApplicationHelper
	LOCALE_COUNTRY_CODES = {
		"pl" => "PL",
		"en" => "GB",
		"ua" => "UA"
	}.freeze

	HREFLANG_CODES = {
		"pl" => "pl",
		"en" => "en",
		"ua" => "uk"
	}.freeze

	def locale_switch_label(locale)
		locale_code = locale.to_s
		country_code = LOCALE_COUNTRY_CODES[locale_code] || locale_code.upcase

		"#{country_flag_emoji(country_code)} #{locale_code.upcase}"
	end

	def hreflang_for(locale)
		HREFLANG_CODES.fetch(locale.to_s, locale.to_s)
	end

	private

	def country_flag_emoji(country_code)
		country_code.to_s.upcase.chars.map { |char| (127_397 + char.ord).chr(Encoding::UTF_8) }.join
	end
end
