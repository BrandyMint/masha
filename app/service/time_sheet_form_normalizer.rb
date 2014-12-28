class TimeSheetFormNormalizer

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
    return if date.blank?

    #приводим к виду dd-mm-yy
    d, m, y = date.split(/[\.\/\:\-\*\~\#]/)
    d, m, y = [d, m, y].reverse if d.length == 4
    src_date = [d, m, y].reject(&:blank?).join('-')

    Date.parse( src_date ).to_s

  rescue

    date_by_locale src_date, locale

  end


  def date_by_locale d, locale
    return d unless STRANGE_LOCALES.include?(locale)
    Date.strptime(d, '%m-%d-%Y').to_s
  rescue
    d
  end

end