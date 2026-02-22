import { Controller } from "@hotwired/stimulus"

// Tracks elapsed time for the reading assessment from page render to submit.
export default class extends Controller {
  static targets = ["time"]

  connect() {
    this.startedAt = Date.now()
  }

  stamp() {
    if (!this.hasTimeTarget) return
    const seconds = Math.max(1, Math.round((Date.now() - this.startedAt) / 1000))
    this.timeTarget.value = seconds
  }
}

