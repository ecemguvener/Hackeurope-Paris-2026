import { Controller } from "@hotwired/stimulus"

// Simple accessible tab panel controller.
//
//   data-controller="tabs"
//
// Targets:
//   tab   — a tab button (role="tab")
//   panel — a tab panel (role="tabpanel")
//
// Switching is triggered by: data-action="click->tabs#switch"
// Keyboard: left/right arrow keys move between tabs when focused.
export default class extends Controller {
  static targets = ["tab", "panel"]

  connect() {
    this.#showTab(0)
  }

  switch(event) {
    const idx = this.tabTargets.indexOf(event.currentTarget)
    if (idx >= 0) this.#showTab(idx)
  }

  keydown(event) {
    const currentIdx = this.tabTargets.findIndex(t => t === document.activeElement)
    if (currentIdx < 0) return

    if (event.key === "ArrowRight") {
      event.preventDefault()
      const nextIdx = (currentIdx + 1) % this.tabTargets.length
      this.#showTab(nextIdx)
      this.tabTargets[nextIdx].focus()
    } else if (event.key === "ArrowLeft") {
      event.preventDefault()
      const prevIdx = (currentIdx - 1 + this.tabTargets.length) % this.tabTargets.length
      this.#showTab(prevIdx)
      this.tabTargets[prevIdx].focus()
    }
  }

  #showTab(index) {
    this.tabTargets.forEach((tab, i) => {
      const active = i === index
      tab.setAttribute("aria-selected", String(active))
      tab.setAttribute("tabindex", active ? "0" : "-1")
      tab.classList.toggle("tab-active", active)
      tab.classList.toggle("tab-inactive", !active)
    })

    this.panelTargets.forEach((panel, i) => {
      if (i === index) {
        panel.removeAttribute("hidden")
      } else {
        panel.setAttribute("hidden", "")
      }
    })
  }
}
