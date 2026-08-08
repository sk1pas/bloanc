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
    assert_includes response.body, "Docelowa laczna rata miesieczna (PLN)"
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
    assert_includes response.body, "Tryb docelowego okresu aktywny: 15 lat"
  end

  test "renders loan period sort option" do
    get root_path(locale: :pl)

    assert_response :success
    assert_includes response.body, 'value="loan-period"'
    assert_includes response.body, "Rata bazowa"
    assert_includes response.body, "Rata w pierwszym miesiacu"
    assert_includes response.body, "Kwota kredytu"
    assert_includes response.body, "Odsetki banku"
    assert_includes response.body, "Jednorazowy pakiet oplacony w pierwszym miesiacu"
    assert_includes response.body, "miesiecznie przez"
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
