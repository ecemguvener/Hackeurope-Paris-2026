import { Controller } from "@hotwired/stimulus"

// Controls the audio player for text-to-speech output.
// Adjusts playback speed client-side via the HTML audio element's playbackRate.
//
//   data-controller="tts"
//   data-tts-speed-value="1.0"  (optional initial speed)
//
// Targets:
//   audio       — the <audio> element
//   speedLabel  — element showing current speed label (optional)
export default class extends Controller {
  static targets = ["audio", "speedLabel"]
  static values  = { speed: { type: Number, default: 1.0 } }

  connect() {
    this.updatePlaybackRate()
    this.updateSpeedLabel()
  }

  // Called by speed buttons via data-action="tts#setSpeed"
  // Reads the desired speed from data-tts-speed-param on the button.
  setSpeed(event) {
    this.speedValue = parseFloat(event.params.speed)
    this.updatePlaybackRate()
    this.updateSpeedLabel()

    // Visual feedback: highlight the active speed button
    this.element.querySelectorAll("[data-tts-speed-param]").forEach(btn => {
      const active = parseFloat(btn.dataset.ttsSpeedParam) === this.speedValue
      btn.classList.toggle("bg-indigo-100", active)
      btn.classList.toggle("border-indigo-400", active)
      btn.classList.toggle("text-indigo-700", active)
    })
  }

  updatePlaybackRate() {
    if (this.hasAudioTarget) {
      this.audioTarget.playbackRate = this.speedValue
    }
  }

  updateSpeedLabel() {
    if (this.hasSpeedLabelTarget) {
      const labels = { 0.7: "Slow", 1.0: "Normal", 1.3: "Fast" }
      this.speedLabelTarget.textContent = labels[this.speedValue] ?? `${this.speedValue}×`
    }
  }
}
