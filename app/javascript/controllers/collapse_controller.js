import { Controller } from "@hotwired/stimulus"
import { Turbo } from "@hotwired/turbo-rails"

// Animates the "Pick This Version" selection on the results page.
// The selected card scales up briefly while sibling cards fade and shrink out,
// then navigates via Turbo after the animation completes.
export default class extends Controller {
  static targets = ["card"]
  static values = { duration: { type: Number, default: 500 } }

  select(event) {
    event.preventDefault()

    const clickedCard = event.target.closest("[data-collapse-target='card']")
    if (!clickedCard) return

    const link = event.target.closest("a")
    if (!link) return

    // Animate sibling cards out
    this.cardTargets.forEach((card) => {
      if (card === clickedCard) {
        card.style.transition = `transform ${this.durationValue}ms ease, box-shadow ${this.durationValue}ms ease`
        card.style.transform = "scale(1.05)"
        card.style.boxShadow = "0 20px 40px rgba(99, 102, 241, 0.3)"
        card.style.zIndex = "10"
      } else {
        card.style.transition = `opacity ${this.durationValue}ms ease, transform ${this.durationValue}ms ease`
        card.style.opacity = "0"
        card.style.transform = "scale(0.9)"
        card.style.pointerEvents = "none"
      }
    })

    // After animation, let Turbo handle the navigation
    setTimeout(() => {
      // Remove the event handler temporarily so Turbo processes the click naturally
      link.removeAttribute("data-action")
      link.click()
    }, this.durationValue)
  }
}
