Rails.application.config.active_storage.queues.analysis = :storage
Rails.application.config.active_storage.queues.purge = :storage

Rails.configuration.after_initialize do
  ActiveStorage.service_urls_expire_in = 1.week
end
