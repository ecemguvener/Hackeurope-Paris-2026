import { Controller } from "@hotwired/stimulus"

// Toggles "Reading Mode" by adding/removing a CSS class on <body>.
// Persists the preference in localStorage so it survives page navigations.
//
//   data-controller="reading-mode"
//   data-action="click->reading-mode#toggle"
//   aria-pressed="false"
//
// Targets:
//   label — text label inside the button (updated on toggle)
export default class extends Controller {
  static targets = ["label"]

  connect() {
    if (localStorage.getItem("qlarity-reading-mode") === "on") {
      this.#apply(true)
    }
  }

  toggle() {
    const active = document.body.classList.contains("reading-mode")
    this.#apply(!active)
  }

  #apply(on) {
    document.body.classList.toggle("reading-mode", on)
    localStorage.setItem("qlarity-reading-mode", on ? "on" : "off")
    this.element.setAttribute("aria-pressed", String(on))
    if (this.hasLabelTarget) {
      this.labelTarget.textContent = on ? "Exit Reading Mode" : "Reading Mode"
    }
  }
}
