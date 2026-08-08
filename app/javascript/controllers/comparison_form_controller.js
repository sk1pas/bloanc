import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "loanAmountInput",
    "loanAmountRange",
    "yearsInput",
    "yearsRange",
    "modeRadio",
    "fixedMonthlyWrap",
    "fixedPeriodWrap",
    "fixedMonthlyInput",
    "fixedMonthlyRange",
    "targetYearsInput",
    "targetYearsRange"
  ]

  connect() {
    this.updateTargetYearsBounds()
    this.updateOverpaymentFields()
    this.scrollToResultsIfRequested()
  }

  syncLoanAmountFromInput() {
    this.loanAmountRangeTarget.value = this.loanAmountInputTarget.value
  }

  syncLoanAmountFromRange() {
    this.loanAmountInputTarget.value = this.loanAmountRangeTarget.value
  }

  syncYearsFromInput() {
    this.yearsRangeTarget.value = this.yearsInputTarget.value
    this.updateTargetYearsBounds()
  }

  syncYearsFromRange() {
    this.yearsInputTarget.value = this.yearsRangeTarget.value
    this.updateTargetYearsBounds()
  }

  syncFixedMonthlyFromInput() {
    this.fixedMonthlyRangeTarget.value = this.fixedMonthlyInputTarget.value || this.fixedMonthlyRangeTarget.min
  }

  syncFixedMonthlyFromRange() {
    this.fixedMonthlyInputTarget.value = this.fixedMonthlyRangeTarget.value
  }

  syncTargetYearsFromInput() {
    const min = Number(this.targetYearsRangeTarget.min || 1)
    const max = Number(this.targetYearsRangeTarget.max || 1)
    const parsed = Number(this.targetYearsInputTarget.value || min)
    const normalized = Math.min(Math.max(parsed, min), max)

    this.targetYearsInputTarget.value = String(normalized)
    this.targetYearsRangeTarget.value = String(normalized)
  }

  syncTargetYearsFromRange() {
    this.targetYearsInputTarget.value = this.targetYearsRangeTarget.value
  }

  modeChanged() {
    this.updateOverpaymentFields()
  }

  updateOverpaymentFields() {
    const mode = this.selectedMode()
    const useFixedMonthly = mode === "fixed_monthly"
    const useFixedPeriod = mode === "fixed_period"

    this.toggleFieldGroup(
      this.fixedMonthlyWrapTarget,
      [this.fixedMonthlyInputTarget, this.fixedMonthlyRangeTarget],
      useFixedMonthly
    )
    this.toggleFieldGroup(
      this.fixedPeriodWrapTarget,
      [this.targetYearsInputTarget, this.targetYearsRangeTarget],
      useFixedPeriod
    )
  }

  updateTargetYearsBounds() {
    const years = Number(this.yearsInputTarget.value || this.yearsRangeTarget.value || 1)
    const maxYears = Math.max(years - 1, 1)

    this.targetYearsInputTarget.max = String(maxYears)
    this.targetYearsRangeTarget.max = String(maxYears)

    const current = Number(this.targetYearsInputTarget.value || 1)
    const clamped = Math.min(Math.max(current, 1), maxYears)
    this.targetYearsInputTarget.value = String(clamped)
    this.targetYearsRangeTarget.value = String(clamped)
  }

  toggleFieldGroup(wrapper, inputs, enabled) {
    wrapper.classList.toggle("d-none", !enabled)
    inputs.forEach((input) => {
      input.disabled = !enabled
    })
  }

  selectedMode() {
    return this.modeRadioTargets.find((radio) => radio.checked)?.value || "none"
  }

  scrollToResultsIfRequested() {
    const search = new URLSearchParams(window.location.search)
    if (search.size === 0) return

    const resultsSection = document.getElementById("results-table")
    if (!resultsSection) return

    requestAnimationFrame(() => {
      resultsSection.scrollIntoView({ behavior: "smooth", block: "start" })
    })
  }
}
