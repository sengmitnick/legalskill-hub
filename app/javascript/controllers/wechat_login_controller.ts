import { Controller } from "@hotwired/stimulus"

// Legacy WeChat QR login controller - replaced by WxLogin JS SDK.
// Kept as a stub to satisfy stimulus validation (targets & actions declared in HTML).
export default class extends Controller<HTMLElement> {
  static targets = ["loadingSpinner", "qrImage", "status", "countdown", "refreshBtn"]

  declare readonly loadingSpinnerTarget: HTMLElement
  declare readonly qrImageTarget: HTMLImageElement
  declare readonly statusTarget: HTMLElement
  declare readonly countdownTarget: HTMLElement
  declare readonly refreshBtnTarget: HTMLButtonElement

  connect(): void {
    // WxLogin SDK now handles WeChat login via open platform QR code.
    // See app/views/wechat/qrcode/show.html.erb for the WxLogin setup.
  }

  // Stub for the refresh button action - no-op since WxLogin handles the flow.
  refresh(): void {
    // Reload page to reinitialize WxLogin SDK
    window.location.reload()
  }
}
