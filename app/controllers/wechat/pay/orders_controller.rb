module Wechat
  module Pay
    class OrdersController < ApplicationController
      before_action :authenticate_user!

      PLANS = {
        "plan1" => { amount: 99900,  description: "青狮龙虾 · 社群版 + 1年期使用权" },
        "plan2" => { amount: 199900, description: "青狮龙虾 · 线上课程 + 1年期使用权" },
        "plan3" => { amount: 299900, description: "青狮龙虾 · 线下课程 + 1年期使用权" },
        "plan4" => { amount: 199900, description: "青狮龙虾 · 团队线下内训 + 1年期使用权" }
      }.freeze

      # Fallback for development/testing
      TEST_PLAN = { amount: 100, description: "青狮法律技能平台 · 测试支付" }.freeze

      def new
        @plan_key  = params[:plan].presence
        plan_cfg   = plan_config(@plan_key)
        @amount_yuan = plan_cfg[:amount] / 100.0
        @description = plan_cfg[:description]
        @existing_paid = WechatOrder.paid.find_by(user: current_user)

        # In WeChat browser without MP openid → get openid first
        if wechat_browser? && mp_openid.blank?
          redirect_to wechat_mp_oauth_authorize_path(return_to: wechat_pay_order_new_path(plan: @plan_key))
        end
      end

      def create
        @plan_key = params[:plan].presence
        plan_cfg  = plan_config(@plan_key)

        # plan3 支持多人团购，quantity 由前端传入
        qty = if @plan_key == "plan3"
          [[params[:quantity].to_i, 1].max, 3].min
        else
          1
        end

        # plan3 动态定价：基价 2999，每增1人立减300，最多3人
        amount = if @plan_key == "plan3" && !Rails.env.development?
          unit_price = 2999_00 - (qty - 1) * 300_00
          unit_price * qty
        else
          plan_cfg[:amount]
        end

        # Idempotent: one pending order per user per plan
        order = WechatOrder.pending.find_or_initialize_by(user: current_user, plan: @plan_key)
        order.out_trade_no ||= SecureRandom.hex(16)
        order.amount       = amount
        order.description  = plan_cfg[:description]
        order.plan         = @plan_key
        order.quantity     = qty
        order.save!

        service = WechatPayService.new

        if wechat_browser?
          create_jsapi(order, service)
        else
          create_native(order, service)
        end
      rescue => e
        # Stale order conflicts: expire and retry with a fresh out_trade_no
        stale_order_errors = [
          "该订单已支付", "ORDERPAID",
          "请求重入时，参数与首次请求时不一致", "PARAM_ERROR"
        ]
        if stale_order_errors.any? { |msg| e.message.include?(msg) }
          order&.update(status: "expired")
          retry_order = WechatOrder.create!(
            user:         current_user,
            plan:         @plan_key,
            out_trade_no: SecureRandom.hex(16),
            amount:       order&.amount || plan_config(@plan_key)[:amount],
            description:  plan_config(@plan_key)[:description],
            quantity:     qty
          )
          service = WechatPayService.new
          return wechat_browser? ? create_jsapi(retry_order, service) : create_native(retry_order, service)
        end
        Rails.logger.error "[WechatPay] create order failed: #{e.message}\n#{e.backtrace.first(5).join("\n")}"
        render_modal_error("创建支付订单失败，请稍后重试")
      end

      def success
        @order = WechatOrder.paid.find_by!(user: current_user)
      rescue ActiveRecord::RecordNotFound
        redirect_to root_path, alert: "未找到支付记录"
      end

      private

      # ── Native (PC QR code) → Turbo Stream modal ────────────────────
      def create_native(order, service)
        result = service.create_native_order(
          out_trade_no: order.out_trade_no,
          amount:       order.amount,
          description:  order.description
        )

        qr = RQRCode::QRCode.new(result[:code_url])
        qr_svg       = qr.as_svg(module_size: 4, standalone: true, use_path: true)

        modal_html = render_to_string(
          partial: "payment_modal",
          locals:  {
            qr_svg:       qr_svg,
            out_trade_no: order.out_trade_no,
            amount_yuan:  order.amount_yuan,
            description:  order.description
          }
        )

        render_modal_html(modal_html)
      end

      # ── JSAPI (WeChat in-app browser) ────────────────────────────────
      def create_jsapi(order, service)
        openid = mp_openid
        raise "No MP openid available for JSAPI payment" if openid.blank?

        result = service.create_jsapi_order(
          out_trade_no: order.out_trade_no,
          amount:       order.amount,
          description:  order.description,
          openid:       openid
        )

        @jsapi_params = service.generate_jsapi_params(result[:prepay_id])
        @out_trade_no = order.out_trade_no
        @amount_yuan  = order.amount_yuan

        render :jsapi
      end

      # ── Render helpers ───────────────────────────────────────────────

      # Replace the overlay with visible modal containing inner HTML
      def render_modal_html(inner_html)
        overlay_html = <<~HTML.html_safe
          <div id="payment-modal-overlay"
               class="flex fixed inset-0 z-50 bg-black/60 backdrop-blur-sm"
               data-controller="wechat-pay-modal"
               data-action="click->wechat-pay-modal#backdropClick">
            <div id="payment-modal-body"
                 class="w-full h-full"
                 data-wechat-pay-modal-target="body">#{inner_html}</div>
          </div>
        HTML

        render turbo_stream: turbo_stream.replace("payment-modal-overlay", html: overlay_html)
      end

      # Replace the overlay with an error modal
      def render_modal_error(message)
        error_html = render_to_string(
          partial: "wechat/pay/orders/payment_error",
          locals:  { message: message }
        )
        render_modal_html(error_html)
      end

      # ── Helpers ──────────────────────────────────────────────────────

      def plan_config(plan_key)
        cfg = PLANS[plan_key] || TEST_PLAN
        # Override amount to 1 fen (0.01 yuan) in development for easy testing
        Rails.env.development? ? cfg.merge(amount: 1) : cfg
      end

      def mp_openid
        session[:wechat_mp_openid].presence ||
          current_user&.wechat_mp_openid.presence
      end
    end
  end
end
