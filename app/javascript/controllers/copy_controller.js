import { Controller } from "@hotwired/stimulus"

// Copies the innerText of a target element to the clipboard.
// Shows brief visual feedback after copying.
//
//   data-controller="copy"
//
// Targets:
//   source   — element whose innerText will be copied
//   feedback — element whose text changes briefly to confirm the copy
export default class extends Controller {
  static targets = ["source", "feedback"]

  copy() {
    if (!this.hasSourceTarget) return

    const text = this.sourceTarget.innerText.trim()

    const done = () => {
      if (!this.hasFeedbackTarget) return

      const original = this.feedbackTarget.dataset.originalLabel
        || this.feedbackTarget.textContent
      // Store original on first call
      if (!this.feedbackTarget.dataset.originalLabel) {
        this.feedbackTarget.dataset.originalLabel = original
      }

      this.feedbackTarget.textContent = "Copied!"
      setTimeout(() => {
        this.feedbackTarget.textContent = this.feedbackTarget.dataset.originalLabel
      }, 2000)
    }

    if (navigator.clipboard) {
      navigator.clipboard.writeText(text).then(done).catch(() => this.#legacyCopy(text, done))
    } else {
      this.#legacyCopy(text, done)
    }
  }

  #legacyCopy(text, callback) {
    const el = document.createElement("textarea")
    el.value = text
    el.style.cssText = "position:fixed;opacity:0;top:0;left:0;pointer-events:none"
    document.body.appendChild(el)
    el.focus()
    el.select()
    try { document.execCommand("copy") } catch (_) { /* silent */ }
    document.body.removeChild(el)
    callback()
  }
}
