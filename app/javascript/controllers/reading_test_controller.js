import { Controller } from "@hotwired/stimulus"

// Hidden assessment telemetry (timer + typing behavior) for better profiling.
export default class extends Controller {
  static targets = ["time", "metrics", "retyped"]

  connect() {
    this.startedAt = null
    this.lastInputAt = null
    this.pauses = 0
    this.backspaces = 0
    this.edits = 0
    this.sessionStartedAt = Date.now()
    this.boundKeydown = this.onKeydown.bind(this)

    if (this.hasRetypedTarget) {
      this.retypedTarget.addEventListener("keydown", this.boundKeydown)
    }
  }

  disconnect() {
    if (this.hasRetypedTarget && this.boundKeydown) {
      this.retypedTarget.removeEventListener("keydown", this.boundKeydown)
    }
  }

  track() {
    const now = Date.now()
    this.ensureStarted(now)
    if (this.lastInputAt && now - this.lastInputAt > 1500) this.pauses += 1
    this.lastInputAt = now
    this.edits += 1
  }

  onKeydown(event) {
    this.ensureStarted(Date.now())
    if (event.key === "Backspace" || event.key === "Delete") this.backspaces += 1
  }

  ensureStarted(now) {
    this.startedAt ||= now
  }

  stamp() {
    const now = Date.now()
    this.ensureStarted(now)

    if (this.hasTimeTarget) {
      // Keep at least 1s so backend scoring never gets a weird zero.
      const seconds = Math.max(1, Math.round((now - this.startedAt) / 1000))
      this.timeTarget.value = seconds
    }

    if (this.hasMetricsTarget) {
      const metrics = {
        hidden_timer_seconds: Math.max(1, Math.round((now - this.sessionStartedAt) / 1000)),
        active_typing_seconds: Math.max(1, Math.round((now - this.startedAt) / 1000)),
        pauses: this.pauses,
        backspaces: this.backspaces,
        edits: this.edits
      }
      this.metricsTarget.value = JSON.stringify(metrics)
    }
  }
}
