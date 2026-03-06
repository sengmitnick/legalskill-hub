import { Controller } from "@hotwired/stimulus"

// Handles WeChat QR-code login flow:
// 1. On connect: fetch a QR code from /wechat/qrcode
// 2. Display QR code image and start 60-second countdown
// 3. Poll /wechat/check every 1.5s until scan confirmed or expired
// 4. On success: redirect to returned URL
// 5. On expiry: show refresh button

export default class extends Controller<HTMLElement> {
  static targets = ["qrImage", "status", "countdown", "refreshBtn", "loadingSpinner"]
  static values  = { pollInterval: { type: Number, default: 1500 } }

  declare readonly qrImageTarget:      HTMLImageElement
  declare readonly statusTarget:       HTMLElement
  declare readonly countdownTarget:    HTMLElement
  declare readonly refreshBtnTarget:   HTMLElement
  declare readonly loadingSpinnerTarget: HTMLElement
  declare readonly pollIntervalValue:  number

  private ticket        = ""
  private pollTimer     = 0
  private countdownTimer= 0
  private secondsLeft   = 60

  connect(): void {
    this.loadQrCode()
  }

  disconnect(): void {
    this.clearTimers()
  }

  refresh(): void {
    this.clearTimers()
    this.refreshBtnTarget.classList.add("hidden")
    this.loadQrCode()
  }

  private async loadQrCode(): Promise<void> {
    this.setStatus("loading")

    try {
      const res  = await fetch("/wechat/qrcode", { headers: { Accept: "application/json" } })
      const data = await res.json()

      if (data.error || !data.ticket) {
        this.setStatus("error", data.error || "二维码加载失败")
        return
      }

      this.ticket      = data.ticket
      this.secondsLeft = data.expire_seconds || 300

      this.qrImageTarget.src = data.qrcode_url
      this.qrImageTarget.classList.remove("hidden")
      this.loadingSpinnerTarget.classList.add("hidden")

      this.startCountdown()
      this.startPolling()
      this.setStatus("waiting")
    } catch {
      this.setStatus("error", "网络错误，请稍后重试")
    }
  }

  private startPolling(): void {
    this.pollTimer = window.setInterval(() => this.poll(), this.pollIntervalValue)
  }

  private async poll(): Promise<void> {
    try {
      const res  = await fetch(`/wechat/check?ticket=${encodeURIComponent(this.ticket)}`, {
        headers: { Accept: "application/json" }
      })
      const data = await res.json()

      if (data.status === "ok" && data.redirect_url) {
        this.clearTimers()
        this.setStatus("success")
        window.location.href = data.redirect_url
      }
    } catch {
      // transient network error - keep polling
    }
  }

  private startCountdown(): void {
    this.updateCountdown()
    this.countdownTimer = window.setInterval(() => {
      this.secondsLeft -= 1
      this.updateCountdown()

      if (this.secondsLeft <= 0) {
        this.clearTimers()
        this.qrImageTarget.classList.add("opacity-30")
        this.refreshBtnTarget.classList.remove("hidden")
        this.setStatus("expired")
      }
    }, 1000)
  }

  private updateCountdown(): void {
    this.countdownTarget.textContent = `${this.secondsLeft}s`
  }

  private setStatus(state: "loading" | "waiting" | "success" | "expired" | "error", msg?: string): void {
    const messages: Record<string, string> = {
      loading:  "正在生成二维码…",
      waiting:  "请用微信扫描二维码登录",
      success:  "扫码成功，正在跳转…",
      expired:  "二维码已过期，请刷新",
      error:    msg || "出错了，请重试"
    }
    this.statusTarget.textContent = messages[state]
  }

  private clearTimers(): void {
    clearInterval(this.pollTimer)
    clearInterval(this.countdownTimer)
    this.pollTimer      = 0
    this.countdownTimer = 0
  }
}
