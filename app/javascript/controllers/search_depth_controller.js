import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "value", "results"]

  connect() {
    this.update()
  }

  update() {
    const pages = Number.parseInt(this.inputTarget.value, 10) || 1
    this.valueTarget.textContent = `${pages} ${pages === 1 ? "page" : "pages"}`
    this.resultsTarget.textContent = pages * 10
  }
}
