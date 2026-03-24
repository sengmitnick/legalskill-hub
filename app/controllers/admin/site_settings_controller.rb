class Admin::SiteSettingsController < Admin::BaseController
  EDITABLE_KEYS = %w[
    install_cmd_mac
    install_cmd_win
    uninstall_cmd_mac
    uninstall_cmd_win
  ].freeze

  def index
    @settings = EDITABLE_KEYS.map do |key|
      { key: key, value: SiteSetting.get(key) || "" }
    end
  end

  def update
    key   = params[:key]
    value = params[:value].to_s.strip

    unless EDITABLE_KEYS.include?(key)
      return redirect_to admin_site_settings_path, alert: "不允许修改该配置项"
    end

    SiteSetting.set(key, value)
    redirect_to admin_site_settings_path, notice: "「#{key}」已更新"
  end
end
