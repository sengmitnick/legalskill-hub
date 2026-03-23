module ApplicationHelper
  def app_name
    Rails.application.config.x.appname
  end

  # Renders a "立即购买" button.
  # - Logged-in users (PC): POST form → Turbo Stream → QR modal
  # - Logged-in users (mobile WeChat): POST form → JSAPI page
  # - Guests: link → wechat login page
  def buy_button(plan:, css_class:, style: nil)
    icon = lucide_icon("shopping-cart", class: "w-3.5 h-3.5")
    label = "#{icon} 立即购买".html_safe

    if user_signed_in?
      form_tag(wechat_pay_order_create_path, method: :post, class: "w-full",
               data: { turbo: true, turbo_stream: true }) do
        hidden_field_tag(:plan, plan) +
          button_tag(label, type: "submit", class: css_class,
                     style: style,
                     data: { disable_with: "处理中..." })
      end
    else
      link_to(label, wechat_qrcode_path, class: css_class, style: style)
    end
  end
end
