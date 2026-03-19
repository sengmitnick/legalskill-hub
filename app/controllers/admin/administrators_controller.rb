class Admin::AdministratorsController < Admin::BaseController
  before_action :set_administrator, only: [:show, :edit, :update, :destroy]
  before_action :ensure_super_admin, except: [:index, :show]

  def index
    @administrators = Administrator.order(created_at: :desc).page(params[:page]).per(10)
  end

  def show
  end

  def new
    @administrator = Administrator.new
  end

  def create
    @administrator = Administrator.new(administrator_params)
    @administrator.first_login = false if @administrator.name == 'admin'

    if @administrator.save
      redirect_to admin_administrator_path(@administrator), notice: '管理员已创建'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    # Redirect to account edit page if editing self
    if @administrator == current_admin
      redirect_to edit_admin_account_path, notice: '请在账号设置中修改自己的信息'
    end
  end

  def update
    # Remove empty password parameters if not changing password
    update_params = administrator_params
    if update_params[:password].blank?
      update_params = update_params.except(:password, :password_confirmation)
    end

    if @administrator.update(update_params)
      redirect_to admin_administrator_path(@administrator), notice: '管理员信息已更新'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    unless @administrator.can_be_deleted_by?(current_admin)
      redirect_to admin_administrators_path, alert: '该管理员无法删除'
      return
    end

    @administrator.destroy
    redirect_to admin_administrators_path, notice: '管理员已删除'
  end

  private

  def set_administrator
    @administrator = Administrator.find(params[:id])
  end

  def administrator_params
    permitted_params = [:name, :password, :password_confirmation]
    # Only super admins can set roles
    permitted_params << :role if current_admin.can_manage_administrators?
    params.require(:administrator).permit(permitted_params)
  end

  def ensure_super_admin
    unless current_admin.can_manage_administrators?
      redirect_to admin_administrators_path, alert: '权限不足，需要超级管理员权限'
    end
  end

end
