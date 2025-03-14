class DateRange
  attr_reader :start_date, :end_date

  def initialize(start_date, end_date)
    @start_date = start_date
    @end_date = end_date
  end

  def to_s
    parsed_start_date = start_date && Date.new(start_date.to_i)
    parsed_end_date = end_date && Date.new(end_date.to_i)
    printable_start_date = printable_date(parsed_start_date, parsed_start_date && parsed_start_date.year < 1)
    printable_end_date = printable_date(parsed_end_date, (parsed_start_date && parsed_start_date.year < 1) || (parsed_end_date && parsed_end_date.year < 1))

    if printable_start_date == printable_end_date
      dates = printable_start_date
    else
      dates = I18n.t "date.formats.range", :start => printable_start_date, :end => printable_end_date
    end
  end

  def printable_date(parsed_date, era)
    if parsed_date
      format = "date.formats.brief"
      if era
        format = parsed_date.year > 0 ? "date.formats.brief_ce" : "date.formats.brief_bce"
      end
      if parsed_date.year < 1
        parsed_date = Date.new(1 - parsed_date.year)
      end
      I18n.t format, :year => "%d" % parsed_date.year
    else
      ""
    end
  end
end
