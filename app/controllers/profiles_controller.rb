class ProfilesController < ApplicationController
  before_action :authenticate_user!
  # Allow viewing and editing profile even if profile is incomplete
  skip_before_action :require_profile_complete, only: [:show, :edit, :update]

  def show
    @user = current_user
    sync_location_from_law_firm
  end

  def edit
    @user = current_user
    sync_location_from_law_firm
  end

  def update
    @user = current_user
    profile = @user.profile || @user.build_profile

    # 更新 user name
    @user.update(name: params[:name]) if params[:name].present?

    # 解析律所：优先用选中的已有律所，否则用输入的文本自动创建
    company_name = resolve_company_name

    # 地区以律所为准：若选中已有律所且律所有地区，直接用律所地区
    firm = LawFirm.find_by(id: params[:law_firm_id]) if params[:law_firm_id].present?
    if firm&.province.present?
      province = firm.province
      city     = firm.city
      district = firm.district
    else
      province = params[:province]
      city     = params[:city]
      district = params[:district]
    end

    # 省市必填校验
    if province.blank? || city.blank?
      flash.now[:alert] = "请选择所在省份和城市"
      return render :edit, status: :unprocessable_entity
    end

    # 更新 profile 中可编辑的字段
    profile_attrs = { company: company_name }
    profile_attrs[:province] = province
    profile_attrs[:city]     = city
    profile_attrs[:district] = district

    if profile.update(profile_attrs)
      redirect_to profile_path, notice: "资料已更新"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def sync_location_from_law_firm
    firm = LawFirm.find_by(name: @user.profile&.company)
    return unless firm&.province.present?
    profile = @user.profile || @user.build_profile
    profile.province = firm.province
    profile.city     = firm.city
    profile.district = firm.district
  end

  def resolve_company_name
    # 用户从下拉选中了已有律所
    if params[:law_firm_id].present?
      firm = LawFirm.find_by(id: params[:law_firm_id])
      return firm.name if firm
    end

    # 用户手动输入了律所名
    company = params[:company].to_s.strip
    if company.present?
      # 自动 find_or_create，保证后台有记录，同时写入省市区
      firm = LawFirm.find_or_create_by(name: company)
      firm.update(
        province: params[:province].presence,
        city:     params[:city].presence,
        district: params[:district].presence
      ) if firm.province.blank? && params[:province].present?
      return company
    end

    nil
  end
end
