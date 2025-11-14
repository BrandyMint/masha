# frozen_string_literal: true

# Запись о затраченном времени на проект. Содержит дату, количество часов,
# привязку к проекту и пользователю. Отправляет уведомления при создании.
class TimeShift < ApplicationRecord
  include Authority::Abilities

  self.authorizer_name = 'TimeShiftAuthorizer'

  scope :ordered, -> { order 'date desc, created_at desc' }
  scope :this_day, -> { where ['created_at >= ?', Time.zone.today - 24.hours] }

  belongs_to :project
  belongs_to :user

  validates :project, presence: true
  validates :user, presence: true
  validates :date, timeliness: { on_or_before: -> { Time.zone.today }, type: :date }
  validates :hours, presence: true, numericality: { greater_than_or_equal_to: 0.1 }

  after_commit on: :create do
    ViewerMailer.new_time_shift_email(self).deliver_later
  end
end
