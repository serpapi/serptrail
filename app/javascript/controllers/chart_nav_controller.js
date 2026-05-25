import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { frame: String }

  navigate(event) {
    const url = event.currentTarget.dataset.searchRunUrl
    if (!url) return
    const frame = document.getElementById(this.frameValue)
    if (frame) frame.src = url
  }
}
