import { Controller } from "@hotwired/stimulus"

// 支付弹窗遮罩控制器
// 用法：data-controller="wechat-pay-modal"
// 方法：open()、close()、backdropClick(event)
export default class extends Controller {
  static targets = ["body"]

  declare readonly bodyTarget: HTMLElement
  declare readonly hasBodyTarget: boolean

  // 打开弹窗
  open() {
    this.element.classList.remove("hidden")
  }

  // 关闭弹窗，清空内容
  close() {
    this.element.classList.add("hidden")
    if (this.hasBodyTarget) {
      this.bodyTarget.innerHTML = ""
    }
  }

  // 点击遮罩背景时关闭（点到内容区不关闭）
  backdropClick(event: MouseEvent) {
    if (event.target === this.element) {
      this.close()
    }
  }
}
