require "omniauth-oauth2"

module OmniAuth
  module Strategies
    # OmniAuth strategy for WeChat Open Platform (PC QR code login / WxLogin)
    # Returns unionid which is the cross-app unified user identifier.
    class OpenWechat < OmniAuth::Strategies::OAuth2
      option :name, "open_wechat"

      option :client_options, {
        site:          "https://api.weixin.qq.com",
        authorize_url: "https://open.weixin.qq.com/connect/qrconnect",
        token_url:     "/sns/oauth2/access_token"
      }

      # WeChat uses appid/secret instead of client_id/client_secret
      option :token_params, { grant_type: "authorization_code" }

      uid { raw_info["unionid"] || raw_info["openid"] }

      info do
        {
          name:      raw_info["nickname"],
          image:     raw_info["headimgurl"],
          unionid:   raw_info["unionid"],
          openid:    raw_info["openid"]
        }
      end

      extra { { raw_info: raw_info } }

      def raw_info
        @raw_info ||= begin
          access_token.options[:mode] = :query
          response = access_token.get("/sns/userinfo", params: {
            access_token: access_token.token,
            openid:       access_token["openid"],
            lang:         "zh_CN"
          })
          JSON.parse(response.body)
        end
      end

      # WeChat token endpoint requires GET, not POST
      def client
        opts = deep_symbolize(options.client_options).merge(token_method: :get)
        ::OAuth2::Client.new(options.client_id, options.client_secret, opts) do |builder|
          builder.request :url_encoded
          builder.adapter Faraday.default_adapter
        end
      end

      def authorize_params
        super.tap do |params|
          params[:appid]         = options.client_id
          params[:response_type] = "code"
          params[:scope]         = "snsapi_login"
          # WeChat QR login requires #wechat_redirect fragment
        end
      end

      def token_params
        super.tap do |params|
          params[:appid]  = options.client_id
          params[:secret] = options.client_secret
        end
      end

      # WeChat token endpoint requires GET with query params.
      # Bypass oauth2 gem entirely to avoid POST-body issues.
      def build_access_token
        conn = Faraday.new(url: "https://api.weixin.qq.com") do |f|
          f.adapter Faraday.default_adapter
        end
        resp = conn.get("/sns/oauth2/access_token") do |req|
          req.params["appid"]      = options.client_id
          req.params["secret"]     = options.client_secret
          req.params["code"]       = request.params["code"]
          req.params["grant_type"] = "authorization_code"
        end
        data = JSON.parse(resp.body)
        raise "WeChat token error: #{data['errmsg']} (#{data['errcode']})" if data["errcode"]
        ::OAuth2::AccessToken.new(client, data["access_token"], data.merge("token" => data["access_token"]))
      end

      # Override callback_url to avoid issues with default oauth2 url building
      def callback_url
        full_host + script_name + callback_path
      end
    end
  end
end
