# frozen_string_literal: true

class UniqueJob < ApplicationJob
  around_enqueue do |job, block|
    job_key = unique_job_key(*job.arguments)
    existing_job = SolidQueue::Job.scheduled.find_by(
      class_name: job.class.name,
      arguments: job.arguments.to_json
    )

    if existing_job.nil?
      Rails.logger.info("Enqueuing #{job.class.name} with key: #{job_key}")
      block.call # enqueue the job
    else
      Rails.logger.info("Skipping #{job.class.name} with key: #{job_key} because it is already scheduled")
    end
  end

  def perform(...)
    raise NotImplementedError, "#{self.class} must implement #perform method"
  end

  private

  # Override this method in subclasses to define custom unique key logic
  def unique_job_key(*args)
    args.join('-')
  end
end
