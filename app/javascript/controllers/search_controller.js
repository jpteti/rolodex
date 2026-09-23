import { Controller } from "@hotwired/stimulus"

// Submits the search form as the user types, after a short pause.
export default class extends Controller {
  search() {
    clearTimeout(this.timeout)
    this.timeout = setTimeout(() => this.element.requestSubmit(), 200)
  }
}
