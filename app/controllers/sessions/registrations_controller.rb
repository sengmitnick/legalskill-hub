# This app uses WeChat login - traditional email registration is not supported.
# This controller exists to satisfy route helpers (sign_up_path) used in specs.
class Sessions::RegistrationsController < ApplicationController
  skip_before_action :authenticate_user!, raise: false
  skip_before_action :require_profile_complete, raise: false

  def create
    redirect_to root_path
  end
end
