import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    storageKey: { type: String, default: "bloanc_cookie_consent" }
  }

  connect() {
    if (this.#storedConsent()) {
      this.#hide()
      return
    }

    this.element.hidden = false
  }

  accept() {
    this.#persist("accepted")
    window.dispatchEvent(new CustomEvent("cookie-consent:change", { detail: { consent: "accepted" } }))
    this.#hide()
  }

  reject() {
    this.#persist("rejected")
    window.dispatchEvent(new CustomEvent("cookie-consent:change", { detail: { consent: "rejected" } }))
    this.#hide()
  }

  #persist(value) {
    try {
      window.localStorage.setItem(this.storageKeyValue, value)
    } catch (_error) {
      // Ignore storage failures (private mode, blocked storage).
    }
  }

  #storedConsent() {
    try {
      return window.localStorage.getItem(this.storageKeyValue)
    } catch (_error) {
      return null
    }
  }

  #hide() {
    this.element.hidden = true
  }
}
