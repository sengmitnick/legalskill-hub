class DeliveredSkill < ApplicationRecord
  validates :name, presence: true

  scope :ordered, -> { order(:position, :id) }

  # 从 time_saved 解析小时数，× 2000 得出等值价值
  # 支持格式：「3h」「3 小时」「3.5h」「约 2 小时」等
  def equivalent_value
    return nil if time_saved.blank?
    hours = time_saved.to_s.scan(/\d+\.?\d*/).first&.to_f
    return nil if hours.nil? || hours == 0
    value = (hours * 2000).to_i
    "#{value.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\1,').reverse} 元"
  end

  before_create :set_position

  def move_up!
    prev = DeliveredSkill.ordered.where("position < ?", position).last
    return unless prev
    swap_positions!(prev)
  end

  def move_down!
    nxt = DeliveredSkill.ordered.where("position > ?", position).first
    return unless nxt
    swap_positions!(nxt)
  end

  private

  def set_position
    max = DeliveredSkill.maximum(:position) || 0
    self.position = max + 1
  end

  def swap_positions!(other)
    my_pos    = self.position
    other_pos = other.position
    update_column(:position, other_pos)
    other.update_column(:position, my_pos)
  end
end
