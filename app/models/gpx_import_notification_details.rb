# frozen_string_literal: true

class GpxImportNotificationDetails
  class Details
    def initialize(notification)
      @notification = notification
    end

    delegate :record, :to => :@notification
  end

  class Success < Details
    delegate :description, :tagstring, :to => :record

    def filename
      record.name
    end

    def num_tags
      record.tags.length
    end

    def possible_points
      @notification.params[:possible_points]
    end

    def trace_points
      record.size
    end
  end

  class Failure < Details
    def filename
      @notification.params[:trace_name]
    end

    def description
      @notification.params[:trace_description]
    end

    def num_tags
      tags.count
    end

    def tags
      @notification.params[:trace_tags]
    end

    def tagstring
      tags.join(", ")
    end

    def possible_points
      nil
    end

    def trace_points
      nil
    end
  end
end
