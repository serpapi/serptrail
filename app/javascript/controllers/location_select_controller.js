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

function countryFlag(code) {
  return [...code.toUpperCase()].map(c => String.fromCodePoint(0x1F1E6 + c.charCodeAt(0) - 65)).join("")
}

function escapeHtml(value) {
  return String(value)
    .replaceAll("&", "&amp;")
    .replaceAll('"', "&quot;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
}

function locationOption(value) {
  const country = COUNTRIES.find(item => item.code === value)
  if (country) return { value, ...country }

  if (value.startsWith("city:")) {
    const [, code, ...nameParts] = value.split(":")
    return {
      value,
      code,
      flag: countryFlag(code),
      name: nameParts.join(":").replaceAll(",", ", "),
      targetType: "City",
    }
  }

  return { value, code: value, flag: "", name: value }
}

export default class extends Controller {
  static targets = ["input", "tags", "dropdown", "hiddenInputs"]
  static values = { searchUrl: String }

  connect() {
    const initial = JSON.parse(this.element.dataset.locationSelectInitialValue || "[]")
    this.selectedValues = new Set(initial)
    this.renderTags()
    this.renderHiddenInputs()
    this.onDocumentClick = this.closeIfOutside.bind(this)
    document.addEventListener("click", this.onDocumentClick)
  }

  disconnect() {
    document.removeEventListener("click", this.onDocumentClick)
    clearTimeout(this.searchTimer)
    this.abortController?.abort()
  }

  open() {
    this.inputTarget.select()
    this.renderDropdown(this.availableCountries())
    this.dropdownTarget.removeAttribute("hidden")
  }

  filter() {
    const query = this.inputTarget.value.toLowerCase().trim()
    const countries = this.availableCountries().filter(country =>
      country.name.toLowerCase().includes(query) || country.code === query
    )

    clearTimeout(this.searchTimer)
    this.abortController?.abort()

    if (query.length < 2) {
      this.renderDropdown(countries)
    } else {
      this.renderDropdown(countries, "Searching cities…")
      this.searchTimer = setTimeout(() => this.searchCities(query, countries), 250)
    }
    this.dropdownTarget.removeAttribute("hidden")
  }

  async searchCities(query, countries) {
    this.abortController = new AbortController()

    try {
      const url = new URL(this.searchUrlValue, window.location.origin)
      url.searchParams.set("q", query)
      const response = await fetch(url, { headers: { Accept: "application/json" }, signal: this.abortController.signal })
      if (!response.ok) throw new Error("Location search failed")

      const cities = (await response.json())
        .filter(city => !this.selectedValues.has(city.value))
        .map(city => ({
          value: city.value,
          code: city.country_code,
          flag: countryFlag(city.country_code),
          name: city.name,
          targetType: city.target_type,
        }))

      if (this.inputTarget.value.toLowerCase().trim() === query) {
        this.renderDropdown([...countries, ...cities])
      }
    } catch (error) {
      if (error.name !== "AbortError") this.renderDropdown(countries, "City search is temporarily unavailable")
    }
  }

  add(event) {
    const option = event.target.closest("[data-value]")
    if (!option) return

    this.selectedValues.add(option.dataset.value)
    this.renderTags()
    this.renderHiddenInputs()
    this.inputTarget.value = ""
    this.filter()
    this.inputTarget.focus()
  }

  remove(event) {
    this.selectedValues.delete(event.currentTarget.dataset.value)
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

  availableCountries() {
    return COUNTRIES
      .filter(country => !this.selectedValues.has(country.code))
      .map(country => ({ value: country.code, ...country }))
  }

  renderTags() {
    this.tagsTarget.innerHTML = Array.from(this.selectedValues).map(value => {
      const location = locationOption(value)
      return `<span class="location-tag">
        ${location.flag} ${escapeHtml(location.name)}
        <button type="button" class="location-tag-remove"
                data-action="click->location-select#remove"
                data-value="${escapeHtml(value)}"
                aria-label="Remove ${escapeHtml(location.name)}">×</button>
      </span>`
    }).join("")
  }

  renderHiddenInputs() {
    this.hiddenInputsTarget.innerHTML = Array.from(this.selectedValues)
      .map(value => `<input type="hidden" name="keyword[locations][]" value="${escapeHtml(value)}">`)
      .join("")
  }

  renderDropdown(locations, message = null) {
    const options = locations.map(location => {
      const type = location.targetType
        ? `<span class="location-select-option-type">${escapeHtml(location.targetType)}</span>`
        : ""
      return `<button type="button" class="location-select-option" data-action="click->location-select#add" data-value="${escapeHtml(location.value)}"><span>${location.flag} ${escapeHtml(location.name)}</span>${type}</button>`
    }).join("")

    const status = message ? `<div class="location-select-empty">${escapeHtml(message)}</div>` : ""
    this.dropdownTarget.innerHTML = options || status || `<div class="location-select-empty">No results</div>`
    if (options && status) this.dropdownTarget.insertAdjacentHTML("beforeend", status)
  }
}
