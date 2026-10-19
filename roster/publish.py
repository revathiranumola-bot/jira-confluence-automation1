"""Publish workflow: follows instructions/publish-roster.agent.md."""
from __future__ import annotations

from datetime import datetime
from zoneinfo import ZoneInfo

from .core import Roster, validate_roster
from .publisher import PublishError, RosterPublisher


def _to_records(roster: Roster, member_map: dict[str, str]) -> list[dict]:
    return [
        {
            "start": a.start.isoformat(),
            "end": a.end.isoformat(),
            "primary": member_map[a.primary],
            "time_zone": roster.settings.time_zone,
        }
        for a in roster.assignments
    ]


def verify_publish_result(publisher: RosterPublisher, servicenow_id: str, expected: list[dict]) -> list[str]:
    """Follows instructions/verify-publish-result.agent.md; returns mismatch descriptions."""
    actual = publisher.read_back(servicenow_id)
    if len(actual) != len(expected):
        return [f"record count {len(actual)} != expected {len(expected)}"]
    problems = []
    for index, (want, got) in enumerate(zip(expected, actual)):
        for key in ("start", "end", "primary", "time_zone"):
            if want[key] != got.get(key):
                problems.append(f"record {index}: {key} {got.get(key)!r} != {want[key]!r}")
    return problems


def publish_roster(
    roster: Roster,
    user: str,
    publisher: RosterPublisher,
    member_map: dict[str, str],
    audit: list[dict],
    dry_run: bool = False,
) -> dict:
    """With dry_run=True, unconfirmed settings are allowed (defaults assumed) and the result is flagged."""
    now = datetime.now(ZoneInfo(roster.settings.time_zone or "UTC")).isoformat(timespec="seconds")

    def fail(category: str, message: str, details: list) -> dict:
        audit.append({"event": "publish", "roster_id": roster.roster_id, "user": user, "outcome": "failed", "at": now})
        return {
            "status": "failed",
            "roster_state": roster.state,
            "error_category": category,
            "message": message,
            "details": details,
        }

    if roster.state != "draft":
        return fail("validation", f"Roster is '{roster.state}'; only a draft can be published.", [])

    if not roster.settings.confirmed and not dry_run:
        return fail("validation", "Required settings are unconfirmed.", ["time zone, holiday calendar, ServiceNow target"])

    validation = validate_roster(roster)
    if not validation["valid"]:
        return fail("validation", "Validation failed.", validation["hard_failures"])

    unmapped = sorted({a.primary for a in roster.assignments if a.primary not in member_map})
    if unmapped:
        return fail("validation", "Members have no ServiceNow ID.", unmapped)

    if publisher.exists(roster.roster_id):
        return fail("validation", "A roster with this identity already exists; overwrite refused.", [roster.roster_id])

    records = _to_records(roster, member_map)
    try:
        result = publisher.publish(roster.roster_id, records, idempotency_key=f"{roster.roster_id}:{roster.seed}")
    except PublishError as error:
        if error.servicenow_id:
            publisher.rollback(error.servicenow_id)
        return fail(error.category, error.message, ["partial records rolled back"] if error.servicenow_id else [])

    problems = verify_publish_result(publisher, result["servicenow_id"], records)
    if problems:
        publisher.rollback(result["servicenow_id"])
        return fail("unknown", "Read-back verification failed; publish rolled back.", problems)

    roster.state = "published"
    roster.servicenow_id = result["servicenow_id"]
    roster.servicenow_link = result["link"]
    roster.published_by = user
    roster.published_at = now
    audit.append({"event": "publish", "roster_id": roster.roster_id, "user": user, "outcome": "published", "at": now})

    output = {
        "status": "published",
        "roster_id": roster.roster_id,
        "servicenow_id": roster.servicenow_id,
        "servicenow_link": roster.servicenow_link,
        "published_by": user,
        "published_at": now,
        "records": len(records),
    }
    if dry_run:
        output["dry_run"] = True
        output["note"] = "Mock publisher; settings were defaulted, not confirmed. Nothing was sent to ServiceNow."
    return output
