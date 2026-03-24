class Api::LawFirmsController < ApplicationController
  skip_before_action :authenticate_user!
  skip_before_action :require_profile_complete

  # GET /api/law_firms/autocomplete?q=大成
  def autocomplete
    q = params[:q].to_s.strip
    if q.length >= 1
      firms = LawFirm.search_by_name(q).pluck(:id, :name, :province, :city, :district)
      results = firms.map { |id, name, province, city, district| { id: id, name: name, province: province, city: city, district: district } }
    else
      results = []
    end
    render json: results
  end
end
