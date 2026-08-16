import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["tbody", "row", "sortKey", "direction"]

  connect() {
    this.sort()
  }

  sort() {
    const key = this.selectedValue(this.sortKeyTargets, "total-paid")
    const direction = this.selectedValue(this.directionTargets, "asc") === "desc" ? -1 : 1

    const rows = [...this.rowTargets]
    rows.sort((rowA, rowB) => {
      const valueA = Number(rowA.getAttribute(`data-sort-${key}`) || "0")
      const valueB = Number(rowB.getAttribute(`data-sort-${key}`) || "0")

      if (valueA === valueB) {
        const titleA = rowA.querySelector("td strong")?.textContent || ""
        const titleB = rowB.querySelector("td strong")?.textContent || ""
        return titleA.localeCompare(titleB)
      }

      return (valueA - valueB) * direction
    })

    rows.forEach((row) => this.tbodyTarget.appendChild(row))
  }

  selectedValue(targets, fallback) {
    return targets.find((input) => input.checked)?.value || fallback
  }
}
