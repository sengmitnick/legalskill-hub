import BaseChannelController from "./base_channel_controller"

// Listens to WechatPayChannel via ActionCable for real-time payment status updates.
// When the server receives WeChat Pay notify callback, it broadcasts to this channel.
//
// Targets:
//   statusTarget  - element showing current status text
//   spinnerTarget - loading spinner shown while waiting
// Values:
//   outTradeNo  - the order's out_trade_no (used as ActionCable stream key)
//   successUrl  - redirect URL on successful payment

export default class extends BaseChannelController {
  static targets = ["status", "spinner"]
  static values  = {
    outTradeNo: String,
    successUrl: String
  }

  declare readonly statusTarget:    HTMLElement
  declare readonly spinnerTarget:   HTMLElement
  declare readonly outTradeNoValue: string
  declare readonly successUrlValue: string

  connect(): void {
    this.createSubscription("WechatPayChannel", {
      out_trade_no: this.outTradeNoValue
    })
  }

  disconnect(): void {
    this.destroySubscription()
  }

  // Handles { type: 'payment-success', ... } broadcast from WechatPayChannel
  protected handlePaymentSuccess(_data: any): void {
    this.statusTarget.textContent = "支付成功，正在跳转..."
    window.location.href = this.successUrlValue
  }

  // Handles { type: 'payment-failed', ... } broadcast from WechatPayChannel
  protected handlePaymentFailed(_data: any): void {
    this.statusTarget.textContent = "支付失败或已关闭，请重新发起"
    this.spinnerTarget.classList.add("hidden")
  }

  protected channelConnected(): void {
    this.statusTarget.textContent = "等待扫码支付..."
  }
}
