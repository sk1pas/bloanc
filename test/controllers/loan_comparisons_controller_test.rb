require "test_helper"

class LoanComparisonsControllerTest < ActionDispatch::IntegrationTest
  test "renders site root without redirect using pl locale and variable rate" do
    get "/"

    assert_response :success
    assert_includes response.body, "Porównaj oferty kredytów hipotecznych"
    assert_includes response.body, 'rel="canonical" href="http://www.example.com/"'
    assert_includes response.body, "/oprocentowanie-zmienne"
  end

  test "renders locale root without redirecting to rate type slug" do
    get root_path(locale: :pl)

    assert_response :success
    assert_includes response.body, "Porównaj oferty kredytów hipotecznych"
    assert_includes response.body, 'rel="canonical" href="http://www.example.com/"'
    assert_includes response.body, "/pl/oprocentowanie-zmienne"
  end

  test "renders polish rate type slug without locale prefix" do
    get loan_comparison_path(locale: nil, rate_type_slug: "oprocentowanie-zmienne")

    assert_response :success
    assert_includes response.body, 'rel="canonical" href="http://www.example.com/oprocentowanie-zmienne"'
    assert_includes response.body, "/oprocentowanie-stale"
  end

  test "variable rate slug with locale canonicalizes to slug without locale prefix" do
    get loan_comparison_path(locale: :pl, rate_type_slug: "oprocentowanie-zmienne")

    assert_response :success
    assert_includes response.body, 'rel="canonical" href="http://www.example.com/oprocentowanie-zmienne"'
  end

  test "renders public comparison page" do
    get loan_comparison_path(locale: :pl, rate_type_slug: "oprocentowanie-zmienne")

    assert_response :success
    assert_includes response.body, "Porównaj oferty kredytów hipotecznych"
    assert_includes response.body, "Okres kredytu (lata)"
    refute_includes response.body, "Wyniki aktualizuja sie automatycznie po zmianie pola."
    refute_includes response.body, "Zalozenia ogolne"
    refute_includes response.body, "submitNow"
    assert_match(/<th>\s*Oprocentowanie zmienne\s*<\/th>/, response.body)
    assert_includes response.body, "Oferta banku"
    assert_includes response.body, "Oprocentowanie zmienne"
    assert_includes response.body, "Oprocentowanie stałe"
    assert_includes response.body, "Docelowa łączna rata miesięczna (PLN)"
    assert_includes response.body, "Nadpłacaj w okresie opłaty"
    assert_includes response.body, "data-controller=\"cookie-consent\""
    assert_includes response.body, "Akceptuj wszystkie"
    refute_includes response.body, "Panel admina"
    refute_includes response.body, admin_root_path
    assert_includes response.body, "/pl/oprocentowanie-zmienne"
    assert_includes response.body, "/pl/oprocentowanie-stale"
    assert_includes response.body, "/en/variable-rate"
    assert_includes response.body, "/ua/zminna-stavka"
    assert_includes response.body, 'hreflang="uk"'
    refute_includes response.body, 'hreflang="ua"'
    assert_includes response.body, "locale-switch-select"
    assert_includes response.body, "🇵🇱"
    assert_includes response.body, 'role="tab"'
    assert_includes response.body, 'aria-selected="true"'
    assert_includes response.body, 'width="73"'
    assert_includes response.body, 'height="40"'
    assert_includes response.body, 'for="loan_amount_range"'
    assert_includes response.body, 'for="years_range"'
    assert_includes response.body, "cdn.jsdelivr.net/npm/bootstrap"
    assert_includes response.body, "Rata miesięczna to zwykle suma tych części"
    assert_includes response.body, "Ubezpieczenie życia"
    assert_includes response.body, 'data-controller="details-cookie"'
    refute_includes response.body, "total-paid-row--fee"
    refute_includes response.body, "offer-incomplete"
    assert_select "details.payment-parts[open]"
    assert_select "details.payment-parts summary.payment-parts__summary"
    assert_select "section.wibor-snapshot"
    assert_includes response.body, "Data WIBOR"
    assert_includes response.body, "WIBOR 1M"
    assert_includes response.body, "WIBOR 3M"
    assert_includes response.body, "wibor-change--up"
    assert_includes response.body, "(+0.02)"
    assert_select ".results-rate-switcher__copy"
    refute_includes response.body, "Opłata za nadpłatę"
  end

  test "hides overpayment fee row when fee total is zero" do
    get loan_comparison_path(locale: :pl, rate_type_slug: "oprocentowanie-zmienne"), params: {
      loan_amount: 400_000,
      years: 25,
      overpayment_mode: "fixed_monthly",
      fixed_monthly_payment: 9_000,
      fixed_monthly_overpay_during_penalty: "0"
    }

    assert_response :success
    refute_includes response.body, "total-paid-row--fee"
    refute_includes response.body, "Opłata za nadpłatę"
  end

  test "shows wibor change arrows against previous snapshot" do
    get loan_comparison_path(locale: :pl, rate_type_slug: "oprocentowanie-zmienne")

    assert_response :success
    assert_select ".wibor-change--up", count: 2
    assert_includes response.body, I18n.l(wibor_snapshots(:one).effective_date)
    refute_includes response.body, "Latest WIBOR snapshot:"
  end

  test "omits wibor change marker when rate is unchanged" do
    previous = wibor_snapshots(:two)
    previous.update!(wibor_1m: 3.84, wibor_3m: 3.83)

    get loan_comparison_path(locale: :pl, rate_type_slug: "oprocentowanie-zmienne")

    assert_response :success
    refute_includes response.body, "wibor-change"
  end

  test "filters offers by fixed-period rate type" do
    get loan_comparison_path(locale: :pl, rate_type_slug: "oprocentowanie-stale"), params: {
      loan_amount: 400_000,
      years: 25
    }

    assert_response :success
    assert_includes response.body, "Offer Two"
    refute_includes response.body, "Offer One"
    assert_match(/<th>\s*Oprocentowanie stałe\s*<\/th>/, response.body)
    assert_includes response.body, "Oprocentowanie stałe"
    assert_includes response.body, "/pl/oprocentowanie-stale"
  end

  test "shows empty-state message when selected type has no offers" do
    LoanOffer.update_all(rate_type: LoanOffer.rate_types[:variable])

    get loan_comparison_path(locale: :pl, rate_type_slug: "oprocentowanie-stale"), params: {
      loan_amount: 400_000,
      years: 25
    }

    assert_response :success
    assert_includes response.body, "Brak ofert dla typu"
  end

  test "defaults to no user overpayment note" do
    get loan_comparison_path(locale: :pl, rate_type_slug: "oprocentowanie-zmienne"), params: {
      loan_amount: 400_000,
      years: 25
    }

    assert_response :success
    refute_includes response.body, "Nadpłata użytkownika nie jest stosowana."
  end

  test "renders offer title as external link without printing url text" do
    get loan_comparison_path(locale: :pl, rate_type_slug: "oprocentowanie-zmienne")

    assert_response :success
    assert_includes response.body, 'href="https://offer-one.test"'
    assert_includes response.body, 'rel="noopener noreferrer nofollow"'
    assert_includes response.body, "Offer One"
    assert_includes response.body, "Aktualizacja:"
    assert_includes response.body, "Dane o kredytach na tej stronie pochodzą z publicznie dostępnych materiałów banków"
    assert_includes response.body, "wCredit.pl nie ponosi odpowiedzialności"
    refute_includes response.body, ">https://offer-one.test<"
  end

  test "shows validation note for fixed monthly mode when payment is too low" do
    get loan_comparison_path(locale: :pl, rate_type_slug: "oprocentowanie-zmienne"), params: {
      loan_amount: 400_000,
      years: 25,
      overpayment_mode: "fixed_monthly",
      fixed_monthly_payment: 1
    }

    assert_response :success
    assert_includes response.body, "Rata stała musi być wyższa od raty standardowej"
  end

  test "applies fixed target period simulation" do
    get loan_comparison_path(locale: :pl, rate_type_slug: "oprocentowanie-zmienne"), params: {
      loan_amount: 400_000,
      years: 25,
      overpayment_mode: "fixed_period",
      target_years: 15
    }

    assert_response :success
    assert_includes response.body, "Tryb docelowego okresu aktywny:"
    assert_includes response.body, "15 lat, szacowana rata"
  end

  test "does not apply penalty when fixed monthly overpayment starts after penalty period" do
    get loan_comparison_path(locale: :pl, rate_type_slug: "oprocentowanie-zmienne"), params: {
      loan_amount: 400_000,
      years: 25,
      overpayment_mode: "fixed_monthly",
      fixed_monthly_payment: 9_000,
      fixed_monthly_overpay_during_penalty: "0"
    }

    assert_response :success
    refute_includes response.body, "Opłata za nadpłatę:"
  end

  test "collapses payment parts when cookie is closed" do
    get loan_comparison_path(locale: :pl, rate_type_slug: "oprocentowanie-zmienne"),
        headers: { "HTTP_COOKIE" => "payment_parts_open=0" }

    assert_response :success
    assert_select "details.payment-parts:not([open])"
  end

  test "highlights overpayment fee in results breakdown" do
    get loan_comparison_path(locale: :pl, rate_type_slug: "oprocentowanie-zmienne"), params: {
      loan_amount: 400_000,
      years: 25,
      overpayment_mode: "fixed_monthly",
      fixed_monthly_payment: 9_000
    }

    assert_response :success
    assert_includes response.body, "Opłata za nadpłatę"
    assert_includes response.body, "total-paid-row--fee"
  end

  test "renders loan period sort option" do
    get loan_comparison_path(locale: :pl, rate_type_slug: "oprocentowanie-zmienne")

    assert_response :success
    assert_includes response.body, 'value="loan-period"'
    assert_includes response.body, "type=\"radio\""
    assert_includes response.body, "Rata kredytowa"
    assert_includes response.body, "Rata w pierwszym miesiącu"
    assert_includes response.body, "Kwota kredytu"
    assert_includes response.body, "Odsetki banku"
    assert_includes response.body, "Jednorazowy pakiet poza kolumną raty pierwszego miesiąca"
    assert_includes response.body, "miesięcznie przez"
    assert_includes response.body, "wkład własny wynosi więcej niż 20%"
    refute_includes response.body, "Niestandardowa oferta"
    assert_includes response.body, "wCredit.pl"
  end

  test "highlights unknown insurance values in total repayment breakdown" do
    offer = loan_offers(:one)
    offer.update!(
      life_insurance_percent: nil,
      life_insurance_years: nil,
      life_insurance_total: nil,
      life_insurance_full_term: false,
      life_insurance_one_time: false,
      property_insurance_monthly: nil
    )

    get loan_comparison_path(locale: :pl, rate_type_slug: "oprocentowanie-zmienne")

    assert_response :success
    assert_includes response.body, 'class="value-unknown"'
    assert_includes response.body, "Nieznane"
    assert_includes response.body, "offer-incomplete"
    assert_includes response.body, "Zwróć uwagę, że w tej ofercie brakuje kosztu ubezpieczenia życia i nieruchomości"
  end

  test "names only missing life insurance in incomplete offer note" do
    offer = loan_offers(:one)
    offer.update!(
      life_insurance_percent: nil,
      life_insurance_years: nil,
      life_insurance_total: nil,
      life_insurance_full_term: false,
      life_insurance_one_time: false
    )

    get loan_comparison_path(locale: :pl, rate_type_slug: "oprocentowanie-zmienne")

    assert_response :success
    assert_includes response.body, "Zwróć uwagę, że w tej ofercie brakuje kosztu ubezpieczenia życia, więc"
    refute_includes response.body, "życia i nieruchomości"
  end

  test "shows one-time life insurance as percent of loan amount" do
    offer = loan_offers(:one)
    offer.update!(
      life_insurance_percent: 1.5,
      life_insurance_years: nil,
      life_insurance_total: nil,
      life_insurance_full_term: false,
      life_insurance_one_time: true
    )

    get loan_comparison_path(locale: :pl, rate_type_slug: "oprocentowanie-zmienne"), params: {
      loan_amount: 400_000,
      years: 25
    }

    assert_response :success
    assert_includes response.body, "Jednorazowo 1.5% kwoty kredytu"
    assert_includes response.body, "6000 PLN"
  end

  test "shows rate notes for variable and fixed offers" do
    get loan_comparison_path(locale: :pl, rate_type_slug: "oprocentowanie-zmienne"), params: {
      loan_amount: 400_000,
      years: 25
    }

    assert_response :success
    assert_includes response.body, "= marża"

    get loan_comparison_path(locale: :pl, rate_type_slug: "oprocentowanie-stale"), params: {
      loan_amount: 400_000,
      years: 25
    }

    assert_response :success
    assert_includes response.body, "Stała stopa"
    assert_includes response.body, "potem zmienna"
    assert_includes response.body, "marża"
    refute_match(/Stała stopa przez .* lat, potem zmienna\s*<\/div>/, response.body)
  end

  test "form submit from site root redirects to variable rate slug" do
    get "/", params: { loan_amount: 500_000, years: 20 }

    assert_response :redirect
    assert_match %r{/oprocentowanie-zmienne}, response.location
    assert_match(/loan_amount=500000/, response.location)
    assert_match(/years=20/, response.location)
    assert_match(/#results-table\z/, response.location)
  end

  test "form submit from locale root redirects to localized variable rate slug" do
    get root_path(locale: :en), params: { loan_amount: 500_000, years: 20 }

    assert_response :redirect
    assert_match %r{/en/variable-rate}, response.location
    assert_match(/loan_amount=500000/, response.location)
  end

  test "form submit on rate type slug does not redirect" do
    get loan_comparison_path(locale: nil, rate_type_slug: "oprocentowanie-zmienne"),
        params: { loan_amount: 500_000, years: 20 }

    assert_response :success
  end

  test "locale switch keeps comparison query params" do
    get loan_comparison_path(locale: :pl, rate_type_slug: "oprocentowanie-zmienne"), params: {
      loan_amount: 500_000,
      years: 20,
      overpayment_mode: "fixed_monthly",
      fixed_monthly_payment: 5_000
    }

    assert_response :success
    assert_includes response.body, "loan_amount=500000"
    assert_includes response.body, "years=20"
    assert_includes response.body, "overpayment_mode=fixed_monthly"
    assert_includes response.body, "fixed_monthly_payment=5000"
    assert_includes response.body, 'value="http://www.example.com/en/variable-rate?'
  end

  test "locale switch from slug-only path keeps polish slug for pl and adds locale for others" do
    get loan_comparison_path(locale: nil, rate_type_slug: "oprocentowanie-zmienne")

    assert_response :success
    assert_includes response.body, 'value="http://www.example.com/oprocentowanie-zmienne"'
    assert_includes response.body, 'value="http://www.example.com/en/variable-rate"'
    assert_includes response.body, 'value="http://www.example.com/ua/zminna-stavka"'
  end

  test "hreflang on polish prefixed path points to canonical urls" do
    get root_path(locale: :pl)

    assert_response :success
    assert_includes response.body, 'hreflang="pl" href="http://www.example.com/"'
    assert_includes response.body, 'hreflang="en" href="http://www.example.com/en"'
    assert_includes response.body, 'hreflang="x-default" href="http://www.example.com/"'
  end

  test "uses localized english and ukrainian rate type slugs" do
    get loan_comparison_path(locale: :en, rate_type_slug: "variable-rate")
    assert_response :success
    assert_includes response.body, 'rel="canonical" href="http://www.example.com/en/variable-rate"'
    assert_includes response.body, "/en/variable-rate"

    get loan_comparison_path(locale: :ua, rate_type_slug: "fiksovana-stavka")
    assert_response :success
    assert_includes response.body, "/ua/fiksovana-stavka"
  end

  test "calculates custom offer" do
    skip "Custom bank offer UI is temporarily hidden"
  end
end
