defmodule Cldr.Calendar.Gregorian do
  @moduledoc """
  Implements the `Calendar` behaviour for the
  Gregorian proleptic calendar.

  In this regard it implements the same
  calendar as the Elixir `Calendar.ISO`
  calendar but adds the `Cldr.Calendar`
  behaviour.

  This behaviour adds the following
  functions:

  * `week_of_year/4` and `iso_week_of_year/3`
    functions.

  """

  @behaviour Calendar
  @behaviour Cldr.Calendar

  alias Calendar.ISO
  alias Cldr.Calendar.Config

  @days_in_week 7
  @iso_week_first_day 1
  @iso_week_min_days 4

  def iso_week_of_year(year, month, day) do
    week_of_year(year, month, day, @iso_week_first_day, @iso_week_min_days)
  end

  def week_of_year(year, month, day, options \\ [])

  def week_of_year(year, month, day, options) when is_list(options) do
    with options <- extract_options(options) do
      week_of_year(year, month, day, options)
    end
  end

  def week_of_year(year, month, day, %Config{} = config) do
    week_of_year(year, month, day, config.first_day, config.min_days)
  end

  def week_of_year(year, month, day, first_day, min_days) do
    iso_days = ISO.date_to_iso_days(year, month, day)
    first_week_starts = first_week_starts(year, first_day, min_days)
    last_week_ends = last_week_ends(year, first_day, min_days)

    cond do
      iso_days < first_week_starts ->
        if long_year?(year - 1, first_day, min_days), do: {year - 1, 53}, else: {year - 1, 52}

      iso_days > last_week_ends ->
        {year + 1, 1}

      true ->
        week = div(iso_days - first_week_starts, @days_in_week) + 1
        {year, week}
    end
  end

  def long_year?(year, %Config{} = config) do
    long_year?(year, config.first_day, config.min_days)
  end

  def long_year?(year, first_day, min_days) do
    div(
      last_week_ends(year, first_day, min_days) - first_week_starts(year, first_day, min_days) +
        1,
      @days_in_week
    ) == 53
  end

  def days_in_year(year) do
    if leap_year?(year), do: 365, else: 366
  end

  defdelegate date_to_string(year, month, day), to: Calendar.ISO

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

  defdelegate day_of_era(year, month, day), to: Calendar.ISO
  defdelegate day_of_week(year, month, day), to: Calendar.ISO
  defdelegate day_of_year(year, month, day), to: Calendar.ISO
  defdelegate day_rollover_relative_to_midnight_utc, to: Calendar.ISO
  defdelegate days_in_month(year, month), to: Calendar.ISO
  defdelegate leap_year?(year), to: Calendar.ISO
  defdelegate months_in_year(year), to: Calendar.ISO
  defdelegate naive_datetime_from_iso_days(iso_days), to: Calendar.ISO

  defdelegate naive_datetime_to_iso_days(year, month, day, hour, minute, second, microsecond),
    to: Calendar.ISO

  defdelegate naive_datetime_to_string(year, month, day, hour, minute, second, microsecond),
    to: Calendar.ISO

  defdelegate quarter_of_year(year, month, day), to: Calendar.ISO
  defdelegate time_from_day_fraction(day_fraction), to: Calendar.ISO
  defdelegate time_to_day_fraction(hour, minute, second, microsecond), to: Calendar.ISO
  defdelegate time_to_string(hour, minute, second, microsecond), to: Calendar.ISO
  defdelegate valid_date?(year, month, day), to: Calendar.ISO
  defdelegate valid_time?(hour, minute, second, microsecond), to: Calendar.ISO
  defdelegate year_of_era(year), to: Calendar.ISO

  def first_week_starts(year, %Config{} = config) do
    first_week_starts(year, config.first_day, config.min_days)
  end

  def first_week_starts(year, first_day, min_days) do
    iso_days = ISO.date_to_iso_days(year, 1, min_days)
    day_of_week = Cldr.Calendar.iso_days_to_day_of_week(iso_days)

    if first_day < day_of_week do
      iso_days - (day_of_week - first_day)
    else
      iso_days + (day_of_week - first_day)
    end
  end

  def last_week_ends(year, %Config{} = config) do
    last_week_ends(year, config.first_day, config.min_days)
  end

  def last_week_ends(year, first_day, min_days) do
    iso_days = ISO.date_to_iso_days(year, 12, 31 - min_days + 1)
    day_of_week = Cldr.Calendar.iso_days_to_day_of_week(iso_days)

    last_week_starts =
      if first_day < day_of_week do
        iso_days - (day_of_week - first_day + 1)
      else
        iso_days + (day_of_week - first_day + 1)
      end

    last_week_starts + @days_in_week
  end

  @doc false
  def extract_options(options) do
    backend = Keyword.get(options, :backend)
    locale = Keyword.get(options, :locale, Cldr.get_locale())
    format = Keyword.get(options, :format, :wide)
    {min_days, first_day} = get_min_and_first_days(locale, options)

    %Config{
      format: format,
      locale: locale,
      min_days: min_days,
      first_day: first_day,
      backend: backend
    }
  end

  defp get_min_and_first_days(locale, options) do
    min_days = Keyword.get(options, :min_days, Cldr.Calendar.min_days(locale))
    first_day = Keyword.get(options, :first_day, Cldr.Calendar.first_day(locale))
    {min_days, first_day}
  end

  def offset_to_string(utc, std, zone, format \\ :extended)
  def offset_to_string(0, 0, "Etc/UTC", _format), do: "Z"

  def offset_to_string(utc, std, _zone, format) do
    total = utc + std
    second = abs(total)
    minute = second |> rem(3600) |> div(60)
    hour = div(second, 3600)
    format_offset(total, hour, minute, format)
  end

  def format_offset(total, hour, minute, :extended) do
    sign(total) <> zero_pad(hour, 2) <> ":" <> zero_pad(minute, 2)
  end

  def format_offset(total, hour, minute, :basic) do
    sign(total) <> zero_pad(hour, 2) <> zero_pad(minute, 2)
  end

  def zone_to_string(0, 0, _abbr, "Etc/UTC"), do: ""
  def zone_to_string(_, _, abbr, zone), do: " " <> abbr <> " " <> zone

  def sign(total) when total < 0, do: "-"
  def sign(_), do: "+"

  def zero_pad(val, count) when val >= 0 do
    num = Integer.to_string(val)
    :binary.copy("0", max(count - byte_size(num), 0)) <> num
  end

  def zero_pad(val, count) do
    "-" <> zero_pad(-val, count)
  end

  defimpl String.Chars do
    def to_string(%{calendar: calendar, year: year, month: month, day: day}) do
      calendar.date_to_string(year, month, day)
    end
  end
end
