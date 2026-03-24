module Admin
  class UsersController < BaseController
    before_action :set_user, only: [:show]

    def index
      @users = User.order(created_at: :desc)
                   .page(params[:page])
                   .per(10)

      # Search by name or phone
      if params[:q].present?
        @users = @users.joins("LEFT JOIN user_profiles ON user_profiles.user_id = users.id")
                       .where("users.name ILIKE ? OR user_profiles.phone ILIKE ?", "%#{params[:q]}%", "%#{params[:q]}%")
      end

      # Calculate statistics
      calculate_statistics
    end

    def show
      # View-only - users should be managed through the user-facing interface
    end

    private

    def set_user
      @user = User.find(params[:id])
    end

    def calculate_statistics
      # Today's new users
      @today_users_count = User.where('created_at >= ?', Time.current.beginning_of_day).count

      # This month's new users
      @this_month_users_count = User.where('created_at >= ?', Time.current.beginning_of_month).count

      # Active users (users with sessions in the last 7 days)
      @active_users_count = User.joins(:sessions)
                                .where('sessions.created_at >= ?', 7.days.ago)
                                .distinct
                                .count

      # Total users
      @total_users_count = User.count
    end
  end
end
