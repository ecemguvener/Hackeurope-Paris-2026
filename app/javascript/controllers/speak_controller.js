import { Controller } from "@hotwired/stimulus"

// Browser-native text-to-speech using the Web Speech API.
// Reads aloud the text content of the element marked as `data-speak-target="content"`.
//
//   data-controller="speak"
//   data-speak-target="content"  — the element whose innerText will be read
//   data-action="speak#toggle"   — on the play/pause button
//   data-speak-target="button"   — the button (label will update)
//
export default class extends Controller {
  static targets = ["content", "button"]

  connect() {
    this.speaking = false
    this.utterance = null
  }

  disconnect() {
    this.stop()
  }

  toggle() {
    if (this.speaking) {
      this.stop()
    } else {
      this.play()
    }
  }

  play() {
    if (!window.speechSynthesis) return

    // Cancel any ongoing speech first
    window.speechSynthesis.cancel()

    const text = this.hasContentTarget
      ? this.contentTarget.innerText
      : this.element.innerText

    if (!text.trim()) return

    this.utterance = new SpeechSynthesisUtterance(text)
    this.utterance.rate = 0.9
    this.utterance.pitch = 1.0

    this.utterance.onend = () => this.resetButton()
    this.utterance.onerror = () => this.resetButton()

    window.speechSynthesis.speak(this.utterance)
    this.speaking = true
    this.updateButton("Stop Listening")
  }

  stop() {
    window.speechSynthesis.cancel()
    this.resetButton()
  }

  resetButton() {
    this.speaking = false
    this.utterance = null
    this.updateButton("Listen")
  }

  updateButton(label) {
    if (this.hasButtonTarget) {
      this.buttonTarget.textContent = label
    }
  }
}
