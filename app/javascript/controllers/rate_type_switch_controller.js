import { Controller } from "@hotwired/stimulus"

const SCROLL_CANCEL_EVENT = "comparison-form:cancel-scroll"

export default class extends Controller {
  static values = {
    pageTitle: String,
    metaDescription: String,
    rateType: String,
    canonicalUrl: String
  }

  connect() {
    this.stripFrameNavigationState()
  }

  async switch(event) {
    event.preventDefault()

    const button = event.currentTarget
    if (button.getAttribute("aria-selected") === "true") return

    const url = button.dataset.switchUrl
    if (!url) return

    document.dispatchEvent(new CustomEvent(SCROLL_CANCEL_EVENT))
    sessionStorage.removeItem("comparisonFormScrollToResults")

    const location = new URL(url, document.baseURI)
    this.updateActiveTab(button)
    this.element.setAttribute("aria-busy", "true")

    try {
      const response = await fetch(url, {
        headers: {
          "Turbo-Frame": "comparison_results",
          Accept: "text/html"
        },
        credentials: "same-origin"
      })

      if (!response.ok) return

      const html = await response.text()
      const doc = new DOMParser().parseFromString(html, "text/html")
      const newFrame = doc.getElementById("comparison_results")
      if (!newFrame) return

      window.Turbo.session.history.push(location)

      newFrame.removeAttribute("src")
      newFrame.removeAttribute("complete")
      this.element.replaceWith(newFrame)

      const frame = document.getElementById("comparison_results")
      if (!frame) return

      syncDocumentMetaFromFrame(frame)
      syncFormRateTypeFromFrame(frame)
      syncFormActionFromLocation(location)
    } finally {
      document.getElementById("comparison_results")?.removeAttribute("aria-busy")
    }
  }

  stripFrameNavigationState() {
    this.element.removeAttribute("src")
    this.element.removeAttribute("complete")
  }

  updateActiveTab(selectedButton) {
    this.element.querySelectorAll('[role="tab"]').forEach((tab) => {
      const isSelected = tab === selectedButton
      tab.classList.toggle("active", isSelected)
      tab.setAttribute("aria-selected", isSelected ? "true" : "false")
      tab.tabIndex = isSelected ? 0 : -1
    })

    const panel = this.element.querySelector("#results-table-panel")
    if (panel && selectedButton.id) {
      panel.setAttribute("aria-labelledby", selectedButton.id)
    }
  }
}

function syncDocumentMetaFromFrame(frame) {
  const pageTitle = frame.dataset.rateTypeSwitchPageTitleValue
  const metaDescription = frame.dataset.rateTypeSwitchMetaDescriptionValue
  const canonicalUrl = frame.dataset.rateTypeSwitchCanonicalUrlValue

  if (pageTitle) {
    document.title = pageTitle
  }

  const descriptionMeta = document.querySelector('meta[name="description"]')
  if (descriptionMeta && metaDescription) {
    descriptionMeta.content = metaDescription
  }

  const canonicalLink = document.querySelector('link[rel="canonical"]')
  if (canonicalLink && canonicalUrl) {
    canonicalLink.href = canonicalUrl
  }

  const ogTitle = document.querySelector('meta[property="og:title"]')
  if (ogTitle && pageTitle) {
    ogTitle.content = pageTitle
  }

  const ogDescription = document.querySelector('meta[property="og:description"]')
  if (ogDescription && metaDescription) {
    ogDescription.content = metaDescription
  }

  const ogUrl = document.querySelector('meta[property="og:url"]')
  if (ogUrl && canonicalUrl) {
    ogUrl.content = canonicalUrl
  }

  const twitterTitle = document.querySelector('meta[name="twitter:title"]')
  if (twitterTitle && pageTitle) {
    twitterTitle.content = pageTitle
  }

  const twitterDescription = document.querySelector('meta[name="twitter:description"]')
  if (twitterDescription && metaDescription) {
    twitterDescription.content = metaDescription
  }
}

function syncFormRateTypeFromFrame(frame) {
  const rateType = frame.dataset.rateTypeSwitchRateTypeValue
  if (!rateType) return

  document.querySelectorAll('input[name="rate_type"]').forEach((input) => {
    input.value = rateType
  })
}

function syncFormActionFromLocation(location) {
  const form = document.querySelector("form.hero-form")
  if (!form) return

  form.action = location.pathname
}
