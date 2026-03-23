# GET /wechat/qrcode - renders the WeChat login page (WxLogin JS SDK handles QR code)
# If accessed from WeChat in-app browser, automatically redirects to MP OAuth H5 login.
class Wechat::QrcodeController < ApplicationController
  skip_before_action :authenticate_user!, raise: false

  def show
    # Already logged in — go home
    return redirect_to root_path if current_user

    # WeChat in-app browser: use MP OAuth H5 login instead of WxLogin QR code
    if wechat_browser?
      return redirect_to wechat_mp_oauth_authorize_path(
        purpose:   "login",
        return_to: params[:return_to] || root_path
      )
    end

    # PC browser: render WxLogin QR code page as usual
  end
end
