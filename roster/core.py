"""CPS on-call roster: domain model, draft generation, and validation."""
from __future__ import annotations

from collections import Counter, defaultdict
from dataclasses import dataclass, field
from datetime import date, datetime, time, timedelta, timezone
from zoneinfo import ZoneInfo

SHIFT_TIMES = {"day": (time(9), time(21)), "night": (time(21), time(9))}
MIN_REST = timedelta(hours=12)
WEEKEND_DAYS = {5, 6}
US_FEDERAL_HOLIDAYS = {date(2026, 11, 11), date(2026, 11, 26), date(2026, 12, 25)}


@dataclass(frozen=True)
class Assignment:
    date: date
    shift: str
    start: datetime
    end: datetime
    primary: str


@dataclass
class Settings:
    time_zone: str | None = "America/Chicago"
    holiday_region: str | None = "US"
    servicenow_target: str | None = None
    confirmed: bool = False


@dataclass
class Roster:
    roster_id: str
    start_date: date
    weeks: int
    settings: Settings
    members: list[str]
    assignments: list[Assignment] = field(default_factory=list)
    state: str = "draft"
    seed: int = 0
    servicenow_id: str | None = None
    servicenow_link: str | None = None
    published_by: str | None = None
    published_at: str | None = None


def utc(value: datetime) -> datetime:
    # Same-tzinfo datetimes compare on wall time, so always compare in UTC.
    return value.astimezone(timezone.utc)


def generate_draft(
    roster_id: str, start_date: date, weeks: int, members: list[str], settings: Settings
) -> Roster:
    tz = ZoneInfo(settings.time_zone)
    assignments: list[Assignment] = []
    slot = 0
    for offset in range(weeks * 7):
        day = start_date + timedelta(days=offset)
        for shift, (start_time, end_time) in SHIFT_TIMES.items():
            end_day = day if shift == "day" else day + timedelta(days=1)
            assignments.append(
                Assignment(
                    date=day,
                    shift=shift,
                    start=datetime.combine(day, start_time, tzinfo=tz),
                    end=datetime.combine(end_day, end_time, tzinfo=tz),
                    primary=members[slot % len(members)],
                )
            )
            slot += 1
    return Roster(roster_id, start_date, weeks, settings, list(members), assignments)


def _failure(rule: str, assignments: list[Assignment], members: list[str] | None = None) -> dict:
    return {
        "rule": rule,
        "shifts": [f"{a.date.isoformat()} {a.shift}" for a in assignments],
        "members": sorted(set(members if members is not None else (a.primary for a in assignments))),
    }


def validate_roster(roster: Roster) -> dict:
    failures: list[dict] = []
    settings = roster.settings

    for name in ("time_zone", "holiday_region"):
        if not getattr(settings, name):
            failures.append({"rule": f"missing_setting:{name}", "shifts": [], "members": []})
    if failures:
        return {"valid": False, "hard_failures": failures, "info": []}

    by_key: dict[tuple[date, str], list[Assignment]] = defaultdict(list)
    for a in roster.assignments:
        by_key[(a.date, a.shift)].append(a)
    for offset in range(roster.weeks * 7):
        day = roster.start_date + timedelta(days=offset)
        for shift in SHIFT_TIMES:
            found = by_key.get((day, shift), [])
            if not found:
                failures.append({"rule": "missing_primary", "shifts": [f"{day.isoformat()} {shift}"], "members": []})
            elif len(found) > 1:
                failures.append(_failure("multiple_primaries", found))

    ordered = sorted(roster.assignments, key=lambda a: utc(a.start))
    for prev, nxt in zip(ordered, ordered[1:]):
        if utc(nxt.start) < utc(prev.end):
            failures.append(_failure("coverage_overlap", [prev, nxt]))
        elif utc(nxt.start) > utc(prev.end):
            failures.append(_failure("coverage_gap", [prev, nxt], []))

    per_member: dict[str, list[Assignment]] = defaultdict(list)
    for a in ordered:
        per_member[a.primary].append(a)
        if a.primary not in roster.members:
            failures.append(_failure("ineligible_member", [a]))
    for member, items in per_member.items():
        for prev, nxt in zip(items, items[1:]):
            if utc(nxt.start) < utc(prev.end):
                failures.append(_failure("member_overlap", [prev, nxt], [member]))
            elif utc(nxt.start) - utc(prev.end) < MIN_REST:
                failures.append(_failure("rest_under_12h", [prev, nxt], [member]))

    totals: dict[str, Counter] = {m: Counter() for m in roster.members}
    for a in roster.assignments:
        if a.primary not in totals:
            continue
        counter = totals[a.primary]
        counter["total"] += 1
        counter[a.shift] += 1
        counter["weekend"] += a.date.weekday() in WEEKEND_DAYS
        counter["holiday"] += a.date in US_FEDERAL_HOLIDAYS
    info = [{"rule": "fairness", "totals": {m: dict(c) for m, c in totals.items()}}]

    return {"valid": not failures, "hard_failures": failures, "info": info}
