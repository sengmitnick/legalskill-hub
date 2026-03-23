class WechatPayChannel < ApplicationCable::Channel
  def subscribed
    reject unless current_user

    out_trade_no = params[:out_trade_no]
    reject unless out_trade_no.present?

    # Verify the order belongs to current_user
    order = WechatOrder.find_by(out_trade_no: out_trade_no, user: current_user)
    reject unless order

    stream_from "wechat_pay_#{out_trade_no}"
  rescue StandardError => e
    handle_channel_error(e)
    reject
  end

  def unsubscribed
  rescue StandardError => e
    handle_channel_error(e)
  end

  private

  def current_user
    @current_user ||= connection.current_user
  end
end
