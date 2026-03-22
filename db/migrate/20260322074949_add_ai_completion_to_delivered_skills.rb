class AddAiCompletionToDeliveredSkills < ActiveRecord::Migration[7.2]
  def change
    add_column :delivered_skills, :ai_completion, :integer
    remove_column :delivered_skills, :time_saved, :string
    remove_column :delivered_skills, :cost_saved, :string
  end
end
