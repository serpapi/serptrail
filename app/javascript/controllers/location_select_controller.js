import { Controller } from "@hotwired/stimulus"

const COUNTRIES = [
  { code: "us", name: "United States", flag: "🇺🇸" },
  { code: "gb", name: "United Kingdom", flag: "🇬🇧" },
  { code: "ca", name: "Canada", flag: "🇨🇦" },
  { code: "au", name: "Australia", flag: "🇦🇺" },
  { code: "de", name: "Germany", flag: "🇩🇪" },
  { code: "fr", name: "France", flag: "🇫🇷" },
  { code: "es", name: "Spain", flag: "🇪🇸" },
  { code: "it", name: "Italy", flag: "🇮🇹" },
  { code: "nl", name: "Netherlands", flag: "🇳🇱" },
  { code: "be", name: "Belgium", flag: "🇧🇪" },
  { code: "ch", name: "Switzerland", flag: "🇨🇭" },
  { code: "at", name: "Austria", flag: "🇦🇹" },
  { code: "se", name: "Sweden", flag: "🇸🇪" },
  { code: "no", name: "Norway", flag: "🇳🇴" },
  { code: "dk", name: "Denmark", flag: "🇩🇰" },
  { code: "fi", name: "Finland", flag: "🇫🇮" },
  { code: "pl", name: "Poland", flag: "🇵🇱" },
  { code: "pt", name: "Portugal", flag: "🇵🇹" },
  { code: "ie", name: "Ireland", flag: "🇮🇪" },
  { code: "cz", name: "Czech Republic", flag: "🇨🇿" },
  { code: "hu", name: "Hungary", flag: "🇭🇺" },
  { code: "ro", name: "Romania", flag: "🇷🇴" },
  { code: "ua", name: "Ukraine", flag: "🇺🇦" },
  { code: "ru", name: "Russia", flag: "🇷🇺" },
  { code: "tr", name: "Turkey", flag: "🇹🇷" },
  { code: "il", name: "Israel", flag: "🇮🇱" },
  { code: "sa", name: "Saudi Arabia", flag: "🇸🇦" },
  { code: "ae", name: "United Arab Emirates", flag: "🇦🇪" },
  { code: "eg", name: "Egypt", flag: "🇪🇬" },
  { code: "za", name: "South Africa", flag: "🇿🇦" },
  { code: "ng", name: "Nigeria", flag: "🇳🇬" },
  { code: "in", name: "India", flag: "🇮🇳" },
  { code: "pk", name: "Pakistan", flag: "🇵🇰" },
  { code: "bd", name: "Bangladesh", flag: "🇧🇩" },
  { code: "jp", name: "Japan", flag: "🇯🇵" },
  { code: "kr", name: "South Korea", flag: "🇰🇷" },
  { code: "cn", name: "China", flag: "🇨🇳" },
  { code: "tw", name: "Taiwan", flag: "🇹🇼" },
  { code: "hk", name: "Hong Kong", flag: "🇭🇰" },
  { code: "sg", name: "Singapore", flag: "🇸🇬" },
  { code: "my", name: "Malaysia", flag: "🇲🇾" },
  { code: "id", name: "Indonesia", flag: "🇮🇩" },
  { code: "ph", name: "Philippines", flag: "🇵🇭" },
  { code: "th", name: "Thailand", flag: "🇹🇭" },
  { code: "vn", name: "Vietnam", flag: "🇻🇳" },
  { code: "nz", name: "New Zealand", flag: "🇳🇿" },
  { code: "br", name: "Brazil", flag: "🇧🇷" },
  { code: "mx", name: "Mexico", flag: "🇲🇽" },
  { code: "ar", name: "Argentina", flag: "🇦🇷" },
  { code: "cl", name: "Chile", flag: "🇨🇱" },
  { code: "co", name: "Colombia", flag: "🇨🇴" },
]

export default class extends Controller {
  static targets = ["input", "tags", "dropdown", "hiddenInputs"]

  connect() {
    const initial = JSON.parse(this.element.dataset.locationSelectInitialValue || "[]")
    this.selectedCodes = new Set(initial)
    this.renderTags()
    this.renderHiddenInputs()
    this.onDocumentClick = this.closeIfOutside.bind(this)
    document.addEventListener("click", this.onDocumentClick)
  }

  disconnect() {
    document.removeEventListener("click", this.onDocumentClick)
  }

  open() {
    this.inputTarget.select()
    this.renderDropdown(this.available())
    this.dropdownTarget.removeAttribute("hidden")
  }

  filter() {
    const q = this.inputTarget.value.toLowerCase().trim()
    const matches = q
      ? this.available().filter(c => c.name.toLowerCase().includes(q) || c.code === q)
      : this.available()
    this.renderDropdown(matches)
    this.dropdownTarget.removeAttribute("hidden")
  }

  add(event) {
    const option = event.target.closest("[data-code]")
    if (!option) return
    this.selectedCodes.add(option.dataset.code)
    this.renderTags()
    this.renderHiddenInputs()
    this.inputTarget.value = ""
    this.filter()
    this.inputTarget.focus()
  }

  remove(event) {
    this.selectedCodes.delete(event.currentTarget.dataset.code)
    this.renderTags()
    this.renderHiddenInputs()
    if (!this.dropdownTarget.hidden) this.filter()
  }

  focusInput() {
    this.inputTarget.focus()
  }

  closeIfOutside(event) {
    if (!this.element.contains(event.target)) {
      this.dropdownTarget.setAttribute("hidden", "")
      this.inputTarget.value = ""
    }
  }

  available() {
    return COUNTRIES.filter(c => !this.selectedCodes.has(c.code))
  }

  renderTags() {
    this.tagsTarget.innerHTML = Array.from(this.selectedCodes).map(code => {
      const c = COUNTRIES.find(c => c.code === code)
      if (!c) return ""
      return `<span class="location-tag">
        ${c.flag} ${c.name}
        <button type="button" class="location-tag-remove"
                data-action="click->location-select#remove"
                data-code="${code}"
                aria-label="Remove ${c.name}">×</button>
      </span>`
    }).join("")
  }

  renderHiddenInputs() {
    this.hiddenInputsTarget.innerHTML = Array.from(this.selectedCodes)
      .map(code => `<input type="hidden" name="keyword[locations][]" value="${code}">`)
      .join("")
  }

  renderDropdown(countries) {
    if (countries.length === 0) {
      this.dropdownTarget.innerHTML = `<div class="location-select-empty">No results</div>`
    } else {
      this.dropdownTarget.innerHTML = countries
        .map(c => `<button type="button" class="location-select-option" data-action="click->location-select#add" data-code="${c.code}">${c.flag} ${c.name}</button>`)
        .join("")
    }
  }
}
