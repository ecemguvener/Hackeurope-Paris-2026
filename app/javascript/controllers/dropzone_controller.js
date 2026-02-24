import { Controller } from "@hotwired/stimulus"

// Adds drag-and-drop visual feedback to the upload area.
export default class extends Controller {
  static targets = ["input", "zone", "filename", "error"]

  static MAX_FILE_SIZE_BYTES = 10 * 1024 * 1024

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
      this.selectFile(files[0], files)
    }
  }

  change(event) {
    const file = event.target.files?.[0]
    if (!file) {
      this.updateFilename("")
      this.clearError()
      return
    }

    this.selectFile(file)
  }

  updateFilename(name) {
    this.filenameTarget.textContent = name
  }

  selectFile(file, filesList = null) {
    if (file.size > this.constructor.MAX_FILE_SIZE_BYTES) {
      this.inputTarget.value = ""
      this.updateFilename("")
      this.showError("File is too large. Please upload a file up to 10MB.")
      return
    }

    if (filesList) {
      this.inputTarget.files = filesList
    }

    this.clearError()
    this.updateFilename(file.name)
  }

  showError(message) {
    this.errorTarget.textContent = message
    this.errorTarget.classList.remove("hidden")
  }

  clearError() {
    this.errorTarget.textContent = ""
    this.errorTarget.classList.add("hidden")
  }
}
