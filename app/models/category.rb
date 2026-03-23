class Category < ApplicationRecord
  extend FriendlyId
  friendly_id :name, use: :slugged

  TYPES = %w[video skill].freeze

  has_many :video_resources, dependent: :destroy
  has_many :skills, dependent: :destroy

  scope :for_video, -> { where(category_type: "video") }
  scope :for_skill, -> { where(category_type: "skill") }

  validates :name, presence: true, uniqueness: true
  validates :slug, presence: true, uniqueness: true
  validates :category_type, inclusion: { in: TYPES }

  def should_generate_new_friendly_id?
    name_changed?
  end

  # 公开课分类：所有人均可查看
  def free?
    name == "公开课"
  end
end
