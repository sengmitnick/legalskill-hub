# Handles WeChat Official Account Webhook:
# GET  /wechat/mp - server verification (WeChat sends echostr)
# POST /wechat/mp - receives push events (subscribe, SCAN, etc.)
class Wechat::MpController < ApplicationController
  skip_before_action :verify_authenticity_token
  skip_before_action :authenticate_user!, raise: false

  def verify
    # HEAD requests from WeChat health checks have no params — return 200 immediately
    return head :ok if request.head?

    service = WechatMpService.new

    token     = ENV.fetch("WECHAT_MP_TOKEN", "")
    timestamp = params[:timestamp]
    nonce     = params[:nonce]
    signature = params[:signature]
    echostr   = params[:echostr]
    arr       = [ token, timestamp, nonce ].sort
    expected  = Digest::SHA1.hexdigest(arr.join)

    Rails.logger.info "[WeChat Verify] token=#{token} timestamp=#{timestamp} nonce=#{nonce}"
    Rails.logger.info "[WeChat Verify] received_sig=#{signature}"
    Rails.logger.info "[WeChat Verify] expected_sig=#{expected}"
    Rails.logger.info "[WeChat Verify] match=#{expected == signature}"

    if service.valid_signature?(timestamp, nonce, signature)
      render plain: echostr
    else
      render plain: "invalid signature", status: :forbidden
    end
  end

  def callback
    service   = WechatMpService.new
    xml_body  = request.body.read
    xml       = Nokogiri::XML(xml_body)

    msg_type  = xml.at("MsgType")&.text
    event     = xml.at("Event")&.text
    openid    = xml.at("FromUserName")&.text
    # For SCAN event: Ticket field = the real ticket string (same as qrcode_url ticket)
    # For subscribe event: EventKey has "qrscene_" prefix, Ticket is the real ticket
    ticket    = xml.at("Ticket")&.text

    Rails.logger.info "[WeChat Callback] msg_type=#{msg_type} event=#{event} openid=#{openid} ticket=#{ticket&.first(30)}"

    # Handle both subscribe-with-scan and direct SCAN events
    if msg_type == "event" && event.in?([ "subscribe", "SCAN" ]) && ticket.present?
      service.store_scan_result(ticket, openid)
      Rails.logger.info "[WeChat Callback] stored openid=#{openid} for ticket=#{ticket[0..20]}..."
    else
      Rails.logger.info "[WeChat Callback] ignored - conditions not met (msg_type=#{msg_type} event=#{event} ticket_present=#{ticket.present?})"
    end

    render plain: "success"
  end
end
