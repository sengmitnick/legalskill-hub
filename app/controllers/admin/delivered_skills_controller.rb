class Admin::DeliveredSkillsController < Admin::BaseController
  before_action :set_delivered_skill, only: [:edit, :update, :destroy, :move_up, :move_down]

  def index
    @delivered_skills = DeliveredSkill.ordered
  end

  def new
    @delivered_skill = DeliveredSkill.new
  end

  def create
    @delivered_skill = DeliveredSkill.new(delivered_skill_params)
    if @delivered_skill.save
      redirect_to admin_delivered_skills_path, notice: "技能已添加"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @delivered_skill.update(delivered_skill_params)
      redirect_to admin_delivered_skills_path, notice: "技能已更新"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @delivered_skill.destroy
    redirect_to admin_delivered_skills_path, notice: "技能已删除"
  end

  def move_up
    @delivered_skill.move_up!
    redirect_to admin_delivered_skills_path
  end

  def move_down
    @delivered_skill.move_down!
    redirect_to admin_delivered_skills_path
  end

  private

  def set_delivered_skill
    @delivered_skill = DeliveredSkill.find(params[:id])
  end

  def delivered_skill_params
    params.require(:delivered_skill).permit(:name, :scenario, :ai_completion, :demo_video_url)
  end
end
