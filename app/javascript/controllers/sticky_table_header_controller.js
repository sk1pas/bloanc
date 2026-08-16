import { Controller } from "@hotwired/stimulus"

// Keeps a fixed header clone visible while the results table scrolls vertically,
// and mirrors horizontal scroll from the overflow wrapper.
export default class extends Controller {
  static targets = ["scroller", "table", "head"]

  connect() {
    this.update = this.update.bind(this)
    this.rebuild = this.rebuild.bind(this)

    window.addEventListener("scroll", this.update, { passive: true })
    window.addEventListener("resize", this.rebuild)
    this.scrollerTarget.addEventListener("scroll", this.update, { passive: true })

    this.rebuild()
  }

  disconnect() {
    window.removeEventListener("scroll", this.update)
    window.removeEventListener("resize", this.rebuild)
    this.scrollerTarget.removeEventListener("scroll", this.update)
    this.#teardownClone()
  }

  rebuild() {
    this.#teardownClone()

    this.clone = document.createElement("div")
    this.clone.className = "sticky-table-header"
    this.clone.hidden = true
    this.clone.setAttribute("aria-hidden", "true")

    this.cloneScroller = document.createElement("div")
    this.cloneScroller.className = "sticky-table-header__scroller"

    this.cloneTable = document.createElement("table")
    this.cloneTable.className = this.tableTarget.className
    this.cloneTable.appendChild(this.headTarget.cloneNode(true))
    this.cloneTable.querySelectorAll("[id]").forEach((node) => node.removeAttribute("id"))

    this.cloneScroller.appendChild(this.cloneTable)
    this.clone.appendChild(this.cloneScroller)
    document.body.appendChild(this.clone)

    this.update()
  }

  update() {
    if (!this.clone) return

    const headRect = this.headTarget.getBoundingClientRect()
    const tableRect = this.tableTarget.getBoundingClientRect()
    const scrollerRect = this.scrollerTarget.getBoundingClientRect()
    const shouldShow = headRect.top < 0 && tableRect.bottom > Math.max(headRect.height, 40)

    this.clone.hidden = !shouldShow
    if (!shouldShow) return

    this.#syncWidths()
    this.clone.style.top = "0px"
    this.clone.style.left = `${Math.max(scrollerRect.left, 0)}px`
    this.clone.style.width = `${scrollerRect.width}px`
    this.cloneScroller.scrollLeft = this.scrollerTarget.scrollLeft
  }

  #syncWidths() {
    const sourceCells = this.headTarget.querySelectorAll("th")
    const cloneCells = this.cloneTable.querySelectorAll("th")
    const tableWidth = this.tableTarget.getBoundingClientRect().width

    this.cloneTable.style.width = `${tableWidth}px`
    this.cloneTable.style.minWidth = `${tableWidth}px`

    sourceCells.forEach((sourceCell, index) => {
      const cloneCell = cloneCells[index]
      if (!cloneCell) return

      const width = sourceCell.getBoundingClientRect().width
      cloneCell.style.width = `${width}px`
      cloneCell.style.minWidth = `${width}px`
      cloneCell.style.maxWidth = `${width}px`
    })
  }

  #teardownClone() {
    this.clone?.remove()
    this.clone = null
    this.cloneScroller = null
    this.cloneTable = null
  }
}
