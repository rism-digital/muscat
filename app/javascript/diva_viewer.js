import Diva from "diva.js"
import OpenSeadragon from "openseadragon"

// Diva's ESM build expects OpenSeadragon to be available as a browser global.
window.OpenSeadragon = OpenSeadragon

const viewers = new WeakMap()
const VIEWER_HEIGHT = "700px"
const CANVAS_MIN_HEIGHT = "500px"

function scopeDivaElementLookups() {
  const prototype = Diva.prototype
  if (prototype.muscatUsesScopedElementLookups) return

  // Diva 7.4.0 renders the same `main-viewer` and `filter-viewer` IDs in every
  // instance, then looks them up through document.getElementById(). Scope those
  // lookups to the instance root so multiple manifests can coexist on a page.
  prototype.ensureMainViewer = function ensureMainViewer() {
    const current = this.root.querySelector("#main-viewer")
    if (current && current !== this.mainViewer) this.mainViewer = current

    return this.mainViewer
  }

  prototype.ensureFilterViewerElement = function ensureFilterViewerElement() {
    const element = this.root.querySelector("#filter-viewer")
    if (!element) {
      this.filterViewerElement = null
      return null
    }

    if (this.filterViewerElement !== element) {
      if (this.filterViewer && typeof this.filterViewer.destroy === "function") {
        this.filterViewer.destroy()
      }

      this.filterViewer = null
      this.currentFilterSourceKey = null
      this.filterViewerFlipped = false
      this.filterViewerElement = element
    }

    return this.filterViewerElement
  }

  Object.defineProperty(prototype, "muscatUsesScopedElementLookups", { value: true })
}

function enforceViewerDimensions(element) {
  // Active Admin can load extension styles before Diva's runtime styles. Keep
  // the height contract on the rendered elements themselves so the canvas
  // cannot fall back to its roughly 40px intrinsic height.
  element.style.setProperty("height", VIEWER_HEIGHT, "important")
  element.style.setProperty("min-height", VIEWER_HEIGHT, "important")

  const renderedRoot = element.firstElementChild
  if (renderedRoot) {
    renderedRoot.style.setProperty("height", "100%", "important")
    renderedRoot.style.setProperty("min-height", "0", "important")
  }

  const app = element.querySelector(".diva-app")
  if (app) app.style.setProperty("height", "100%", "important")

  ;[".diva-app-body", ".diva-canvas-column", ".diva-canvas-wrapper"].forEach((selector) => {
    const node = element.querySelector(selector)
    if (!node) return

    node.style.setProperty("min-height", CANVAS_MIN_HEIGHT, "important")
  })
}

function initializeViewer(element) {
  if (viewers.has(element)) return

  const manifestUrl = element.dataset.divaManifest
  if (!element.id || !manifestUrl) return

  try {
    enforceViewerDimensions(element)

    const viewer = new Diva(element.id, {
      objectData: manifestUrl,
      showSidebar: false,
      sidebarPanel: "thumbnails",
      showTitle: false,
    })

    enforceViewerDimensions(element)
    requestAnimationFrame(() => enforceViewerDimensions(element))

    viewers.set(element, viewer)
    viewer.ready.catch((error) => {
      element.dataset.divaError = "true"
      console.error(`Unable to load IIIF manifest ${manifestUrl}`, error)
    })
  } catch (error) {
    element.dataset.divaError = "true"
    console.error(`Unable to initialize Diva viewer for ${manifestUrl}`, error)
  }
}

function initializeWithin(root) {
  if (!(root instanceof Element)) return

  if (root.matches("[data-diva-manifest]")) initializeViewer(root)
  root.querySelectorAll("[data-diva-manifest]").forEach(initializeViewer)
}

function start() {
  scopeDivaElementLookups()
  initializeWithin(document.body)

  const observer = new MutationObserver((mutations) => {
    mutations.forEach((mutation) => {
      mutation.addedNodes.forEach(initializeWithin)
    })
  })

  observer.observe(document.body, { childList: true, subtree: true })
}

if (document.readyState === "loading") {
  document.addEventListener("DOMContentLoaded", start, { once: true })
} else {
  start()
}
