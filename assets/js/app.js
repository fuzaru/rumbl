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

const YouTubeSeek = {
  mounted() {
    this.lastPushedSecond = -1
    this.lastPushedDuration = -1
    this.player = null

    this.pushMetrics = (seconds, durationSeconds) => {
      const safeSeconds = Number.isFinite(seconds) ? Math.max(0, Math.floor(seconds)) : 0
      const safeDuration = Number.isFinite(durationSeconds) ? Math.max(0, Math.floor(durationSeconds)) : 0

      if (safeSeconds === this.lastPushedSecond && safeDuration === this.lastPushedDuration) return

      this.lastPushedSecond = safeSeconds
      this.lastPushedDuration = safeDuration
      this.pushEvent("video_player_metrics", {seconds: safeSeconds, duration_seconds: safeDuration})
    }

    this.pollPlayer = () => {
      if (!this.player || typeof this.player.getCurrentTime !== "function") return
      this.pushMetrics(this.player.getCurrentTime(), this.player.getDuration())
    }

    this.ensurePlayer = () => {
      if (window.YT && window.YT.Player) {
        this.player = new window.YT.Player(this.el.id, {
          events: {
            onReady: () => {
              this.pollPlayer()
              this.pollInterval = window.setInterval(this.pollPlayer, 1000)
            },
            onStateChange: () => this.pollPlayer(),
          },
        })
        return
      }

      if (!window.__rumblYouTubeApiPromise) {
        window.__rumblYouTubeApiPromise = new Promise((resolve) => {
          const previousReady = window.onYouTubeIframeAPIReady
          window.onYouTubeIframeAPIReady = () => {
            if (typeof previousReady === "function") previousReady()
            resolve()
          }

          const script = document.createElement("script")
          script.src = "https://www.youtube.com/iframe_api"
          script.async = true
          document.head.appendChild(script)
        })
      }

      window.__rumblYouTubeApiPromise.then(() => this.ensurePlayer())
    }

    this.ensurePlayer()

    this.handleEvent("seek_video", ({seconds}) => {
      if (!Number.isFinite(seconds)) return

      const targetSeconds = Math.max(0, Math.floor(seconds))
      if (!this.player || typeof this.player.seekTo !== "function") return

      this.player.seekTo(targetSeconds, true)
      this.player.playVideo()

      this.pushMetrics(targetSeconds, this.lastPushedDuration)
    })
  },
  destroyed() {
    if (this.pollInterval) {
      window.clearInterval(this.pollInterval)
    }

    if (this.player && typeof this.player.destroy === "function") {
      this.player.destroy()
    }
  }
}

const CopyTimestampLink = {
  mounted() {
    this.handleClick = async () => {
      const rawUrl = this.el.dataset.videoUrl
      const seconds = Number.parseInt(this.el.dataset.seconds || "0", 10)

      if (!rawUrl) return

      let link = rawUrl

      try {
        const url = new URL(rawUrl)
        const safeSeconds = Number.isFinite(seconds) && seconds > 0 ? seconds : 0
        if (safeSeconds > 0) {
          url.searchParams.set("t", `${safeSeconds}s`)
        }
        link = url.toString()
      } catch (_error) {
        // Keep raw URL if parsing fails.
      }

      try {
        await navigator.clipboard.writeText(link)
        const original = this.el.textContent
        this.el.textContent = "Copied!"
        window.setTimeout(() => {
          this.el.textContent = original
        }, 1200)
      } catch (_error) {
        // Ignore clipboard failures silently.
      }
    }

    this.el.addEventListener("click", this.handleClick)
  },

  destroyed() {
    if (this.handleClick) {
      this.el.removeEventListener("click", this.handleClick)
    }
  }
}

const PersistDetailsOpen = {
  mounted() {
    this.storageKey = `rumbl:details:${this.el.id}`

    const savedOpenState = window.sessionStorage.getItem(this.storageKey)
    if (savedOpenState === "true") this.el.open = true
    if (savedOpenState === "false") this.el.open = false

    this.handleToggle = () => {
      window.sessionStorage.setItem(this.storageKey, this.el.open ? "true" : "false")
    }

    this.el.addEventListener("toggle", this.handleToggle)
  },

  updated() {
    const savedOpenState = window.sessionStorage.getItem(this.storageKey)
    if (savedOpenState === "true") this.el.open = true
    if (savedOpenState === "false") this.el.open = false
  },

  destroyed() {
    if (this.handleToggle) {
      this.el.removeEventListener("toggle", this.handleToggle)
    }
  }
}

const csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
const liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: {_csrf_token: csrfToken},
  hooks: {
    ...colocatedHooks,
    FocusHintDisplayName,
    AutoGrowTextarea,
    YouTubeSeek,
    CopyTimestampLink,
    PersistDetailsOpen,
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
