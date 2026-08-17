import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["yearsField", "fullTerm", "oneTime", "totalField"]

  connect() {
    this.toggle()
  }

  toggle() {
    const oneTime = this.hasOneTimeTarget && this.oneTimeTarget.checked
    const fullTerm = this.hasFullTermTarget && this.fullTermTarget.checked

    if (this.hasYearsFieldTarget) {
      this.yearsFieldTarget.disabled = oneTime || fullTerm
      this.yearsFieldTarget.required = false
    }

    if (this.hasFullTermTarget) {
      this.fullTermTarget.disabled = oneTime
    }

    if (this.hasTotalFieldTarget) {
      this.totalFieldTarget.disabled = oneTime
    }
  }
}
