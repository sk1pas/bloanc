latest_date = Date.current

WiborSnapshot.find_or_initialize_by(effective_date: latest_date).tap do |snapshot|
	snapshot.fetched_at = Time.current
	snapshot.wibor_1m = 3.84
	snapshot.wibor_3m = 3.83
	snapshot.source_url = "seed"
	snapshot.payload = { "source" => "seeds" }
	snapshot.save!
end

banks_data = [
	{
		title: "mBank",
		description: "Popular digital-first mortgage products."
	},
	{
		title: "Pekao",
		description: "Large traditional bank with diversified mortgage offers."
	},
	{
		title: "ING",
		description: "Mortgage products with low commissions in selected campaigns."
	}
]

banks = banks_data.map do |attrs|
	Bank.find_or_create_by!(title: attrs[:title]) do |bank|
		bank.description = attrs[:description]
	end
end

loan_offers_data = [
	{
		bank_title: "mBank",
		title: "Standard Mortgage",
		url: "https://www.mbank.pl/indywidualny/kredyty/kredyt-hipoteczny/",
		description: "Balanced cost profile with life insurance in first years.",
		rate_type: :variable,
		bank_margin_percent: 1.85,
		wibor_kind: :wibor_3m,
		bank_commission_percent: 0.0,
		life_insurance_percent: 0.05,
		life_insurance_years: 5,
		property_insurance_monthly: 25,
		overpayment_mode: :no_overpayment,
		overpayment_coef: 1.0,
		active: true
	},
	{
		bank_title: "Pekao",
		title: "Promo Mortgage 3Y",
		url: "https://www.pekao.com.pl/klient-indywidualny/kredyty-i-pozyczki/kredyt-hipoteczny.html",
		description: "Overpayment after grace period with x2 coefficient.",
		rate_type: :variable,
		promoted_from: Date.current,
		promoted_until: Date.current + 3.years,
		bank_margin_percent: 1.69,
		wibor_kind: :wibor_3m,
		bank_commission_percent: 0.0,
		life_insurance_total: 8640,
		property_insurance_monthly: 34,
		overpayment_grace_years: 3,
		overpayment_mode: :coef,
		overpayment_coef: 2.0,
		overpayment_penalty_years: 3,
		overpayment_penalty_percent: 5,
		overpayment_penalty_min_amount: 200,
		active: true
	},
	{
		bank_title: "ING",
		title: "Low Start",
		url: "https://www.ing.pl/indywidualni/kredyty-i-pozyczki/kredyt-hipoteczny",
		description: "Low margin and one-time commission.",
		rate_type: :variable,
		bank_margin_percent: 1.7,
		wibor_kind: :wibor_1m,
		bank_commission_percent: 1.5,
		life_insurance_percent: 0.035,
		life_insurance_years: 3,
		property_insurance_monthly: 39,
		overpayment_mode: :absolute,
		overpayment_amount: 1000,
		overpayment_penalty_years: 2,
		overpayment_penalty_percent: 3,
		overpayment_penalty_min_amount: 150,
		active: true
	},
	{
		bank_title: "mBank",
		title: "Fixed 5Y Start",
		url: "https://www.mbank.pl/indywidualny/kredyty/kredyt-hipoteczny/",
		description: "Fixed rate for first 5 years, then margin plus WIBOR.",
		rate_type: :fixed_period,
		fixed_rate_percent: 6.25,
		fixed_rate_years: 5,
		bank_margin_percent: 1.95,
		wibor_kind: :wibor_3m,
		bank_commission_percent: 0.0,
		life_insurance_percent: 0.04,
		life_insurance_years: 5,
		property_insurance_monthly: 27,
		overpayment_mode: :no_overpayment,
		overpayment_coef: 1.0,
		overpayment_penalty_years: 3,
		overpayment_penalty_percent: 3,
		overpayment_penalty_min_amount: 150,
		active: true
	}
]

loan_offers_data.each do |attrs|
	bank = banks.find { |item| item.title == attrs[:bank_title] }
	next if bank.blank?

	LoanOffer.find_or_create_by!(bank: bank, title: attrs[:title]) do |loan_offer|
		loan_offer.assign_attributes(attrs.except(:bank_title, :title))
	end
end
