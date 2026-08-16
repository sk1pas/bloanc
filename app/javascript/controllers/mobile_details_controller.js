import { Controller } from "@hotwired/stimulus"

// Keep <details> open on desktop; collapsed by default on mobile.
export default class extends Controller {
  connect() {
    this.mediaQuery = window.matchMedia("(min-width: 768px)")
    this.syncOpenState = this.syncOpenState.bind(this)
    this.syncOpenState()
    this.mediaQuery.addEventListener("change", this.syncOpenState)
  }

  disconnect() {
    this.mediaQuery.removeEventListener("change", this.syncOpenState)
  }

  syncOpenState() {
    if (this.mediaQuery.matches) {
      this.element.setAttribute("open", "")
    } else {
      this.element.removeAttribute("open")
    }
  }
}
