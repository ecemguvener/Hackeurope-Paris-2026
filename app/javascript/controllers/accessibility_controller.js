import { Controller } from "@hotwired/stimulus"

// Manages global accessibility preferences: theme, font, size, overlay, focus mode
// Persists to localStorage for instant reload; async-PATCHes to server profile.
export default class extends Controller {
  static targets = ["panel", "darkModeBtn", "contrastBtn", "readingModeBtn", "focusModeBtn"]

  connect() {
    this.applyStoredPreferences()
  }

  // ── Panel toggle ────────────────────────────────────────
  togglePanel() {
    if (this.hasPanelTarget) {
      this.panelTarget.classList.toggle("hidden")
    }
  }

  // ── Theme (dark mode) ───────────────────────────────────
  toggleDarkMode() {
    const html = document.documentElement
    const current = html.getAttribute("data-theme")
    const next = current === "dark" ? "" : "dark"
    this._setAttr("data-theme", next, "qlarity-theme")
    if (this.hasDarkModeBtnTarget) {
      this.darkModeBtnTarget.textContent = next === "dark" ? "On" : "Off"
    }
    // If turning on dark, turn off high contrast
    if (next === "dark") {
      this._setAttr("data-contrast", "", "qlarity-contrast")
      if (this.hasContrastBtnTarget) this.contrastBtnTarget.textContent = "Normal"
    }
    this._persist({ theme: next || "light" })
  }

  // ── High Contrast ───────────────────────────────────────
  toggleContrast() {
    const html = document.documentElement
    const current = html.getAttribute("data-contrast")
    const next = current === "high" ? "" : "high"
    this._setAttr("data-contrast", next, "qlarity-contrast")
    if (this.hasContrastBtnTarget) {
      this.contrastBtnTarget.textContent = next === "high" ? "High" : "Normal"
    }
    // If turning on high contrast, turn off dark mode
    if (next === "high") {
      this._setAttr("data-theme", "", "qlarity-theme")
      if (this.hasDarkModeBtnTarget) this.darkModeBtnTarget.textContent = "Off"
    }
    this._persist({ contrast: next || "normal" })
  }

  // ── Font Family ─────────────────────────────────────────
  setFont(event) {
    const font = event.params.font
    const body = document.body
    ;["dys-font-sans", "dys-font-serif", "dys-font-mono", "dys-font-open"].forEach(c => body.classList.remove(c))
    if (font) body.classList.add(`dys-font-${font}`)
    localStorage.setItem("qlarity-font", font || "")
    this._highlightActive("font", font)
    this._persist({ font_preference: font })
  }

  // ── Text Size ───────────────────────────────────────────
  setSize(event) {
    const size = event.params.size
    const body = document.body
    ;["dys-size-normal", "dys-size-large", "dys-size-xlarge"].forEach(c => body.classList.remove(c))
    if (size) body.classList.add(`dys-size-${size}`)
    localStorage.setItem("qlarity-text-size", size || "")
    this._highlightActive("size", size)
    this._persist({ text_size: size })
  }

  // ── Background Overlay ──────────────────────────────────
  setOverlay(event) {
    const overlay = event.params.overlay
    const value = overlay === "none" ? "" : overlay
    this._setAttr("data-overlay", value, "qlarity-overlay")
    this._highlightActive("overlay", overlay)
    this._persist({ overlay_color: value || "none" })
  }

  // ── Reading Mode (standard / strong) ────────────────────
  toggleReadingMode() {
    const body = document.body
    const isStrong = body.classList.contains("dys-mode-strong")
    body.classList.remove("dys-mode-standard", "dys-mode-strong")
    const next = isStrong ? "standard" : "strong"
    body.classList.add(`dys-mode-${next}`)
    localStorage.setItem("qlarity-reading-mode", next)
    if (this.hasReadingModeBtnTarget) {
      this.readingModeBtnTarget.textContent = next === "strong" ? "Strong" : "Standard"
    }
    this._persist({ reading_mode: next })
  }

  // ── Focus Mode ──────────────────────────────────────────
  toggleFocusMode() {
    const body = document.body
    const isOn = body.classList.contains("focus-mode")
    body.classList.toggle("focus-mode")
    localStorage.setItem("qlarity-focus-mode", !isOn)
    if (this.hasFocusModeBtnTarget) {
      this.focusModeBtnTarget.textContent = isOn ? "Off" : "On"
    }
    this._persist({ focus_mode: !isOn })
  }

