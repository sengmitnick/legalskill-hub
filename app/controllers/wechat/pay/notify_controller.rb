module Wechat
  module Pay
    # Receives async payment result callbacks from WeChat Pay servers.
    class NotifyController < ApplicationController
      skip_before_action :verify_authenticity_token
      # WeChat servers are not authenticated users
      skip_before_action :authenticate_user!, raise: false

      def callback
        headers_hash = {
          "wechatpay-timestamp" => request.headers["HTTP_WECHATPAY_TIMESTAMP"] || request.headers["wechatpay-timestamp"],
          "wechatpay-nonce"     => request.headers["HTTP_WECHATPAY_NONCE"]     || request.headers["wechatpay-nonce"],
          "wechatpay-signature" => request.headers["HTTP_WECHATPAY_SIGNATURE"] || request.headers["wechatpay-signature"]
        }

        body_str = request.body.read

        resource = WechatPayService.new.decrypt_notify(headers: headers_hash, body_str: body_str)

        out_trade_no     = resource["out_trade_no"]
        transaction_id   = resource["transaction_id"]
        trade_state      = resource["trade_state"]

        order = WechatOrder.find_by(out_trade_no: out_trade_no)

        if order && trade_state == "SUCCESS"
          order.update!(status: "paid", wechat_transaction_id: transaction_id)
          Rails.logger.info "[WechatPay] Order #{out_trade_no} paid, txn=#{transaction_id}"
          # Broadcast to frontend via ActionCable so the QR page auto-redirects
          ActionCable.server.broadcast(
            "wechat_pay_#{out_trade_no}",
            { type: "payment-success", out_trade_no: out_trade_no }
          )
        end

        render json: { code: "SUCCESS", message: "成功" }
      rescue => e
        Rails.logger.error "[WechatPay] notify error: #{e.message}"
        render json: { code: "FAIL", message: e.message }, status: :ok
      end
    end
  end
end
