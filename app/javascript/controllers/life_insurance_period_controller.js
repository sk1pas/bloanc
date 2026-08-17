import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["yearsField", "fullTerm"]

  connect() {
    this.toggle()
  }

  toggle() {
    if (!this.hasYearsFieldTarget || !this.hasFullTermTarget) return

    const fullTerm = this.fullTermTarget.checked
    this.yearsFieldTarget.disabled = fullTerm
    this.yearsFieldTarget.required = false
  }
}
