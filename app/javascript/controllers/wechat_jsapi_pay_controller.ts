// Stimulus controller for WeChat JSAPI payment (in-app H5).
// Reads JSAPI params from data attribute, invokes WeixinJSBridge,
// then redirects on success (server receives async notify from Wechat Pay).
//
// Targets:
//   payBtn    — the pay button
//   statusBox — wrapper div shown during processing
//   status    — text inside statusBox
//   error     — error message paragraph
//
// Values:
//   params      — JSON string of JSAPI params (appId/timeStamp/nonceStr/package/signType/paySign)
//   successUrl  — redirect URL after payment confirmed by WeixinJSBridge

import { Controller } from "@hotwired/stimulus"

declare global {
  interface Window {
    WeixinJSBridge?: {
      invoke: (api: string, params: object, callback: (res: { err_msg: string }) => void) => void
    }
  }
}

export default class extends Controller {
  static targets = ["payBtn", "statusBox", "status", "error"]
  static values  = {
    params:     String,
    successUrl: String
  }

  declare readonly payBtnTarget:    HTMLButtonElement
  declare readonly statusBoxTarget: HTMLElement
  declare readonly statusTarget:    HTMLElement
  declare readonly errorTarget:     HTMLElement
  declare paramsValue:    string
  declare successUrlValue: string

  connect() {
    // Auto-invoke payment once WeixinJSBridge is ready
    if (typeof window.WeixinJSBridge === "undefined") {
      document.addEventListener("WeixinJSBridgeReady", () => this.pay(), { once: true })
    }
  }

  pay() {
    let jsapiParams: object
    try {
      jsapiParams = JSON.parse(this.paramsValue)
    } catch {
      this.showError("支付参数解析失败")
      return
    }

    if (typeof window.WeixinJSBridge === "undefined") {
      this.showError("请在微信内打开此页面")
      return
    }

    this.setLoading(true)

    // WeixinJSBridge ok callback is authoritative: user confirmed payment in Wechat app.
    // Server receives async notify from Wechat Pay to finalize order status.
    window.WeixinJSBridge.invoke("getBrandWCPayRequest", jsapiParams, (res) => {
      if (res.err_msg === "get_brand_wcpay_request:ok") {
        this.showStatus("支付成功，正在跳转...")
        window.location.href = this.successUrlValue
      } else if (res.err_msg === "get_brand_wcpay_request:cancel") {
        this.setLoading(false)
        this.showError("已取消支付")
      } else {
        this.setLoading(false)
        this.showError(`支付失败：${res.err_msg}`)
      }
    })
  }

  private setLoading(loading: boolean) {
    this.payBtnTarget.disabled = loading
    this.statusBoxTarget.classList.toggle("hidden", !loading)
  }

  private showStatus(msg: string) {
    this.statusTarget.textContent = msg
    this.statusBoxTarget.classList.remove("hidden")
  }

  private showError(msg: string) {
    this.errorTarget.textContent = msg
    this.errorTarget.classList.remove("hidden")
  }
}
