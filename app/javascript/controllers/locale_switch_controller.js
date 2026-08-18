import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  go(event) {
    const url = event.currentTarget.value
    if (!url) return

    if (window.Turbo) {
      window.Turbo.visit(url)
    } else {
      window.location.assign(url)
    }
  }
}
