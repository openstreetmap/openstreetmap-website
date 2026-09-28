# frozen_string_literal: true

class ApplicationNotifier < Noticed::Event
  notification_methods do
    def record_required?
      true
    end
  end
end
