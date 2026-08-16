import { Controller } from "@hotwired/stimulus"

// Monthly life insurance = remaining_balance * (percent / 100)
// So percent = total_insurance * 100 / sum(remaining_balances over insurance months)
// Remaining balances come from a standard annuity schedule (not from total bank interest).
export default class extends Controller {
  static targets = [
    "modal",
    "loanAmount",
    "loanMonths",
    "annualRate",
    "insuranceYears",
    "insuranceTotal",
    "result",
    "error",
    "percentField",
    "yearsField",
    "totalField"
  ]

  static values = {
    wibor1m: Number,
    wibor3m: Number
  }

  connect() {
    this.modalInstance = null
  }

  open(event) {
    event.preventDefault()
    this.#clearFeedback()
    this.#prefillFromForm()
    this.#modal().show()
  }

  calculate(event) {
    event.preventDefault()
    this.#clearFeedback()

    const loanAmount = this.#parseNumber(this.loanAmountTarget.value)
    const loanMonths = this.#parseInteger(this.loanMonthsTarget.value)
    const annualRate = this.#parseNumber(this.annualRateTarget.value)
    const insuranceYears = this.#parseInteger(this.insuranceYearsTarget.value)
    const insuranceTotal = this.#parseNumber(this.insuranceTotalTarget.value)

    if (![loanAmount, loanMonths, annualRate, insuranceYears, insuranceTotal].every((value) => value > 0)) {
      this.#showError("Enter positive values for loan amount, loan months, annual rate, insurance years, and total insurance.")
      return
    }

    const insuranceMonths = insuranceYears * 12
    if (insuranceMonths > loanMonths) {
      this.#showError("Insurance period cannot be longer than the loan period.")
      return
    }

    const balanceSum = this.#sumRemainingBalances({
      loanAmount,
      loanMonths,
      annualRatePercent: annualRate,
      insuranceMonths
    })

    if (balanceSum <= 0) {
      this.#showError("Could not build an amortization schedule for these inputs.")
      return
    }

    const monthlyPercent = (insuranceTotal * 100) / balanceSum
    const firstMonth = loanAmount * (monthlyPercent / 100)

    this.calculatedPercent = monthlyPercent
    this.calculatedYears = insuranceYears

    this.resultTarget.hidden = false
    this.resultTarget.innerHTML = `
      <div><strong>Monthly life insurance:</strong> ${this.#formatNumber(monthlyPercent, 4)}% of remaining principal</div>
      <div class="small text-secondary mt-1">
        First month ≈ ${this.#formatNumber(firstMonth, 2)} PLN.
        Based on annuity schedule (rate ${this.#formatNumber(annualRate, 3)}% / year).
      </div>
    `
  }

  apply(event) {
    event.preventDefault()

    if (this.calculatedPercent == null || this.calculatedYears == null) {
      this.calculate(event)
      if (this.calculatedPercent == null) return
    }

    this.percentFieldTarget.value = this.#formatNumber(this.calculatedPercent, 4)
    this.yearsFieldTarget.value = String(this.calculatedYears)

    // Percent mode is used only when one-time total is blank.
    if (this.hasTotalFieldTarget) {
      this.totalFieldTarget.value = ""
    }

    this.#modal().hide()
  }

  #prefillFromForm() {
    if (this.hasInsuranceYearsTarget && this.hasYearsFieldTarget && this.yearsFieldTarget.value) {
      this.insuranceYearsTarget.value = this.yearsFieldTarget.value
    }

    if (this.hasInsuranceTotalTarget && this.hasTotalFieldTarget && this.totalFieldTarget.value) {
      this.insuranceTotalTarget.value = this.totalFieldTarget.value
    }

    const margin = this.#parseNumber(this.#formField("loan_offer_bank_margin_percent")?.value)
    const wibor = this.#selectedWibor()
    if (margin > 0 || wibor > 0) {
      this.annualRateTarget.value = this.#formatNumber(margin + wibor, 3)
    }
  }

  #selectedWibor() {
    const kind = this.#formField("loan_offer_wibor_kind")?.value
    if (kind === "wibor_1m") return this.wibor1mValue || 0
    return this.wibor3mValue || 0
  }

  #formField(id) {
    return this.element.closest("form")?.querySelector(`#${id}`)
  }

  #sumRemainingBalances({ loanAmount, loanMonths, annualRatePercent, insuranceMonths }) {
    const monthlyRate = annualRatePercent / 100 / 12
    let payment = this.#annuityPayment(loanAmount, monthlyRate, loanMonths)
    let balance = loanAmount
    let sum = 0

    for (let month = 0; month < loanMonths; month += 1) {
      if (balance <= 0) break

      if (month < insuranceMonths) {
        sum += balance
      }

      const interest = balance * monthlyRate
      let principal = payment - interest
      if (principal >= balance) {
        principal = balance
      }

      balance -= principal
    }

    return sum
  }

  #annuityPayment(principal, monthlyRate, months) {
    if (months <= 0) return 0
    if (monthlyRate === 0) return principal / months

    const factor = Math.pow(1 + monthlyRate, months)
    return (principal * monthlyRate * factor) / (factor - 1)
  }

  #modal() {
    if (!this.modalInstance) {
      this.modalInstance = new window.bootstrap.Modal(this.modalTarget)
    }
    return this.modalInstance
  }

  #clearFeedback() {
    this.calculatedPercent = null
    this.calculatedYears = null
    if (this.hasResultTarget) {
      this.resultTarget.hidden = true
      this.resultTarget.innerHTML = ""
    }
    if (this.hasErrorTarget) {
      this.errorTarget.hidden = true
      this.errorTarget.textContent = ""
    }
  }

  #showError(message) {
    this.errorTarget.hidden = false
    this.errorTarget.textContent = message
  }

  #parseNumber(value) {
    const normalized = String(value ?? "").trim().replace(/\s+/g, "").replace(",", ".")
    const number = Number.parseFloat(normalized)
    return Number.isFinite(number) ? number : NaN
  }

  #parseInteger(value) {
    const number = this.#parseNumber(value)
    return Number.isFinite(number) ? Math.trunc(number) : NaN
  }

  #formatNumber(value, digits) {
    return Number(value).toFixed(digits)
  }
}
