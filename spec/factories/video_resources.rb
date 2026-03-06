FactoryBot.define do
  factory :video_resource do
    title { "MyString" }
    bilibili_url { "https://www.bilibili.com/video/BV1234567890" }
    duration { "45:20" }
    views_count { 1 }
    association :category, category_type: "video"
  end
end
