import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "dropdown", "list", "hidden", "companyText"]
  static values = { provinceSelector: String, citySelector: String, districtSelector: String }

  declare inputTarget: HTMLInputElement
  declare dropdownTarget: HTMLElement
  declare listTarget: HTMLElement
  declare hiddenTarget: HTMLInputElement
  declare companyTextTarget: HTMLInputElement
  declare provinceSelectorValue: string
  declare citySelectorValue: string
  declare districtSelectorValue: string

  private debounceTimer: ReturnType<typeof setTimeout> | null = null

  connect() {
    this.hideDropdown()
    document.addEventListener("click", this.onOutsideClick)
  }

  disconnect() {
    document.removeEventListener("click", this.onOutsideClick)
  }

  onInput() {
    const q = this.inputTarget.value.trim()
    // 清空隐藏字段（用户手动修改了），同步 company 文本
    this.hiddenTarget.value = ""
    this.companyTextTarget.value = q

    if (this.debounceTimer) clearTimeout(this.debounceTimer)
    if (q.length === 0) { this.hideDropdown(); return }

    this.debounceTimer = setTimeout(() => this.search(q), 250)
  }

  search(q: string) {
    const xhr = new XMLHttpRequest()
    xhr.open("GET", `/api/law_firms/autocomplete?q=${encodeURIComponent(q)}`)
    xhr.onload = () => {
      if (xhr.status < 400) {
        const data: Array<{ id: number; name: string }> = JSON.parse(xhr.responseText)
        this.renderDropdown(data, q)
      } else {
        this.hideDropdown()
      }
    }
    xhr.onerror = () => this.hideDropdown()
    xhr.send()
  }

  renderDropdown(items: Array<{ id: number; name: string; province: string; city: string; district: string }>, q: string) {
    this.listTarget.innerHTML = ""

    if (items.length > 0) {
      items.forEach(item => {
        const li = document.createElement("li")
        li.className = "px-4 py-2 cursor-pointer hover:bg-gray-100 dark:hover:bg-gray-700 text-sm text-gray-800 dark:text-gray-200"
        const location = [item.province, item.city].filter(Boolean).join(" · ")
        const nameHtml = item.name.replace(new RegExp(`(${q})`, "gi"), "<mark class='bg-yellow-200 dark:bg-yellow-700'>$1</mark>")
        li.innerHTML = nameHtml + (location ? `<span class="ml-2 text-xs text-gray-400">${location}</span>` : "")
        li.addEventListener("mousedown", (e) => {
          e.preventDefault()
          this.selectItem(item)
        })
        this.listTarget.appendChild(li)
      })
    } else {
      // 没匹配到，提示"使用此名称"
      const li = document.createElement("li")
      li.className = "px-4 py-2 text-sm text-gray-500 dark:text-gray-400 italic"
      li.textContent = `使用「${q}」（新律所，保存后自动创建）`
      this.listTarget.appendChild(li)
    }

    this.showDropdown()
  }

  selectItem(item: { id: number; name: string; province?: string; city?: string; district?: string }) {
    this.inputTarget.value = item.name
    this.hiddenTarget.value = String(item.id)
    this.companyTextTarget.value = item.name
    this.hideDropdown()

    // 自动填入省市区（触发 Stimulus profile-edit controller 的联动）
    if (item.province || item.city) {
      this.fillLocation(item.province || "", item.city || "", item.district || "")
    }
  }

  fillLocation(province: string, city: string, district: string) {
    // 找到 profile-edit controller 元素，触发省市区联动
    const profileEditEl = document.querySelector("[data-controller~='profile-edit']") as HTMLElement
    if (!profileEditEl) return

    // 先设置省，触发 change 事件（加载市列表）
    const provinceSelect = profileEditEl.querySelector("[data-profile-edit-target='province']") as HTMLSelectElement
    if (provinceSelect) {
      provinceSelect.value = province
      // 告知 profile-edit controller 目标城市
      provinceSelect.dataset.pendingCity = city
      provinceSelect.dataset.pendingDistrict = district
      provinceSelect.dispatchEvent(new Event("change", { bubbles: true }))
    }
  }

  showDropdown() {
    this.dropdownTarget.classList.remove("hidden")
  }

  hideDropdown() {
    this.dropdownTarget.classList.add("hidden")
  }

  onOutsideClick = (e: MouseEvent) => {
    if (!this.element.contains(e.target as Node)) {
      this.hideDropdown()
    }
  }
}
