import { Controller } from "@hotwired/stimulus"

// Tracks elapsed time for the reading assessment from page render to submit.
export default class extends Controller {
  static targets = ["time"]

  connect() {
    // Start timer as soon as the form is live.
    this.startedAt = Date.now()
  }

  stamp() {
    if (!this.hasTimeTarget) return
    // Keep at least 1s so backend scoring never gets a weird zero.
    const seconds = Math.max(1, Math.round((Date.now() - this.startedAt) / 1000))
    this.timeTarget.value = seconds
  }
}
