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

export default class extends Controller {
  static targets = ["siteSelect", "keywordSelect", "locationSelect"]

  connect() {
    this.siteChanged()
  }

  siteChanged() {
    const siteId = this.siteSelectTarget.value
    const keywordSelect = this.keywordSelectTarget
    const currentKeyword = keywordSelect.value

    Array.from(keywordSelect.options).forEach(opt => {
      if (!opt.value) return
      opt.hidden = opt.dataset.siteId !== siteId
    })

    const selectedOpt = keywordSelect.querySelector(`option[value="${currentKeyword}"]`)
    if (!selectedOpt || selectedOpt.dataset.siteId !== siteId) {
      keywordSelect.value = ""
      this.locationSelectTarget.innerHTML = '<option value="">Select location</option>'
    } else {
      this.keywordChanged()
    }
  }

  keywordChanged() {
    const selected = this.keywordSelectTarget.selectedOptions[0]
    const locationSelect = this.locationSelectTarget
    const currentLocation = locationSelect.value

    if (!selected || !selected.value || !selected.dataset.locations) {
      locationSelect.innerHTML = '<option value="">Select location</option>'
      return
    }

    const locations = JSON.parse(selected.dataset.locations)
    const options = ['<option value="">Select location</option>']
    locations.forEach(code => {
      const name = COUNTRY_NAMES[code] || code.toUpperCase()
      const flag = countryFlag(code)
      const sel = code === currentLocation ? ' selected' : ''
      options.push(`<option value="${code}"${sel}>${flag} ${name}</option>`)
    })
    locationSelect.innerHTML = options.join("")
  }
}
