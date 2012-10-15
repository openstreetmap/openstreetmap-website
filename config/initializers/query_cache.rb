# encoding: utf-8

Rails.configuration.middleware.delete ActiveRecord::QueryCache
