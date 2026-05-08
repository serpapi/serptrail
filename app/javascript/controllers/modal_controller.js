import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["dialog"]

  open(event) {
    event.preventDefault()
    this.dialogTarget.showModal()
  }

  close() {
    this.dialogTarget.close()
  }

  backdropClick(event) {
    if (event.target === this.dialogTarget) this.dialogTarget.close()
  }
}
