import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    key: String,
    defaultOpen: { type: Boolean, default: true }
  }

  connect() {
    const stored = this.#read()

    if (stored === "0") {
      this.element.removeAttribute("open")
    } else if (stored === "1") {
      this.element.setAttribute("open", "")
    } else if (this.defaultOpenValue) {
      this.element.setAttribute("open", "")
    } else {
      this.element.removeAttribute("open")
    }
  }

  persist() {
    this.#write(this.element.open ? "1" : "0")
  }

  #read() {
    const encodedKey = this.keyValue.replace(/[.*+?^${}()|[\]\\]/g, "\\$&")
    const match = document.cookie.match(new RegExp(`(?:^|; )${encodedKey}=([^;]*)`))
    return match ? decodeURIComponent(match[1]) : null
  }

  #write(value) {
    const secure = window.location.protocol === "https:" ? "; Secure" : ""
    document.cookie = `${this.keyValue}=${encodeURIComponent(value)}; Path=/; Max-Age=31536000; SameSite=Lax${secure}`
  }
}