  // ── Reset ───────────────────────────────────────────────
  resetAll() {
    const keys = ["qlarity-theme", "qlarity-contrast", "qlarity-overlay", "qlarity-font",
                   "qlarity-text-size", "qlarity-reading-mode", "qlarity-focus-mode"]
    keys.forEach(k => localStorage.removeItem(k))

    const html = document.documentElement
    html.removeAttribute("data-theme")
    html.removeAttribute("data-contrast")
    html.removeAttribute("data-overlay")

    const body = document.body
    ;["dys-font-sans", "dys-font-serif", "dys-font-mono", "dys-font-open",
      "dys-size-normal", "dys-size-large", "dys-size-xlarge",
      "dys-mode-standard", "dys-mode-strong", "focus-mode"].forEach(c => body.classList.remove(c))

    // Reset button labels
    if (this.hasDarkModeBtnTarget) this.darkModeBtnTarget.textContent = "Off"
    if (this.hasContrastBtnTarget) this.contrastBtnTarget.textContent = "Normal"
    if (this.hasReadingModeBtnTarget) this.readingModeBtnTarget.textContent = "Standard"
    if (this.hasFocusModeBtnTarget) this.focusModeBtnTarget.textContent = "Off"

    this._persist({ theme: "light", contrast: "normal", overlay_color: "none",
                    font_preference: "", text_size: "normal", reading_mode: "standard", focus_mode: false })
  }

  // ── Internal helpers ────────────────────────────────────
  applyStoredPreferences() {
    const theme = localStorage.getItem("qlarity-theme")
    const contrast = localStorage.getItem("qlarity-contrast")
    const overlay = localStorage.getItem("qlarity-overlay")
    const font = localStorage.getItem("qlarity-font")
    const size = localStorage.getItem("qlarity-text-size")
    const readingMode = localStorage.getItem("qlarity-reading-mode")
    const focusMode = localStorage.getItem("qlarity-focus-mode")

    const html = document.documentElement
    if (theme) html.setAttribute("data-theme", theme)
    if (contrast) html.setAttribute("data-contrast", contrast)
    if (overlay) html.setAttribute("data-overlay", overlay)

    const body = document.body
    if (font) {
      ;["dys-font-sans", "dys-font-serif", "dys-font-mono", "dys-font-open"].forEach(c => body.classList.remove(c))
      body.classList.add(`dys-font-${font}`)
    }
    if (size) {
      ;["dys-size-normal", "dys-size-large", "dys-size-xlarge"].forEach(c => body.classList.remove(c))
      body.classList.add(`dys-size-${size}`)
    }
    if (readingMode) {
      body.classList.remove("dys-mode-standard", "dys-mode-strong")
      body.classList.add(`dys-mode-${readingMode}`)
    }
    if (focusMode === "true") body.classList.add("focus-mode")

    // Sync button labels
    if (this.hasDarkModeBtnTarget) this.darkModeBtnTarget.textContent = theme === "dark" ? "On" : "Off"
    if (this.hasContrastBtnTarget) this.contrastBtnTarget.textContent = contrast === "high" ? "High" : "Normal"
    if (this.hasReadingModeBtnTarget) this.readingModeBtnTarget.textContent = readingMode === "strong" ? "Strong" : "Standard"
    if (this.hasFocusModeBtnTarget) this.focusModeBtnTarget.textContent = focusMode === "true" ? "On" : "Off"

    // Highlight active buttons
    this._highlightActive("font", font)
    this._highlightActive("size", size)
    this._highlightActive("overlay", overlay || "none")
  }

  _setAttr(attr, value, storageKey) {
    const html = document.documentElement
    if (value) {
      html.setAttribute(attr, value)
    } else {
      html.removeAttribute(attr)
    }
    localStorage.setItem(storageKey, value || "")
  }

  _highlightActive(type, activeKey) {
    const buttons = document.querySelectorAll(`.accessibility-${type}-btn`)
    buttons.forEach(btn => {
      const key = btn.getAttribute(`data-${type}-key`)
      if (key === activeKey) {
        btn.style.borderColor = "var(--color-accent, #6366f1)"
        btn.style.fontWeight = "700"
      } else {
        btn.style.borderColor = "var(--color-border)"
        btn.style.fontWeight = ""
      }
    })
  }

  _persist(data) {
    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content
    if (!csrfToken) return

    fetch("/api/v1/profile", {
      method: "PATCH",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": csrfToken
      },
      body: JSON.stringify({ profile: data })
    }).catch(() => {}) // fire-and-forget
  }
}
