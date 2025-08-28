# frozen_string_literal: true

namespace :db do
  desc 'Load cache schema'
  task load_cache_schema: :environment do
    ActiveRecord::Base.establish_connection(:cache)
    load Rails.root.join('db/cache_schema.rb')
  end

  desc 'Load cable schema'
  task load_cable_schema: :environment do
    ActiveRecord::Base.establish_connection(:cable)
    load Rails.root.join('db/cable_schema.rb')
  end

  desc 'Load queue schema'
  task load_queue_schema: :environment do
    ActiveRecord::Base.establish_connection(:queue)
    load Rails.root.join('db/queue_schema.rb')
  end
end
