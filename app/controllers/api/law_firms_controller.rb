class Api::LawFirmsController < ApplicationController
  skip_before_action :authenticate_user!
  skip_before_action :require_profile_complete

  # GET /api/law_firms/autocomplete?q=大成
  def autocomplete
    q = params[:q].to_s.strip
    if q.length >= 1
      firms = LawFirm.search_by_name(q).pluck(:id, :name)
      results = firms.map { |id, name| { id: id, name: name } }
    else
      results = []
    end
    render json: results
  end
end
