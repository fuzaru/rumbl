// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//
// If you have dependencies that try to import CSS, esbuild will generate a separate `app.css` file.
// To load it, simply add a second `<link>` to your `root.html.heex` file.

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html"
// Establish Phoenix Socket and LiveView configuration.
import {Socket} from "phoenix"
import {LiveSocket} from "phoenix_live_view"
import {hooks as colocatedHooks} from "phoenix-colocated/rumbl"
import topbar from "../vendor/topbar"

const VideoWatch = {
  mounted() {
    const videoId = this.el.dataset.videoId
    const userToken = this.el.dataset.userToken

    if (!videoId || !userToken) return

    this.videoSocket = new Socket("/socket", {params: {token: userToken}})
    this.videoSocket.connect()

    this.channel = this.videoSocket.channel(`video:${videoId}`, {})
    this.channel.on("new_annotation", (annotation) => this.renderAnnotation(annotation))

    this.channel
      .join()
      .receive("ok", (_resp) => {})
      .receive("error", (reason) => console.error("Join failed", reason))

    const form = document.getElementById("annotation-form")
    if (form) {
      this.onSubmit = (e) => {
        e.preventDefault()
        const bodyInput = document.getElementById("annotation-body")
        const timestampInput = document.getElementById("annotation-timestamp")
        const body = bodyInput?.value || ""
        const timestamp = timestampInput?.value?.trim() || ""
        const at = this.parseTimestamp(timestamp)

        if (body.trim() === "" || !timestampInput) return
        if (at === null) {
          timestampInput.setCustomValidity("Use m:ss or h:mm:ss")
          timestampInput.reportValidity()
          return
        }

        timestampInput.setCustomValidity("")

        this.channel.push("new_annotation", {body, at})
          .receive("ok", () => {
            bodyInput.value = ""
            timestampInput.value = ""
          })
          .receive("error", (err) => console.error("Failed to post annotation", err))
      }

      form.addEventListener("submit", this.onSubmit)
    }

    this.onTimestampClick = (e) => {
      const target = e.target.closest(".annotation-timestamp")
      if (!target) return

      e.preventDefault()
      const at = parseInt(target.dataset.at || "0", 10) || 0
      this.seekTo(at)
    }

    this.el.addEventListener("click", this.onTimestampClick)
  },

  destroyed() {
    const form = document.getElementById("annotation-form")
    if (form && this.onSubmit) {
      form.removeEventListener("submit", this.onSubmit)
    }

    if (this.onTimestampClick) {
      this.el.removeEventListener("click", this.onTimestampClick)
    }

    if (this.channel) this.channel.leave()
    if (this.videoSocket) this.videoSocket.disconnect()
  },

  renderAnnotation(annotation) {
    const container = document.getElementById("annotations")
    const noAnnotations = document.getElementById("no-annotations")

    if (!container) return

    if (noAnnotations) {
      noAnnotations.remove()
    }

    const div = document.createElement("div")
    div.className = "annotation p-3 bg-gray-50 rounded-lg"
    div.dataset.at = annotation.at
    div.innerHTML = `
      <button type="button" class="annotation-timestamp text-xs font-mono text-brand hover:underline" data-at="${annotation.at}">
        ${this.formatTime(annotation.at)}
      </button>
      <p class="mt-1 text-gray-600">${annotation.body}</p>
    `

    const siblings = [...container.querySelectorAll(".annotation")]
    const nextElement = siblings.find((item) => Number(item.dataset.at || "0") > annotation.at)

    if (nextElement) {
      container.insertBefore(div, nextElement)
    } else {
      container.appendChild(div)
    }

    div.scrollIntoView({behavior: "smooth", block: "nearest"})
  },

  formatTime(ms) {
    const totalSeconds = Math.floor(ms / 1000)
    const minutes = Math.floor(totalSeconds / 60)
    const seconds = totalSeconds % 60
    return `${minutes}:${seconds.toString().padStart(2, "0")}`
  },

  parseTimestamp(timestamp) {
    if (!timestamp) return null

    const parts = timestamp.split(":")
    const allNumeric = parts.every((part) => /^\d+$/.test(part))
    if (!allNumeric) return null

    if (parts.length === 2) {
      const minutes = Number(parts[0])
      const seconds = Number(parts[1])

      if (seconds >= 60) return null

      return (minutes * 60 + seconds) * 1000
    }

    if (parts.length === 3) {
      const hours = Number(parts[0])
      const minutes = Number(parts[1])
      const seconds = Number(parts[2])

      if (minutes >= 60 || seconds >= 60) return null

      return (hours * 3600 + minutes * 60 + seconds) * 1000
    }

    return null
  },

  seekTo(milliseconds) {
    const iframe = document.getElementById("video-player")
    if (!iframe) return

    const startSeconds = Math.floor(milliseconds / 1000)
    const url = new URL(iframe.src, window.location.origin)
    url.searchParams.set("start", startSeconds.toString())
    url.searchParams.set("autoplay", "1")
    iframe.src = url.toString()
  }
}

