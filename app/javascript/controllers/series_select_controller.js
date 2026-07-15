import { Controller } from "@hotwired/stimulus"

const COUNTRY_NAMES = {
  us: "United States", gb: "United Kingdom", ca: "Canada", au: "Australia",
  de: "Germany", fr: "France", es: "Spain", it: "Italy", nl: "Netherlands",
  be: "Belgium", ch: "Switzerland", at: "Austria", se: "Sweden", no: "Norway",
  dk: "Denmark", fi: "Finland", pl: "Poland", pt: "Portugal", ie: "Ireland",
  cz: "Czech Republic", hu: "Hungary", ro: "Romania", ua: "Ukraine", ru: "Russia",
  tr: "Turkey", il: "Israel", sa: "Saudi Arabia", ae: "United Arab Emirates",
  eg: "Egypt", za: "South Africa", ng: "Nigeria", in: "India", pk: "Pakistan",
  bd: "Bangladesh", jp: "Japan", kr: "South Korea", cn: "China", tw: "Taiwan",
  hk: "Hong Kong", sg: "Singapore", my: "Malaysia", id: "Indonesia",
  ph: "Philippines", th: "Thailand", vn: "Vietnam", nz: "New Zealand",
  br: "Brazil", mx: "Mexico", ar: "Argentina", cl: "Chile", co: "Colombia",
}

function countryFlag(code) {
  return [...code.toUpperCase()].map(c => String.fromCodePoint(0x1F1E6 + c.charCodeAt(0) - 65)).join("")
}

function locationDetails(value) {
  if (value.startsWith("city:")) {
    const [, code, ...nameParts] = value.split(":")
    return { flag: countryFlag(code), name: nameParts.join(":").replaceAll(",", ", ") }
  }

  return { flag: countryFlag(value), name: COUNTRY_NAMES[value] || value.toUpperCase() }
}

export default class extends Controller {
  static targets = ["siteSelect", "keywordSelect", "locationSelect"]

  connect() {
    this.siteChanged()
  }

  siteChanged() {
    const siteId = this.siteSelectTarget.value
    const keywordSelect = this.keywordSelectTarget
    const currentKeyword = keywordSelect.value

    Array.from(keywordSelect.options).forEach(option => {
      if (!option.value) return
      option.hidden = option.dataset.siteId !== siteId
    })

    const selectedOption = keywordSelect.querySelector(`option[value="${currentKeyword}"]`)
    if (!selectedOption || selectedOption.dataset.siteId !== siteId) {
      keywordSelect.value = ""
      this.resetLocations()
    } else {
      this.keywordChanged()
    }
  }

  keywordChanged() {
    const selected = this.keywordSelectTarget.selectedOptions[0]
    const currentLocation = this.locationSelectTarget.value

    if (!selected || !selected.value || !selected.dataset.locations) {
      this.resetLocations()
      return
    }

    const locations = JSON.parse(selected.dataset.locations)
    const options = [new Option("Select location", "")]
    locations.forEach(value => {
      const location = locationDetails(value)
      options.push(new Option(`${location.flag} ${location.name}`, value, false, value === currentLocation))
    })
    this.locationSelectTarget.replaceChildren(...options)
  }

  resetLocations() {
    this.locationSelectTarget.replaceChildren(new Option("Select location", ""))
  }
}
