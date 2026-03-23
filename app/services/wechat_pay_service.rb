require "net/http"
require "openssl"
require "json"
require "base64"
require "securerandom"

# Encapsulates WeChat Pay APIv3 Native + JSAPI payment flows.
# Uses OpenSSL RSA-SHA256 signature scheme required by WeChat Pay v3 API.
class WechatPayService
  API_BASE    = "https://api.mch.weixin.qq.com"
  NATIVE_URL  = "/v3/pay/transactions/native"
  JSAPI_URL   = "/v3/pay/transactions/jsapi"
  QUERY_URL   = "/v3/pay/transactions/out-trade-no/%s"

  def initialize
    @appid      = ENV.fetch("WECHAT_MP_APPID", "")
    @mch_id     = ENV.fetch("WECHAT_PAY_MCH_ID", "")
    @api_v3_key = ENV.fetch("WECHAT_PAY_API_V3_KEY", "")
    @cert_path  = ENV.fetch("WECHAT_PAY_CERT_PATH", "")
    @notify_url = ENV.fetch("WECHAT_PAY_NOTIFY_URL", "")
  end

  # Entry point for generic service call pattern
  def call
    self
  end

  private

  def load_certs!
    return if @private_key

    @private_key = OpenSSL::PKey::RSA.new(File.read(File.join(@cert_path, "apiclient_key.pem")))
    @public_key  = OpenSSL::PKey::RSA.new(File.read(File.join(@cert_path, "pub_key.pem")))
    @serial      = extract_serial(File.join(@cert_path, "apiclient_cert.pem"))
  end

  public

  # Create a Native payment order. Returns { code_url:, out_trade_no: }
  def create_native_order(out_trade_no:, amount:, description:)
    body = {
      appid:        @appid,
      mchid:        @mch_id,
      description:  description,
      out_trade_no: out_trade_no,
      notify_url:   @notify_url,
      amount:       { total: amount, currency: "CNY" }
    }

    response = post(NATIVE_URL, body)
    raise "WeChat Pay error: #{response['message'] || response.inspect}" unless response["code_url"]

    { code_url: response["code_url"], out_trade_no: out_trade_no }
  end

  # Create a JSAPI payment order (for WeChat in-app H5 pages).
  # openid must be the user's openid under the MP appid (公众号 appid).
  # Returns { prepay_id:, out_trade_no: }
  def create_jsapi_order(out_trade_no:, amount:, description:, openid:)
    body = {
      appid:        @appid,
      mchid:        @mch_id,
      description:  description,
      out_trade_no: out_trade_no,
      notify_url:   @notify_url,
      amount:       { total: amount, currency: "CNY" },
      payer:        { openid: openid }
    }

    response = post(JSAPI_URL, body)
    raise "WeChat Pay JSAPI error: #{response['message'] || response.inspect}" unless response["prepay_id"]

    { prepay_id: response["prepay_id"], out_trade_no: out_trade_no }
  end

  # Generate the JSAPI payment parameters for WeixinJSBridge.invoke on the frontend.
  # Signature uses RSA-SHA256 (v3 spec), NOT MD5.
  def generate_jsapi_params(prepay_id)
    load_certs!
    timestamp  = Time.now.to_i.to_s
    nonce_str  = SecureRandom.hex(16)
    package    = "prepay_id=#{prepay_id}"
    # Signing string per WeChat Pay v3 JSAPI spec
    message    = "#{@appid}\n#{timestamp}\n#{nonce_str}\n#{package}\n"
    pay_sign   = Base64.strict_encode64(@private_key.sign(OpenSSL::Digest::SHA256.new, message))

    {
      appId:     @appid,
      timeStamp: timestamp,
      nonceStr:  nonce_str,
      package:   package,
      signType:  "RSA",
      paySign:   pay_sign
    }
  end

  # Query order status from WeChat API.
  def query_order(out_trade_no)
    path = format(QUERY_URL, out_trade_no) + "?mchid=#{@mch_id}"
    get(path)
  end

  # Decrypt and verify the async notify callback from WeChat.
  # Returns the decrypted resource hash on success, raises on failure.
  def decrypt_notify(headers:, body_str:)
    timestamp = headers["wechatpay-timestamp"]
    nonce     = headers["wechatpay-nonce"]
    signature = headers["wechatpay-signature"]

    raise "Missing WeChat Pay headers" unless timestamp && nonce && signature

    verify_signature!(timestamp: timestamp, nonce: nonce, body: body_str, signature: signature)

    payload  = JSON.parse(body_str)
    resource = payload["resource"]
    decrypt_resource(
      ciphertext:      resource["ciphertext"],
      nonce:           resource["nonce"],
      associated_data: resource["associated_data"]
    )
  end

  private

  # AES-256-GCM decryption of notify resource
  def decrypt_resource(ciphertext:, nonce:, associated_data:)
    decoded    = Base64.strict_decode64(ciphertext)
    tag        = decoded[-16..]
    ciphertext = decoded[0...-16]

    decipher = OpenSSL::Cipher.new("aes-256-gcm")
    decipher.decrypt
    decipher.key             = @api_v3_key
    decipher.iv              = nonce
    decipher.auth_tag        = tag
    decipher.auth_data       = associated_data

    plaintext = decipher.update(ciphertext) + decipher.final
    JSON.parse(plaintext)
  end

  # Verify WeChat Pay callback signature using pub_key.pem
  def verify_signature!(timestamp:, nonce:, body:, signature:)
    load_certs!
    message = "#{timestamp}\n#{nonce}\n#{body}\n"
    digest  = OpenSSL::Digest::SHA256.new
    valid   = @public_key.verify(digest, Base64.strict_decode64(signature), message)
    raise "WeChat Pay signature verification failed" unless valid
  end

  def post(path, body)
    uri  = URI("#{API_BASE}#{path}")
    http = build_http(uri)
    req  = Net::HTTP::Post.new(uri.path, build_headers("POST", path, body.to_json))
    req.body         = body.to_json
    req.content_type = "application/json"
    parse_response(http.request(req))
  end

  def get(path)
    uri  = URI("#{API_BASE}#{path}")
    http = build_http(uri)
    req  = Net::HTTP::Get.new(uri.request_uri, build_headers("GET", path, ""))
    parse_response(http.request(req))
  end

  def build_http(uri)
    http             = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl     = true
    http.verify_mode = OpenSSL::SSL::VERIFY_PEER
    http
  end

  def parse_response(response)
    JSON.parse(response.body)
  rescue JSON::ParserError
    { "error" => response.body }
  end

  # Build Authorization header per WeChat Pay v3 spec
  def build_headers(method, path, body)
    load_certs!
    nonce_str  = SecureRandom.hex(16)
    timestamp  = Time.now.to_i.to_s
    message    = "#{method}\n#{path}\n#{timestamp}\n#{nonce_str}\n#{body}\n"
    signature  = Base64.strict_encode64(@private_key.sign(OpenSSL::Digest::SHA256.new, message))
    auth       = %Q(WECHATPAY2-SHA256-RSA2048 mchid="#{@mch_id}",nonce_str="#{nonce_str}",signature="#{signature}",timestamp="#{timestamp}",serial_no="#{@serial}")

    {
      "Authorization"  => auth,
      "Accept"         => "application/json",
      "Content-Type"   => "application/json",
      "User-Agent"     => "legalskill-hub/1.0"
    }
  end

  def extract_serial(cert_path)
    cert = OpenSSL::X509::Certificate.new(File.read(cert_path))
    cert.serial.to_s(16).upcase
  end
end
