class TimeSheetFormNormalizer

  INVERT_DATE_FORMAT = /\A\d{2}(\.|\/|\:|\-|\*)\d{2}(\.|\/|\:|\-|\*)\d{4}\Z/
  STRANGE_LOCALES = ["en-US","en_BZ","fil-PH","ar_SA","iu-Cans-CA"]

  def initialize params
    @params = params
  end

  def perform
    if @params.present?

      obj = {
          date_from:  normalize_date(@params[:date_from], @params[:locale]),
          date_to:    normalize_date(@params[:date_to], @params[:locale]),
          project_id: @params[:project_id],
          user_id:    @params[:user_id],
          group_by:   @params[:group_by]
      }

      begin
        if Date.parse(obj[:date_to]) < Date.parse(obj[:date_from])
          obj[:date_from], obj[:date_to] = obj[:date_to], obj[:date_from]
        end
      rescue

      end

      obj

    end
  end

  def normalize_date date, locale = ''
    if date.present? && ((date =~ INVERT_DATE_FORMAT) == 0)
      y, m, d = date.split(/\.|\/|\:|\-|\*|\~|\#/)
      y, m, d = [y, m, d].reverse if y.length == 2
      m, d = d, m if STRANGE_LOCALES.include?(locale)

      (y==nil ? "" : y) + (m==nil ? "" : "-" + m) + (d==nil ? "" : "-" + d)
    else
      date
    end
  end

end