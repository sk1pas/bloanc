import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "loanAmountInput",
    "loanAmountRange",
    "yearsInput",
    "yearsRange",
    "rateTypeInput",
    "rateTypeTab",
    "modeRadio",
    "fixedMonthlyWrap",
    "fixedPeriodWrap",
    "fixedMonthlyInput",
    "fixedMonthlyRange",
    "targetYearsInput",
    "targetYearsRange"
  ]

  connect() {
    this.updateRateTypeTabs()
    this.updateTargetYearsBounds()
    this.updateOverpaymentFields()
    this.scrollToResultsIfRequested()
  }

  selectRateType(event) {
    event.preventDefault()

    if (!this.hasRateTypeInputTarget) return

    const selectedType = event.currentTarget.dataset.rateType
    if (!selectedType) return

    const changed = this.rateTypeInputTarget.value !== selectedType
    this.rateTypeInputTarget.value = selectedType
    this.updateRateTypeTabs()

    if (changed) {
      this.element.requestSubmit()
    }
  }

  syncLoanAmountFromInput() {
    this.#setRangeFromInput(this.loanAmountRangeTarget, this.loanAmountInputTarget.value)
  }

  syncLoanAmountFromRange() {
    this.loanAmountInputTarget.value = this.loanAmountRangeTarget.value
  }

  syncYearsFromInput() {
    this.#setRangeFromInput(this.yearsRangeTarget, this.yearsInputTarget.value)
    this.updateTargetYearsBounds()
  }

  syncYearsFromRange() {
    this.yearsInputTarget.value = this.yearsRangeTarget.value
    this.updateTargetYearsBounds()
  }

  syncFixedMonthlyFromInput() {
    this.#setRangeFromInput(
      this.fixedMonthlyRangeTarget,
      this.fixedMonthlyInputTarget.value || this.fixedMonthlyRangeTarget.min
    )
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

  nudgeRange(event) {
    event.preventDefault()
    event.stopPropagation()

    const button = event.currentTarget
    const rangeName = button.dataset.rangeTarget
    const direction = Number(button.dataset.rangeDirection || "0")
    if (!rangeName || !direction) return

    const range = this[`has${this.#capitalize(rangeName)}Target`] ? this[`${rangeName}Target`] : null
    if (!range || range.disabled) return

    const step = Number(range.step || 1)
    const min = Number(range.min)
    const max = Number(range.max)
    const next = Math.min(max, Math.max(min, Number(range.value) + direction * step))
    range.value = String(next)
    range.dispatchEvent(new Event("input", { bubbles: true }))
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

    this.element.querySelectorAll("[data-range-target='fixedMonthlyRange']").forEach((button) => {
      button.disabled = !useFixedMonthly
    })
    this.element.querySelectorAll("[data-range-target='targetYearsRange']").forEach((button) => {
      button.disabled = !useFixedPeriod
    })
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

  updateRateTypeTabs() {
    if (!this.hasRateTypeInputTarget) return

    const selectedType = this.rateTypeInputTarget.value || "variable"
    this.rateTypeTabTargets.forEach((tab) => {
      tab.classList.toggle("active", tab.dataset.rateType === selectedType)
    })
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

  #setRangeFromInput(range, rawValue) {
    const min = Number(range.min)
    const max = Number(range.max)
    const parsed = Number(rawValue)
    if (!Number.isFinite(parsed)) {
      range.value = String(min)
      return
    }

    range.value = String(Math.min(max, Math.max(min, parsed)))
  }

  #capitalize(value) {
    return value.charAt(0).toUpperCase() + value.slice(1)
  }
}
