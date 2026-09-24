extends RefCounted
## LocalCalendar — preload (res://scripts/economy/local_calendar.gd).
##
## Local calendar-day ordinal for Daily (M39 V04, F-M39-V03-002). The ordinal is
## the proleptic-Gregorian day number of a (year, month, day) civil date, so the
## next LOCAL calendar day is always ordinal+1 — across month, year and leap-day
## boundaries. Ordinal 0 == 1970-01-01, so persisted day keys stay compatible.
##
## Production: system_provider() reads the OS LOCAL date (timezone + DST applied
## by the OS), never unix_seconds/86400. Tests: offset_provider(clock, offset)
## derives the local date of an injected clock at a fixed UTC offset.

## Days from 1970-01-01 to y-m-d (Hinnant days_from_civil).
static func ordinal(y: int, m: int, d: int) -> int:
	var yy := y - (1 if m <= 2 else 0)
	var era := (yy if yy >= 0 else yy - 399) / 400
	var yoe := yy - era * 400
	var mp := (m + 9) % 12
	var doy := (153 * mp + 2) / 5 + d - 1
	var doe := yoe * 365 + yoe / 4 - yoe / 100 + doy
	return era * 146097 + doe - 719468

static func ordinal_of_dict(dd: Dictionary) -> int:
	return ordinal(int(dd["year"]), int(dd["month"]), int(dd["day"]))

## Production local-day provider: OS local date right now.
static func system_provider() -> Callable:
	return func() -> int:
		return ordinal_of_dict(Time.get_date_dict_from_system(false))

## Deterministic test provider: local date of clock() at offset_seconds from UTC.
static func offset_provider(clock: Callable, offset_seconds: int) -> Callable:
	return func() -> int:
		return ordinal_of_dict(Time.get_date_dict_from_unix_time(int(clock.call()) + offset_seconds))
