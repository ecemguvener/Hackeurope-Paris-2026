import { Controller } from "@hotwired/stimulus"

// Highlights the paragraph nearest the viewport center on scroll.
// Attach to a container with `data-controller="reading-highlight"`.
// All direct <p> children (and elements with `data-reading-paragraph`) are tracked.
export default class extends Controller {
  connect() {
    this._onScroll = this._highlight.bind(this)
    window.addEventListener("scroll", this._onScroll, { passive: true })
    // Initial highlight
    requestAnimationFrame(() => this._highlight())
  }

  disconnect() {
    window.removeEventListener("scroll", this._onScroll)
    this._clearAll()
  }

  _highlight() {
    const paragraphs = this.element.querySelectorAll("p, [data-reading-paragraph]")
    if (paragraphs.length === 0) return

    const viewportCenter = window.innerHeight / 2
    let closest = null
    let closestDistance = Infinity

    paragraphs.forEach(p => {
      const rect = p.getBoundingClientRect()
      const pCenter = rect.top + rect.height / 2
      const distance = Math.abs(pCenter - viewportCenter)
      if (distance < closestDistance) {
        closestDistance = distance
        closest = p
      }
    })

    if (closest && !closest.classList.contains("reading-highlight")) {
      this._clearAll()
      closest.classList.add("reading-highlight")
    }
  }

  _clearAll() {
    this.element.querySelectorAll(".reading-highlight").forEach(el => {
      el.classList.remove("reading-highlight")
    })
  }
}
