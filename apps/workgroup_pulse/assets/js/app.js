// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html"
// Establish Phoenix Socket and LiveView configuration.
import {Socket} from "phoenix"
import {LiveSocket} from "phoenix_live_view"
import topbar from "../vendor/topbar"

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")

// LiveView hooks for custom JavaScript functionality
let Hooks = {}

// Facilitator timer hook for smooth client-side countdown
Hooks.FacilitatorTimer = {
  mounted() {
    this.remaining = parseInt(this.el.dataset.remaining)
    this.total = parseInt(this.el.dataset.total)
    this.threshold = parseInt(this.el.dataset.threshold)

    this.timeDisplay = this.el.querySelector('.font-mono')

    // Start client-side countdown for smooth updates
    this.startCountdown()

    // Listen for server updates to sync
    this.handleEvent("timer_sync", ({remaining}) => {
      this.remaining = remaining
      this.updateDisplay()
    })
  },

  updated() {
    // Re-read values when the element is updated by the server
    const newRemaining = parseInt(this.el.dataset.remaining)
    const newTotal = parseInt(this.el.dataset.total)
    const newThreshold = parseInt(this.el.dataset.threshold)

    // Only update if values changed significantly (more than 2 second drift)
    if (Math.abs(this.remaining - newRemaining) > 2) {
      this.remaining = newRemaining
    }
    this.total = newTotal
    this.threshold = newThreshold
    this.updateDisplay()
  },

  destroyed() {
    this.stopCountdown()
  },

  startCountdown() {
    this.stopCountdown()
    this.interval = setInterval(() => {
      if (this.remaining > 0) {
        this.remaining--
        this.updateDisplay()
      } else {
        this.stopCountdown()
      }
    }, 1000)
  },

  stopCountdown() {
    if (this.interval) {
      clearInterval(this.interval)
      this.interval = null
    }
  },

  updateDisplay() {
    if (!this.timeDisplay) return

    this.timeDisplay.textContent = this.formatTime(this.remaining)

    // Update warning state
    const isWarning = this.remaining <= this.threshold
    const container = this.el

    if (isWarning) {
      container.classList.remove('bg-gray-800/90', 'border-gray-600')
      container.classList.add('bg-red-900/90', 'border-red-600')
      this.timeDisplay.classList.remove('text-white')
      this.timeDisplay.classList.add('text-red-400')
    } else {
      container.classList.remove('bg-red-900/90', 'border-red-600')
      container.classList.add('bg-gray-800/90', 'border-gray-600')
      this.timeDisplay.classList.remove('text-red-400')
      this.timeDisplay.classList.add('text-white')
    }
  },

  formatTime(seconds) {
    if (seconds < 0) return "0:00"
    const mins = Math.floor(seconds / 60)
    const secs = seconds % 60
    return `${mins}:${secs.toString().padStart(2, '0')}`
  }
}

// File download hook for export functionality
Hooks.FileDownload = {
  mounted() {
    this.handleEvent("download", ({filename, content_type, data}) => {
      // Create a blob from the data
      const blob = new Blob([data], { type: content_type })
      const url = URL.createObjectURL(blob)

      // Create a temporary link and trigger download
      const link = document.createElement("a")
      link.href = url
      link.download = filename
      document.body.appendChild(link)
      link.click()
      document.body.removeChild(link)

      // Clean up the URL
      URL.revokeObjectURL(url)
    })
  }
}

// Duration picker hook for client-side increment/decrement
Hooks.DurationPicker = {
  mounted() {
    this.duration = parseInt(this.el.dataset.duration) || 120
    this.min = 30
    this.max = 480

    this.formattedDisplay = this.el.querySelector('[data-display="formatted"]')
    this.minutesDisplay = this.el.querySelector('[data-display="minutes"]')
    this.hiddenInput = this.el.querySelector('[data-input="duration"]')

    this.decrementBtn = this.el.querySelector('[data-action="decrement"]')
    this.incrementBtn = this.el.querySelector('[data-action="increment"]')

    this.decrementHandler = () => {
      this.duration = Math.max(this.duration - 5, this.min)
      this.updateDisplay()
    }

    this.incrementHandler = () => {
      this.duration = Math.min(this.duration + 5, this.max)
      this.updateDisplay()
    }

    this.decrementBtn.addEventListener("click", this.decrementHandler)
    this.incrementBtn.addEventListener("click", this.incrementHandler)
  },

  destroyed() {
    if (this.decrementBtn) {
      this.decrementBtn.removeEventListener("click", this.decrementHandler)
    }
    if (this.incrementBtn) {
      this.incrementBtn.removeEventListener("click", this.incrementHandler)
    }
  },

  updateDisplay() {
    const hours = Math.floor(this.duration / 60)
    const mins = this.duration % 60

    let formatted
    if (hours === 0) {
      formatted = `${mins} min`
    } else if (mins === 0) {
      formatted = `${hours} hr`
    } else {
      formatted = `${hours} hr ${mins} min`
    }

    this.formattedDisplay.innerText = formatted
    this.minutesDisplay.innerText = this.duration
    this.hiddenInput.value = this.duration
  }
}

