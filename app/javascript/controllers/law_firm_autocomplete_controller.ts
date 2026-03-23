import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "dropdown", "list", "hidden", "companyText"]

  declare inputTarget: HTMLInputElement
  declare dropdownTarget: HTMLElement
  declare listTarget: HTMLElement
  declare hiddenTarget: HTMLInputElement
  declare companyTextTarget: HTMLInputElement

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

  renderDropdown(items: Array<{ id: number; name: string }>, q: string) {
    this.listTarget.innerHTML = ""

    if (items.length > 0) {
      items.forEach(item => {
        const li = document.createElement("li")
        li.className = "px-4 py-2 cursor-pointer hover:bg-gray-100 dark:hover:bg-gray-700 text-sm text-gray-800 dark:text-gray-200"
        // 高亮匹配字符
        li.innerHTML = item.name.replace(new RegExp(`(${q})`, "gi"), "<mark class='bg-yellow-200 dark:bg-yellow-700'>$1</mark>")
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

  selectItem(item: { id: number; name: string }) {
    this.inputTarget.value = item.name
    this.hiddenTarget.value = String(item.id)
    this.companyTextTarget.value = item.name
    this.hideDropdown()
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
