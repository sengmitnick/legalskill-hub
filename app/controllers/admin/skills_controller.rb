class Admin::SkillsController < Admin::BaseController
  before_action :set_skill, only: [:show, :edit, :update, :destroy]

  def index
    @skills = Skill.page(params[:page]).per(10)
  end

  def show
  end

  def new
    @skill = Skill.new
    @skill_categories = Category.for_skill.order(:name)
  end

  def create
    @skill = Skill.new(skill_params)

    if @skill.save
      redirect_to admin_skill_path(@skill), notice: '技能已创建'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @skill_categories = Category.for_skill.order(:name)
  end

  def update
    if @skill.update(skill_params)
      redirect_to admin_skill_path(@skill), notice: '技能已更新'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @skill.destroy
    redirect_to admin_skills_path, notice: '技能已删除'
  end

  private

  def set_skill
    @skill = Skill.find(params[:id])
  end

  def skill_params
    params.require(:skill).permit(:title, :description, :price, :author_name, :template_count, :download_count, :rating, :slug, :category_id)
  end
end
