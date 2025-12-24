# frozen_string_literal: true

module Users
  class HeatmapsController < ApplicationController
    layout false

    before_action :authorize_web
    before_action :set_locale
    before_action :check_database_readable

    authorize_resource :user

    def show
      @user = User.find_by(:display_name => params[:user_display_name])

      if @user&.public_heatmap? && (@user.visible? || current_user&.administrator?)
        @heatmap_data = Rails.cache.fetch("heatmap_data_of_user_#{@user.id}", :expires_at => Time.zone.now.end_of_day) do
          from = 1.year.ago.beginning_of_day
          to = Time.zone.now.end_of_day

          mapped = Changeset
                   .where(:user_id => @user.id)
                   .where(:created_at => from..to)
                   .where(:num_changes => 1..)
                   .group("date_trunc('day', created_at)")
                   .select("date_trunc('day', created_at) AS date, SUM(num_changes) AS total_changes, MAX(id) AS max_id")
                   .order(:date)
                   .map do |changeset|
                     {
                       :date => changeset.date.to_date,
                       :total_changes => changeset.total_changes.to_i,
                       :max_id => changeset.max_id
                     }
                   end

          {
            :count => mapped.sum { |entry| entry[:total_changes] },
            :data => mapped.index_by { |entry| entry[:date] },
            :from => from,
            :to => to
          }
        end
      else
        head :not_found
      end
    end
  end
end
