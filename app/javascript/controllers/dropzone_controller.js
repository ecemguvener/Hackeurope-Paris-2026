import { Controller } from "@hotwired/stimulus"

// Adds drag-and-drop visual feedback to the upload area.
export default class extends Controller {
  static targets = ["input", "zone", "filename"]

  dragenter(event) {
    event.preventDefault()
    this.zoneTarget.classList.add("drop-zone-active")
  }

  dragover(event) {
    event.preventDefault()
    this.zoneTarget.classList.add("drop-zone-active")
  }

  dragleave(event) {
    event.preventDefault()
    this.zoneTarget.classList.remove("drop-zone-active")
  }

  drop(event) {
    event.preventDefault()
    this.zoneTarget.classList.remove("drop-zone-active")

    const files = event.dataTransfer.files
    if (files.length > 0) {
      this.inputTarget.files = files
      this.filenameTarget.textContent = files[0].name
    }
  }
}
