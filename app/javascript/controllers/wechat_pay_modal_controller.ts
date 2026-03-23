import { Controller } from "@hotwired/stimulus"

// Controls the payment modal overlay on the homepage (PC Native pay flow).
// Works together with wechat-pay controller inside the modal body.
//
// Usage in layout (homepage):
//   <div id="payment-modal-overlay"
//        class="hidden fixed inset-0 z-50 bg-black/60 backdrop-blur-sm"
//        data-controller="wechat-pay-modal"
//        data-action="click->wechat-pay-modal#backdropClick">
//     <div id="payment-modal-body" data-wechat-pay-modal-target="body"></div>
//   </div>
//
// Targets:
//   body - the inner container that receives Turbo Stream content
//
// Actions:
//   close        - hides the overlay and clears the body
//   backdropClick - closes when clicking the backdrop (not the card)

export default class extends Controller {
  static targets = ["body"]

  declare readonly bodyTarget: HTMLElement
  declare readonly hasBodyTarget: boolean

  close(): void {
    this.element.classList.add("hidden")
    this.element.classList.remove("flex")
    if (this.hasBodyTarget) this.bodyTarget.innerHTML = ""
  }

  backdropClick(event: MouseEvent): void {
    if (event.target === this.element) {
      this.close()
    }
  }
}