// PostHog analytics hook for custom event tracking from LiveView
// Usage in LiveView: push_event(socket, "posthog:capture", %{event: "event_name", properties: %{}})
Hooks.PostHogTracker = {
  mounted() {
    this.handleEvent("posthog:capture", ({event, properties}) => {
      if (window.posthog) {
        window.posthog.capture(event, properties || {})
      }
    })

    this.handleEvent("posthog:identify", ({distinct_id, properties}) => {
      if (window.posthog) {
        window.posthog.identify(distinct_id, properties || {})
      }
    })
  }
}

// Sheet stack — CSS-driven coverflow positioning (no scroll container)
//
// Architecture: the server (LiveView) is the sole authority on stack
// position via data-index. The hook reads it on every updated() call
// and applies coverflow transforms. No internal state, nothing to fight
// LiveView DOM patches.
Hooks.SheetStack = {
  mounted() {
    this._applyPositions()

    // Event delegation: click inactive slide to navigate
    this.el.addEventListener('click', (e) => {
      const slide = e.target.closest('[data-slide]')
      if (!slide || slide.classList.contains('stack-active')) return
      this.pushEvent('carousel_navigate', {
        index: parseInt(slide.dataset.slide),
        carousel: this.el.id
      })
    })
  },

  updated() {
    this._applyPositions()
  },

  // No destroyed() needed — event delegation on this.el auto-removed

  _applyPositions() {
    const active = parseInt(this.el.dataset.index) || 0
    const slides = this.el.querySelectorAll(':scope > [data-slide]')

    const ROTATE  = 12    // degrees per slide of distance
    const MAX_ROT = 20    // cap rotation
    const SCALE   = 0.06  // scale reduction per slide
    const MIN_SC  = 0.8
    const OVERLAP = 200   // px each slide tucks toward centre
    const OPAC    = 0.35  // opacity reduction per slide
    const MIN_OP  = 0.25

    slides.forEach((slide) => {
      const i = parseInt(slide.dataset.slide)
      const dist = i - active
      const absDist = Math.abs(dist)

      if (dist === 0) {
        // Active: no transform, fully interactive
        slide.style.transform = ''
        slide.style.opacity = '1'
        slide.style.zIndex = '100'
        slide.classList.add('stack-active')
        slide.classList.remove('stack-inactive')
      } else {
        // Inactive: coverflow visual, click-to-navigate
        const sc = Math.max(MIN_SC, 1 - absDist * SCALE)
        const ry = -Math.max(-MAX_ROT, Math.min(MAX_ROT, dist * ROTATE))
        const tx = -dist * OVERLAP
        const op = Math.max(MIN_OP, 1 - absDist * OPAC)
        const z  = 100 - Math.round(absDist * 10)

        slide.style.transform =
          `translateX(${tx}px) perspective(800px) rotateY(${ry}deg) scale(${sc})`
        slide.style.opacity = op
        slide.style.zIndex = z
        slide.classList.remove('stack-active')
        slide.classList.add('stack-inactive')
      }
    })
  }
}

let liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: {_csrf_token: csrfToken},
  hooks: Hooks
})

// Show progress bar on live navigation and form submits
topbar.config({barColors: {0: "#29d"}, shadowColor: "rgba(0, 0, 0, .3)"})
window.addEventListener("phx:page-loading-start", _info => topbar.show(300))
window.addEventListener("phx:page-loading-stop", _info => topbar.hide())

// Copy to clipboard event handler
window.addEventListener("phx:copy", (event) => {
  const input = event.target
  if (input && input.value) {
    navigator.clipboard.writeText(input.value).then(() => {
      // Show brief feedback by changing button text
      const button = input.parentElement.querySelector("button")
      if (button) {
        const originalText = button.innerText
        button.innerText = "Copied!"
        setTimeout(() => { button.innerText = originalText }, 2000)
      }
    })
  }
})

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket
