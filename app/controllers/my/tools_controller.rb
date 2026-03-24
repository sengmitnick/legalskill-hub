module My
  class ToolsController < ApplicationController
    before_action :authenticate_user!

    def show
      @serial_keys = current_user.serial_keys.order(created_at: :desc)
    end
  end
end
