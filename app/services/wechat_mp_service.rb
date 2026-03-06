# Handles WeChat Official Account (公众号) API interactions:
# - access_token management with Rails.cache
# - Temporary QR code generation
# - Webhook signature verification
# - Scan result caching (ticket → openid)
class WechatMpService
  MP_API_BASE = "https://api.weixin.qq.com/cgi-bin"
  TICKET_CACHE_TTL = 305.seconds  # QR code expires in 300s, keep a bit longer
  ACCESS_TOKEN_TTL = 7000.seconds # WeChat token expires in 7200s

  def initialize
    @appid     = ENV.fetch("WECHAT_MP_APPID", "")
    @appsecret = ENV.fetch("WECHAT_MP_APPSECRET", "")
    @token     = ENV.fetch("WECHAT_MP_TOKEN", "")
  end

  # Verify WeChat server signature (GET webhook)
  def valid_signature?(timestamp, nonce, signature)
    arr = [ @token, timestamp, nonce ].sort
    Digest::SHA1.hexdigest(arr.join) == signature
  end

  # Fetch (or refresh) access_token, cached to avoid rate limits
  def access_token
    Rails.cache.fetch("wechat_mp:access_token", expires_in: ACCESS_TOKEN_TTL) do
      fetch_access_token
    end
  end

  # Create a temporary QR code scene (expires in 60s)
  # Returns { ticket:, url:, expire_seconds: }
  def create_qrcode
    uri  = URI("#{MP_API_BASE}/qrcode/create?access_token=#{access_token}")
    body = {
      expire_seconds: 300,
      action_name: "QR_STR_SCENE",
      action_info: { scene: { scene_str: SecureRandom.hex(16) } }
    }.to_json

    response = direct_http_post(uri, body, "Content-Type" => "application/json")
    data = JSON.parse(response.body)

    raise "WeChat QR error: #{data['errmsg']}" if data["errcode"].present? && data["errcode"] != 0

    { ticket: data["ticket"], url: data["url"], expire_seconds: data["expire_seconds"] }
  end

  # Store openid for a given ticket (called from webhook on SCAN/subscribe event)
  def store_scan_result(ticket, openid)
    Rails.cache.write(scan_cache_key(ticket), openid, expires_in: TICKET_CACHE_TTL)
  end

  # Retrieve openid for a ticket (called by frontend polling)
  # Returns openid string or nil
  def fetch_scan_result(ticket)
    Rails.cache.read(scan_cache_key(ticket))
  end

  private

  def fetch_access_token
    uri = URI("#{MP_API_BASE}/token?grant_type=client_credential&appid=#{@appid}&secret=#{@appsecret}")
    response = direct_http_get(uri)
    data = JSON.parse(response.body)
    raise "WeChat token error: #{data['errmsg']}" unless data["access_token"]
    data["access_token"]
  end

  def scan_cache_key(ticket)
    "wechat_mp:scan:#{ticket}"
  end

  # Bypass macOS/system proxy — always connect directly to WeChat API
  def direct_http_get(uri)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = (uri.scheme == "https")
    http.get(uri.request_uri)
  end

  def direct_http_post(uri, body, headers = {})
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = (uri.scheme == "https")
    http.post(uri.request_uri, body, headers)
  end
end
