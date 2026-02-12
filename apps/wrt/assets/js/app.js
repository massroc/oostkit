// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html"

// Establish Phoenix Socket and LiveView configuration.
// No LiveView for now, but keeping the import structure for future use.

// Show progress bar on live navigation and form submits
import topbar from "../vendor/topbar"
topbar.config({barColors: {0: "#7245F4"}, shadowColor: "rgba(0, 0, 0, .3)"})
window.addEventListener("phx:page-loading-start", _info => topbar.show(300))
window.addEventListener("phx:page-loading-stop", _info => topbar.hide())

// Nomination form — dynamic add/remove entries
document.addEventListener("DOMContentLoaded", () => {
  const form = document.getElementById("nomination-form")
  if (!form) return

  const container = document.getElementById("nominations-container")
  const template = document.getElementById("nomination-template")
  const addBtn = document.getElementById("add-nomination")

  function nextIndex() {
    const entries = container.querySelectorAll(".nomination-entry")
    let max = -1
    entries.forEach(e => {
      const idx = parseInt(e.dataset.index, 10)
      if (idx > max) max = idx
    })
    return max + 1
  }

  function updateHeadings() {
    container.querySelectorAll(".nomination-heading").forEach((h, i) => {
      h.textContent = `Nomination ${i + 1}`
    })
  }

  addBtn.addEventListener("click", () => {
    const idx = nextIndex()
    const html = template.innerHTML
      .replace(/__INDEX__/g, idx)
      .replace(/__DISPLAY__/g, idx + 1)
    const wrapper = document.createElement("div")
    wrapper.innerHTML = html.trim()
    const entry = wrapper.firstChild
    container.appendChild(entry)
    updateHeadings()
    entry.querySelector("input[type='text']").focus()
  })

  container.addEventListener("click", (e) => {
    const btn = e.target.closest(".remove-nomination")
    if (!btn) return
    const entry = btn.closest(".nomination-entry")
    if (container.querySelectorAll(".nomination-entry").length <= 1) return
    entry.remove()
    updateHeadings()
  })
})
