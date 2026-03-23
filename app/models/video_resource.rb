class VideoResource < ApplicationRecord
  belongs_to :category

  validate :category_must_be_video_type

  validates :title, presence: true
  validates :bilibili_url, allow_blank: true, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]), message: "must be a valid URL" }
  validates :category, presence: true
  validates :views_count, numericality: { greater_than_or_equal_to: 0 }

  # 保存后自动抓取B站封面（仅当 cover_image 为空 或 bilibili_url 变更时）
  after_save :auto_fetch_bilibili_cover, if: :should_fetch_cover?

  # 公开课：所有人可看；进阶课：需要 plan2/3/4 已付款
  def free?
    category.free?
  end

  def increment_views!
    increment!(:views_count)
  end

  # 返回封面URL：优先用已存入的 cover_image，否则回退到默认占位图
  # 同时将 http:// 转换为 https:// 避免浏览器混合内容拦截
  def cover_image_url
    url = cover_image.presence || "https://images.unsplash.com/photo-1505664194779-8beaceb93744?w=600&h=340&fit=crop&q=80"
    url.gsub(/\Ahttp:\/\//, "https://")
  end

  # 从 bilibili_url 解析出 bvid（支持多种URL格式）
  def extract_bvid
    return nil if bilibili_url.blank?

    # 支持格式：
    # https://www.bilibili.com/video/BV1xx411c7mD
    # https://www.bilibili.com/video/BV1xx411c7mD/
    # https://b23.tv/BV1xx411c7mD
    # https://www.bilibili.com/video/BV1xx411c7mD?p=1
    uri = URI.parse(bilibili_url) rescue nil
    return nil unless uri

    path = uri.path.to_s
    # 匹配 /video/BVxxxxxxxxx 格式
    if (match = path.match(%r{/video/(BV[a-zA-Z0-9]+)}))
      return match[1]
    end

    # 匹配短链 b23.tv/BVxxxxxx
    if (match = path.match(%r{/(BV[a-zA-Z0-9]+)}))
      return match[1]
    end

    nil
  end

  # 调用B站API获取封面URL
  def fetch_bilibili_cover_url
    bvid = extract_bvid
    return nil if bvid.blank?

    begin
      uri = URI.parse("https://api.bilibili.com/x/web-interface/view?bvid=#{bvid}")
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.open_timeout = 5
      http.read_timeout = 5

      request = Net::HTTP::Get.new(uri.request_uri)
      # 加 User-Agent 避免被拒绝
      request["User-Agent"] = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36"
      request["Referer"] = "https://www.bilibili.com"

      response = http.request(request)

      if response.code == "200"
        data = JSON.parse(response.body)
        if data["code"] == 0 && data.dig("data", "pic").present?
          return data["data"]["pic"]
        end
      end
    rescue => e
      Rails.logger.error "[VideoResource] 获取B站封面失败 (#{bilibili_url}): #{e.message}"
    end

    nil
  end

  private

  def category_must_be_video_type
    return unless category
    errors.add(:category, "必须是视频分类") unless category.category_type == "video"
  end

  def should_fetch_cover?
    # 只有 cover_image 为空时才自动抓取
    # 如果管理员手动填写了 cover_image，则不覆盖
    cover_image.blank?
  end

  def auto_fetch_bilibili_cover
    cover_url = fetch_bilibili_cover_url
    if cover_url.present?
      # 统一转换为 https:// 避免混合内容问题
      cover_url = cover_url.gsub(/\Ahttp:\/\//, "https://")
      # 使用 update_column 避免再次触发 callbacks
      update_column(:cover_image, cover_url)
      Rails.logger.info "[VideoResource] 已自动获取B站封面: #{cover_url}"
    end
  end
end
