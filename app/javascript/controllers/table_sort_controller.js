import { Controller } from "@hotwired/stimulus"

const DEFAULT_SORT_KEY = "total-paid"
const DEFAULT_SORT_DIRECTION = "asc"
const VALID_SORT_KEYS = new Set(["bank-margin", "monthly-payment", "loan-period", "total-paid"])
const VALID_SORT_DIRECTIONS = new Set(["asc", "desc"])

export default class extends Controller {
  static targets = ["tbody", "row", "sortKey", "direction"]

  connect() {
    const { key, direction } = this.currentSortFromUrl()
    this.selectSort(key, direction)
    this.syncLinkedUrls(key, direction)
  }

  sort() {
    const key = this.selectedValue(this.sortKeyTargets, DEFAULT_SORT_KEY)
    const direction = this.selectedValue(this.directionTargets, DEFAULT_SORT_DIRECTION)

    this.reorderRows(key, direction)
    this.syncUrl(key, direction)
    this.syncLinkedUrls(key, direction)
  }

  currentSortFromUrl() {
    const url = new URL(window.location.href)

    return {
      key: this.validSortKey(url.searchParams.get("sort_key")),
      direction: this.validSortDirection(url.searchParams.get("sort_direction"))
    }
  }

  selectSort(key, direction) {
    this.sortKeyTargets.forEach((input) => {
      input.checked = input.value === key
    })

    this.directionTargets.forEach((input) => {
      input.checked = input.value === direction
    })
  }

  reorderRows(key, direction) {
    const directionMultiplier = direction === "desc" ? -1 : 1
    const rows = [...this.rowTargets]

    rows.sort((rowA, rowB) => {
      const valueA = Number(rowA.getAttribute(`data-sort-${key}`) || "0")
      const valueB = Number(rowB.getAttribute(`data-sort-${key}`) || "0")

      if (valueA === valueB) {
        const titleA = rowA.querySelector("td strong")?.textContent || ""
        const titleB = rowB.querySelector("td strong")?.textContent || ""
        return titleA.localeCompare(titleB)
      }

      return (valueA - valueB) * directionMultiplier
    })

    rows.forEach((row) => this.tbodyTarget.appendChild(row))
  }

  syncUrl(key, direction) {
    const url = applySortParams(new URL(window.location.href), key, direction)

    if (window.Turbo?.session?.history?.replace) {
      window.Turbo.session.history.replace(url)
    } else {
      window.history.replaceState(window.history.state, "", url)
    }
  }

  syncLinkedUrls(key, direction) {
    document.querySelectorAll('input[name="sort_key"]').forEach((input) => {
      input.value = key
    })

    document.querySelectorAll('input[name="sort_direction"]').forEach((input) => {
      input.value = direction
    })

    document.querySelectorAll("[data-switch-url]").forEach((element) => {
      const url = applySortParams(new URL(element.dataset.switchUrl, document.baseURI), key, direction)
      element.dataset.switchUrl = `${url.pathname}${url.search}`
    })

    const localeSelect = document.getElementById("locale-switch-select")
    if (!localeSelect) return

    localeSelect.querySelectorAll("option").forEach((option) => {
      const url = applySortParams(new URL(option.value, document.baseURI), key, direction)
      option.value = url.toString()
    })
  }

  selectedValue(targets, fallback) {
    return targets.find((input) => input.checked)?.value || fallback
  }

  validSortKey(value) {
    return VALID_SORT_KEYS.has(value) ? value : DEFAULT_SORT_KEY
  }

  validSortDirection(value) {
    return VALID_SORT_DIRECTIONS.has(value) ? value : DEFAULT_SORT_DIRECTION
  }
}

function applySortParams(url, key, direction) {
  if (key === DEFAULT_SORT_KEY && direction === DEFAULT_SORT_DIRECTION) {
    url.searchParams.delete("sort_key")
    url.searchParams.delete("sort_direction")
  } else {
    url.searchParams.set("sort_key", key)
    url.searchParams.set("sort_direction", direction)
  }

  return url
}
