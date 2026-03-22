class DeliveredSkill < ApplicationRecord
  validates :name, presence: true

  scope :ordered, -> { order(:position, :id) }

  # ai_completion: 0-100 整数，表示 AI 能完成该技能的百分比

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
