import { Controller } from "@hotwired/stimulus"

// Toggles between original and transformed content on a card.
// Client-side only — no server round-trip (NFR4).
export default class extends Controller {
  static targets = ["original", "transformed", "button"]

  connect() {
    this.showingOriginal = false
    // Set up transition styles
    this.originalTarget.style.transition = "opacity 150ms ease, max-height 150ms ease"
    this.transformedTarget.style.transition = "opacity 150ms ease, max-height 150ms ease"
    this.originalTarget.style.overflow = "hidden"
    this.transformedTarget.style.overflow = "hidden"
  }

  toggle() {
    this.showingOriginal = !this.showingOriginal

    if (this.showingOriginal) {
      // Fade out transformed
      this.transformedTarget.style.opacity = "0"
      setTimeout(() => {
        this.transformedTarget.classList.add("hidden")
        this.originalTarget.classList.remove("hidden")
        this.originalTarget.style.opacity = "0"
        // Trigger reflow then fade in
        requestAnimationFrame(() => {
          this.originalTarget.style.opacity = "1"
        })
      }, 150)
      this.buttonTarget.textContent = "Show Transformed"
    } else {
      // Fade out original
      this.originalTarget.style.opacity = "0"
      setTimeout(() => {
        this.originalTarget.classList.add("hidden")
        this.transformedTarget.classList.remove("hidden")
        this.transformedTarget.style.opacity = "0"
        requestAnimationFrame(() => {
          this.transformedTarget.style.opacity = "1"
        })
      }, 150)
      this.buttonTarget.textContent = "Show Original"
    }
  }
}
