class SiteSetting < ApplicationRecord
  validates :key, presence: true, uniqueness: true
  validates :value, presence: true

  CACHE_TTL = 10.minutes

  # 快捷读取（带缓存）：SiteSetting.cached("hero_video_url")
  def self.cached(key)
    Rails.cache.fetch("site_setting:#{key}", expires_in: CACHE_TTL) do
      find_by(key: key)&.value
    end
  end

  # 无缓存读取（需要实时值时用）：SiteSetting.get("key")
  def self.get(key)
    find_by(key: key)&.value
  end

  # 快捷写入 + 清缓存：SiteSetting.set("hero_video_url", "https://...")
  def self.set(key, value)
    record = find_or_initialize_by(key: key)
    record.value = value
    record.save!
    Rails.cache.delete("site_setting:#{key}")
    value
  end

  # 写入后自动清对应缓存
  after_commit :expire_cache

  private

  def expire_cache
    Rails.cache.delete("site_setting:#{key}")
  end
end
