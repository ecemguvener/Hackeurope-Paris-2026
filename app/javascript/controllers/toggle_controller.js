import { Controller } from "@hotwired/stimulus"

// Toggles between original and transformed content on a card.
// Client-side only — no server round-trip (NFR4).
export default class extends Controller {
  static targets = ["original", "transformed", "button"]

  connect() {
    this.showingOriginal = false
  }

  toggle() {
    this.showingOriginal = !this.showingOriginal

    if (this.showingOriginal) {
      this.originalTarget.classList.remove("hidden")
      this.transformedTarget.classList.add("hidden")
      this.buttonTarget.textContent = "Show Transformed"
    } else {
      this.originalTarget.classList.add("hidden")
      this.transformedTarget.classList.remove("hidden")
      this.buttonTarget.textContent = "Show Original"
    }
  }
}
