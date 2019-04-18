defmodule Cldr.Calendar.Julian do
  @behaviour Calendar
  @behaviour Cldr.Calendar

  @type year :: -9999..-1 | 1..9999
  @type month :: 1..12
  @type day :: 1..31

  @quarters_in_year 4
  @months_in_year 12
  @months_in_quarter 3
  @days_in_week 7

  @doc """
  Defines the CLDR calendar type for this calendar.

  This type is used in support of `Cldr.Calendar.localize/3`.
  Currently only `:gregorian` is supported.

  """
  @impl true

  def cldr_calendar_type do
    :gregorian
  end

  @epoch Cldr.Calendar.Gregorian.date_to_iso_days(0, 12, 30)
  def epoch do
    @epoch
  end

  @doc """
  Determines if the date given is valid according to this calendar.

  """
  @impl true

  def valid_date?(0, _month, _day) do
    false
  end

  @months_with_30_days [4, 6, 9, 11]
  def valid_date?(_year, month, day) when month in @months_with_30_days and day in 1..30 do
    true
  end

  @months_with_31_days [1, 3, 5, 7, 8, 10, 12]
  def valid_date?(_year, month, day) when month in @months_with_31_days and day in 1..31 do
    true
  end

  def valid_date?(year, 2, 29) do
    if leap_year?(year), do: true, else: false
  end

  def valid_date?(_year, 2, day) when day in 1..28 do
    true
  end

  def valid_date?(_year, _month, _day) do
    false
  end

  @doc """
  Calculates the year and era from the given `year`.
  The ISO calendar has two eras: the current era which
  starts in year 1 and is defined as era "1". And a
  second era for those years less than 1 defined as
  era "0".

  """
  @spec year_of_era(year) :: {year, era :: 0..1}
  @impl true

  def year_of_era(year) when year > 0 do
    {year, 1}
  end

  def year_of_era(year) when year < 0 do
    {abs(year), 0}
  end

  @doc """
  Calculates the quarter of the year from the given `year`, `month`, and `day`.
  It is an integer from 1 to 4.

  """
  @spec quarter_of_year(year, month, day) :: 1..4
  @impl true

  def quarter_of_year(_year, month, _day) do
    Float.ceil(month / @months_in_quarter)
    |> trunc
  end

  @doc """
  Calculates the month of the year from the given `year`, `month`, and `day`.
  It is an integer from 1 to 12.

  """
  @spec month_of_year(year, month, day) :: month
  @impl true

  def month_of_year(_year, month, _day) do
    month
  end

  @doc """
  Calculates the week of the year from the given `year`, `month`, and `day`.
  It is an integer from 1 to 53.

  """
  @spec week_of_year(year, month, day) :: {:error, :not_defined}
  @impl true

  def week_of_year(_year, _month, _day) do
    {:error, :not_defined}
  end

  @doc """
  Calculates the ISO week of the year from the given `year`, `month`, and `day`.
  It is an integer from 1 to 53.

  """
  @spec iso_week_of_year(year, month, day) :: {:error, :not_defined}
  @impl true

  def iso_week_of_year(_year, _month, _day) do
    {:error, :not_defined}
  end

  @doc """
  Calculates the day and era from the given `year`, `month`, and `day`.

  """
  @spec day_of_era(year, month, day) :: {day :: pos_integer(), era :: 0..1}
  @impl true

  def day_of_era(year, month, day) do
    {_, era} = year_of_era(year)
    days = date_to_iso_days(year, month, day)
    {days + epoch(), era}
  end

  @doc """
  Calculates the day of the year from the given `year`, `month`, and `day`.

  """
  @spec day_of_year(year, month, day) :: 1..366
  @impl true

  def day_of_year(year, month, day) do
    first_day = date_to_iso_days(year, 1, 1)
    this_day = date_to_iso_days(year, month, day)
    this_day - first_day + 1
  end

  @doc """
  Calculates the day of the week from the given `year`, `month`, and `day`.
  It is an integer from 1 to 7, where 1 is Monday and 7 is Sunday.

  """
  @spec day_of_week(year, month, day) :: 1..7
  @impl true

  @epoch_day_of_week 6
  def day_of_week(year, month, day) do
    days = date_to_iso_days(year, month, day)
    days_after_saturday = rem(days, 7)
    Cldr.Math.amod(days_after_saturday + @epoch_day_of_week, @days_in_week)
  end

  @doc """
  Calculates the number of period in a given `year`. A period
  corresponds to a month in month-based calendars and
  a week in week-based calendars..

  """
  def periods_in_year(_year) do
    @months_in_year
  end

  @doc """
  Returns the number days in a given year.

  """
  @impl true

  def days_in_year(year) do
    if leap_year?(year), do: 366, else: 365
  end

  @doc """
  Returns how many days there are in the given year-month.

  """
  @spec days_in_month(year, month) :: 28..31
  @impl true

  def days_in_month(year, 2) do
    if leap_year?(year), do: 29, else: 28
  end

  def days_in_month(_year, month) when month in @months_with_30_days do
    30
  end

  def days_in_month(_year, month) when month in @months_with_31_days do
    31
  end

  @doc """
  Returns the number days in a a week.

  """
  def days_in_week do
    @days_in_week
  end

  @doc """
  Returns a `Date.Range.t` representing
  a given year.

  """
  @impl true

  def year(year) do
    last_month = months_in_year(year)
    days_in_last_month = days_in_month(year, last_month)

    with {:ok, start_date} <- Date.new(year, 1, 1, __MODULE__),
         {:ok, end_date} <- Date.new(year, last_month, days_in_last_month, __MODULE__) do
      Date.range(start_date, end_date)
    end
  end

  @doc """
  Returns a `Date.Range.t` representing
  a given quarter of a year.

  """
  @impl true

  def quarter(year, quarter) do
    months_in_quarter = div(months_in_year(year), @quarters_in_year)
    starting_month = months_in_quarter * (quarter - 1) + 1
    starting_day = 1

    ending_month = starting_month + months_in_quarter - 1
    ending_day = days_in_month(year, ending_month)

    with {:ok, start_date} <- Date.new(year, starting_month, starting_day, __MODULE__),
         {:ok, end_date} <- Date.new(year, ending_month, ending_day, __MODULE__) do
      Date.range(start_date, end_date)
    end
  end

  @doc """
  Returns a `Date.Range.t` representing
  a given month of a year.

  """
  @impl true

  def month(year, month) do
    starting_day = 1
    ending_day = days_in_month(year, month)

    with {:ok, start_date} <- Date.new(year, month, starting_day, __MODULE__),
         {:ok, end_date} <- Date.new(year, month, ending_day, __MODULE__) do
      Date.range(start_date, end_date)
    end
  end

  @doc """
  Returns a `Date.Range.t` representing
  a given week of a year.

  """
  @impl true

  def week(_year, _week) do
    {:error, :not_defined}
  end

  @doc """
  Adds an `increment` number of `date_part`s
  to a `year-month-day`.

  `date_part` can be `:quarters`
   or`:months`.

  """
  @impl true

  def plus(year, month, day, date_part, increment, options \\ [])

  def plus(year, month, day, :quarters, quarters, options) do
    months = quarters * @months_in_quarter
    plus(year, month, day, :months, months, options)
  end

  def plus(year, month, day, :months, months, options) do
    months_in_year = months_in_year(year)
    {year_increment, new_month} = Cldr.Math.div_amod(month + months, months_in_year)
    new_year = year + year_increment

    new_day =
      if Keyword.get(options, :coerce, false) do
        max_new_day = days_in_month(new_year, new_month)
        min(day, max_new_day)
      else
        day
      end

    {new_year, new_month, new_day}
  end

  @doc """
  Returns if the given year is a leap year.

  """
  @spec leap_year?(year) :: boolean()
  @impl true

  def leap_year?(year) do
    Cldr.Math.mod(year, 4) == if year > 0, do: 0, else: 3
  end

  @doc """
  Returns the number of days since the calendar
  epoch for a given `year-month-day`

  """

  def date_to_iso_days(year, month, day) do
    adjustment = adjustment(year, month, day)
    year = if year < 0, do: year + 1, else: year

    epoch() - 1 +
      365 * (year - 1) +
      Integer.floor_div(year - 1, 4) +
      Integer.floor_div(367 * month - 362, @months_in_year) +
      adjustment +
      day
  end

  defp adjustment(year, month, _day) do
    cond do
      month <= 2 -> 0
      leap_year?(year) -> -1
      true -> -2
    end
  end

  @doc """
  Returns a `{year, month, day}` calculated from
  the number of `iso_days`.

  """
  def date_from_iso_days(iso_days) do
    approx = Integer.floor_div(4 * (iso_days - epoch()) + 1464, 1461)
    year = if approx <= 0, do: approx - 1, else: approx
    prior_days = iso_days - date_to_iso_days(year, 1, 1)
    correction = correction(iso_days, year)
    month = Integer.floor_div(@months_in_year * (prior_days + correction) + 373, 367)
    day = 1 + (iso_days - date_to_iso_days(year, month, 1))

    {year, month, day}
  end

  defp correction(iso_days, year) do
    cond do
      iso_days < date_to_iso_days(year, 3, 1) -> 0
      leap_year?(year) -> 1
      true -> 2
    end
  end

  @doc """
  Returns the `t:Calendar.iso_days/0` format of the specified date.

  """
  @impl true
  @spec naive_datetime_to_iso_days(
          Calendar.year(),
          Calendar.month(),
          Calendar.day(),
          Calendar.hour(),
          Calendar.minute(),
          Calendar.second(),
          Calendar.microsecond()
        ) :: Calendar.iso_days()

  def naive_datetime_to_iso_days(year, month, day, hour, minute, second, microsecond) do
    {date_to_iso_days(year, month, day), time_to_day_fraction(hour, minute, second, microsecond)}
  end

  @doc """
  Converts the `t:Calendar.iso_days/0` format to the datetime format specified by this calendar.

  """
  @spec naive_datetime_from_iso_days(Calendar.iso_days()) :: {
          Calendar.year(),
          Calendar.month(),
          Calendar.day(),
          Calendar.hour(),
          Calendar.minute(),
          Calendar.second(),
          Calendar.microsecond()
        }
  @impl true

  def naive_datetime_from_iso_days({days, day_fraction}) do
    {year, month, day} = date_from_iso_days(days)
    {hour, minute, second, microsecond} = time_from_day_fraction(day_fraction)
    {year, month, day, hour, minute, second, microsecond}
  end

  @doc false
  @impl true

  def date_to_string(year, month, day) when year > 0 do
    Calendar.ISO.date_to_string(year, month, day) <> " C.E."
  end

  def date_to_string(year, month, day) when year < 0 do
    Calendar.ISO.date_to_string(abs(year), month, day) <> " B.C.E."
  end

  @doc false
  defdelegate datetime_to_string(
                year,
                month,
                day,
                hour,
                minute,
                second,
                microsecond,
                time_zone,
                zone_abbr,
                utc_offset,
                std_offset
              ),
              to: Calendar.ISO

  @doc false
  defdelegate naive_datetime_to_string(year, month, day, hour, minute, second, microsecond),
    to: Calendar.ISO

  @doc false
  defdelegate day_rollover_relative_to_midnight_utc, to: Calendar.ISO

  @doc false
  defdelegate months_in_year(year), to: Calendar.ISO

  @doc false
  defdelegate time_from_day_fraction(day_fraction), to: Calendar.ISO

  @doc false
  defdelegate time_to_day_fraction(hour, minute, second, microsecond), to: Calendar.ISO

  @doc false
  defdelegate time_to_string(hour, minute, second, microsecond), to: Calendar.ISO

  @doc false
  defdelegate valid_time?(hour, minute, second, microsecond), to: Calendar.ISO
end