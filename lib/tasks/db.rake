# frozen_string_literal: true

namespace :db do
  task load_queue_schema: :environment do
    ActiveRecord::Base.establish_connection(:queue)
    load Rails.root.join('db/queue_schema.rb')
  end
end
