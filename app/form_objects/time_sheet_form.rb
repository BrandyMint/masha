class TimeSheetForm < FormObjectBase

  #STRANGE_LOCALES = ["en-US","en_BZ","fil-PH","ar_SA","iu-Cans-CA"]

  #INVERT_DATE_FORMAT = /\A\d{2}(\.|\/|\:|\-|\*)\d{2}(\.|\/|\:|\-|\*)\d{4}\Z/

  NORMAL_DATE_FORMAT = /\A\d{4}(\.|\/|\:|\-|\*)(?:0?[1-9]|1[0-2])(\.|\/|\:|\-|\*)(?:0?[1-9]|1[0-9]|2[0-9]|3[0-1])\Z/

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
    if valid?
      if self.date_to.present? && self.date_from.present? && Date.parse(self.date_to)<Date.parse(self.date_from)
        self.date_to, self.date_from = self.date_from, self.date_to
      end
    end
  end

  def self.build_from_params params
    self.new TimeSheetFormNormalizer.new(params).perform
  end


  private

    def validate_date_from
      if self.date_from.present?
        errors.add(:date_from, I18n.t('simple_form.error_notification.date_invalid')) if ((self.date_from =~ NORMAL_DATE_FORMAT) != 0)
      end
    end

    def validate_date_to
      if self.date_to.present?
        errors.add(:date_to, I18n.t('simple_form.error_notification.date_invalid')) if ((self.date_to =~ NORMAL_DATE_FORMAT) != 0)
      end
    end

end