const FocusHintDisplayName = {
  mounted() {
    this.input = this.el.querySelector("#register-display-name")
    this.hint = this.el.querySelector("#display-name-help")

    if (!this.input || !this.hint) return

    this.onFocus = () => this.hint.classList.add("is-visible")
    this.onBlur = () => this.hint.classList.remove("is-visible")

    this.input.addEventListener("focus", this.onFocus)
    this.input.addEventListener("blur", this.onBlur)
  },

  destroyed() {
    if (this.input && this.onFocus) {
      this.input.removeEventListener("focus", this.onFocus)
    }

    if (this.input && this.onBlur) {
      this.input.removeEventListener("blur", this.onBlur)
    }
  }
}

const AutoGrowTextarea = {
  mounted() {
    this.baseHeight = this.el.offsetHeight

    this.resize = () => {
      this.el.style.height = "auto"
      this.el.style.height = `${Math.max(this.el.scrollHeight, this.baseHeight)}px`
    }

    this.el.addEventListener("input", this.resize)
    this.resize()
  },

  updated() {
    if (this.resize) this.resize()
  },

  destroyed() {
    if (this.resize) {
      this.el.removeEventListener("input", this.resize)
    }
  }
}

const csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
const liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: {_csrf_token: csrfToken},
  hooks: {
    ...colocatedHooks,
    VideoWatch,
    FocusHintDisplayName,
    AutoGrowTextarea,
  },
})

// Show progress bar on live navigation and form submits
topbar.config({barColors: {0: "#29d"}, shadowColor: "rgba(0, 0, 0, .3)"})
window.addEventListener("phx:page-loading-start", _info => topbar.show(300))
window.addEventListener("phx:page-loading-stop", _info => topbar.hide())

const authRoute = (path) => path === "/sessions/new" || path === "/users/new"

window.addEventListener("phx:page-loading-start", (info) => {
  const target = info?.detail?.to
  const current = window.location.pathname

  if (authRoute(current) && (!target || authRoute(target))) {
    document.documentElement.classList.add("auth-switching")
  }
})

window.addEventListener("phx:page-loading-stop", () => {
  document.documentElement.classList.remove("auth-switching")
})

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket

// The lines below enable quality of life phoenix_live_reload
// development features:
//
//     1. stream server logs to the browser console
//     2. click on elements to jump to their definitions in your code editor
//
if (process.env.NODE_ENV === "development") {
  window.addEventListener("phx:live_reload:attached", ({detail: reloader}) => {
    // Enable server log streaming to client.
    // Disable with reloader.disableServerLogs()
    reloader.enableServerLogs()

    // Open configured PLUG_EDITOR at file:line of the clicked element's HEEx component
    //
    //   * click with "c" key pressed to open at caller location
    //   * click with "d" key pressed to open at function component definition location
    let keyDown
    window.addEventListener("keydown", e => keyDown = e.key)
    window.addEventListener("keyup", _e => keyDown = null)
    window.addEventListener("click", e => {
      if(keyDown === "c"){
        e.preventDefault()
        e.stopImmediatePropagation()
        reloader.openEditorAtCaller(e.target)
      } else if(keyDown === "d"){
        e.preventDefault()
        e.stopImmediatePropagation()
        reloader.openEditorAtDef(e.target)
      }
    }, true)

    window.liveReloader = reloader
  })
}
