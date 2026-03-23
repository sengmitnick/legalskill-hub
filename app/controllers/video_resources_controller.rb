class VideoResourcesController < ApplicationController
  before_action :set_video_resource, only: [:show]
  before_action :check_premium_access, only: [:show]

  def index
    @categories = Category.for_video.order(:name)
    @videos = VideoResource.includes(:category).order(created_at: :desc)

    if params[:category].present?
      category = Category.for_video.friendly.find(params[:category])
      @videos = @videos.where(category: category)
    end

    @videos = @videos.page(params[:page]).per(12)
  end

  def show
    @video.increment_views!
    @related_videos = @video.category.video_resources.where.not(id: @video.id).limit(3)
  end

  private

  def set_video_resource
    @video = VideoResource.find(params[:id])
  end

  # 进阶课程需要 plan2/3/4 已付款；公开课所有人可看
  def check_premium_access
    return if @video.free?
    return if user_signed_in? && current_user.has_premium_video_access?

    redirect_to video_resources_path, alert: "此视频为进阶课程，需购买线上课程、线下课程或团队内训后才能观看。"
  end
end
