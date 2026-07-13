/// Pure local-time date-window math for the dashboard aggregates, kept out of
/// the Firestore datasource so it is unit-testable without a fake client.
///
/// A Firestore `createdAt` is an absolute `Timestamp`; the console founder
/// thinks in *their* day, so the window boundaries are local midnights, which
/// `Timestamp.fromDate` then converts to the correct absolute instants.
library;

/// Local midnight that starts [now]'s day.
DateTime startOfDay(DateTime now) => DateTime(now.year, now.month, now.day);

/// The seven local-midnight day-starts ending with today, oldest-first — the
/// bucket starts for the 7-day order bar chart. Each day's bucket runs from its
/// start (inclusive) to the next day's start (exclusive). Built via the
/// `DateTime` constructor (which normalises the day rollover) so every entry is
/// a true local midnight even across a daylight-saving boundary, where
/// subtracting a `Duration` of whole days would land an hour off.
List<DateTime> last7DayStarts(DateTime now) =>
    [for (var k = 6; k >= 0; k--) DateTime(now.year, now.month, now.day - k)];

/// The local midnight that starts the day after [day] — the exclusive upper
/// bound of [day]'s bucket. Constructor-based for the same DST-safety reason.
DateTime nextDay(DateTime day) => DateTime(day.year, day.month, day.day + 1);
