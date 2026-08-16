require "test_helper"

class LoanComparisonsControllerTest < ActionDispatch::IntegrationTest
  test "renders public comparison page" do
    get root_path(locale: :pl)

    assert_response :success
    assert_includes response.body, "Porownaj oferty kredytow hipotecznych"
    assert_includes response.body, "Okres kredytu (lata)"
    refute_includes response.body, "Wyniki aktualizuja sie automatycznie po zmianie pola."
    refute_includes response.body, "Zalozenia ogolne"
    refute_includes response.body, "submitNow"
    assert_match(/<th>\s*Oprocentowanie zmienne\s*<\/th>/, response.body)
    assert_includes response.body, "Oferta banku"
    assert_includes response.body, "Oprocentowanie zmienne"
    assert_includes response.body, "Oprocentowanie stale"
    assert_includes response.body, "Docelowa laczna rata miesieczna (PLN)"
    assert_includes response.body, "Nadplacaj w okresie kary"
    assert_includes response.body, "data-controller=\"cookie-consent\""
    assert_includes response.body, "Akceptuj wszystkie"
    refute_includes response.body, "Panel admina"
    refute_includes response.body, admin_root_path
  end

  test "filters offers by fixed-period rate type" do
    get root_path(locale: :pl), params: {
      rate_type: "fixed_period",
      loan_amount: 400_000,
      years: 25
    }

    assert_response :success
    assert_includes response.body, "Offer Two"
    refute_includes response.body, "Offer One"
    assert_match(/<th>\s*Oprocentowanie stale\s*<\/th>/, response.body)
    assert_includes response.body, "Oprocentowanie stale"
  end

  test "shows empty-state message when selected type has no offers" do
    LoanOffer.update_all(rate_type: LoanOffer.rate_types[:variable])

    get root_path(locale: :pl), params: {
      rate_type: "fixed_period",
      loan_amount: 400_000,
      years: 25
    }

    assert_response :success
    assert_includes response.body, "Brak ofert dla typu"
  end

  test "defaults to no user overpayment note" do
    get root_path(locale: :pl), params: { loan_amount: 400_000, years: 25 }

    assert_response :success
    refute_includes response.body, "Nadplata uzytkownika nie jest stosowana."
  end

  test "renders bank title as clickable label without printing url text" do
    get root_path(locale: :pl)

    assert_response :success
    assert_includes response.body, 'href="https://bank-one.test"'
    refute_includes response.body, ">https://bank-one.test<"
  end

  test "shows validation note for fixed monthly mode when payment is too low" do
    get root_path(locale: :pl), params: {
      loan_amount: 400_000,
      years: 25,
      overpayment_mode: "fixed_monthly",
      fixed_monthly_payment: 1
    }

    assert_response :success
    assert_includes response.body, "Rata stala musi byc wyzsza od raty standardowej"
  end

  test "applies fixed target period simulation" do
    get root_path(locale: :pl), params: {
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
    get root_path(locale: :pl), params: {
      loan_amount: 400_000,
      years: 25,
      overpayment_mode: "fixed_monthly",
      fixed_monthly_payment: 9_000,
      fixed_monthly_overpay_during_penalty: "0"
    }

    assert_response :success
    refute_includes response.body, "Kara za nadplate:"
  end

  test "renders loan period sort option" do
    get root_path(locale: :pl)

    assert_response :success
    assert_includes response.body, 'value="loan-period"'
    assert_includes response.body, "Laczna rata"
    assert_includes response.body, "Rata w pierwszym miesiacu"
    assert_includes response.body, "Kwota kredytu"
    assert_includes response.body, "Odsetki banku"
    assert_includes response.body, "Jednorazowy pakiet poza kolumna raty pierwszego miesiaca"
    assert_includes response.body, "miesiecznie przez"
  end

  test "shows rate notes for variable and fixed offers" do
    get root_path(locale: :pl), params: {
      rate_type: "variable",
      loan_amount: 400_000,
      years: 25
    }

    assert_response :success
    assert_includes response.body, "= marza"

    get root_path(locale: :pl), params: {
      rate_type: "fixed_period",
      loan_amount: 400_000,
      years: 25
    }

    assert_response :success
    assert_includes response.body, "Stale"
    assert_includes response.body, "potem obowiazuje stopa zmienna"
  end

  test "calculates custom offer" do
    post custom_compare_path(locale: :pl),
         params: {
           loan_amount: 400_000,
           years: 20,
           custom_offer: {
             bank_title: "Test Bank",
             title: "Test Offer",
             bank_margin_percent: "1.8",
             wibor_kind: "wibor_3m",
             bank_commission_percent: "1.0",
             property_insurance_monthly: "30"
           }
         }

    assert_response :success
    assert_includes response.body, "Wynik oferty niestandardowej"
  end
end
