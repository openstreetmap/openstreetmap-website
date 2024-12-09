class ApplicationJob < ActiveJob::Base
  discard_on ActiveJob::DeserializationError
end
