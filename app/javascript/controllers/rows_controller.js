import { Controller } from "@hotwired/stimulus"

// Adds and removes repeated form rows (emails, phones, addresses, URLs) without a page reload.
// New rows come from a <template>; NEW_ROW in its field names becomes a unique numeric index,
// which Rails needs to read the rows as an array.
let nextRow = 100

export default class extends Controller {
  static targets = [ "list", "template" ]

  add(event) {
    event.preventDefault()
    const html = this.templateTarget.innerHTML.replace(/NEW_ROW/g, `${Date.now()}${nextRow++}`)
    this.listTarget.insertAdjacentHTML("beforeend", html)
    this.listTarget.lastElementChild.querySelector("input:not([type=hidden]), textarea")?.focus()
  }

  remove(event) {
    event.preventDefault()
    event.target.closest("[data-row]").remove()
  }
}
