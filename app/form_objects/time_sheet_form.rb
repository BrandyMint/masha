class TimeSheetForm < FormObjectBase

  GROUP_BY = [:project, :person]

  property :date_from
  property :date_to
  property :project_id
  property :user_id
  property :group_by


  validates :date_from, :date_to, presence: true, if: lambda{ |form| form.project_id.blank? && form.user_id.blank? }
  validates :project_id, presence: true, if: lambda{ |form| form.date_from.blank? && form.date_to.blank? && form.user_id.blank? }
  validates :user_id, presence: true, if: lambda{ |form| form.date_from.blank? && form.date_to.blank? && form.project_id.blank? }

  validate :validate_date_from, :validate_date_to


  def initialize args
    super args
  end

  def self.build_from_params params
    self.new TimeSheetFormNormalizer.new(params).perform
  end


  private

    def validate_date_from
      if self.date_from.present?
        begin
          Date.parse self.date_from
        rescue
          errors.add(:date_from, I18n.t('simple_form.error_notification.date_invalid'))
        end

      end
    end

    def validate_date_to
      if self.date_to.present?
        begin
          Date.parse self.date_to
        rescue
          errors.add(:date_to, I18n.t('simple_form.error_notification.date_invalid'))
        end
      end
    end

end
