"""Dry run of the publish workflow with a mock publisher. Run: python -m roster.dry_run"""
from __future__ import annotations

import json
from datetime import date

from .core import Settings, generate_draft, validate_roster
from .publish import publish_roster
from .publisher import MockPublisher

MEMBERS = [f"member-{n}" for n in range(1, 6)]
MEMBER_MAP = {m: f"sn-user-{n:03d}" for n, m in enumerate(MEMBERS, start=1)}
USER = "scrum.master"


def new_roster(roster_id: str):
    return generate_draft(roster_id, date(2026, 11, 1), 6, MEMBERS, Settings())


def show(title: str, payload: dict) -> None:
    print(f"\n=== {title} ===")
    print(json.dumps(payload, indent=2))


def main() -> None:
    audit: list[dict] = []
    roster = new_roster("r-2026-11")
    show("Validation (info = fairness totals)", validate_roster(roster))

    show(
        "1. Real publish with unconfirmed settings (must be blocked)",
        publish_roster(new_roster("r-blocked"), USER, MockPublisher(), MEMBER_MAP, audit),
    )

    publisher = MockPublisher()
    show("2. Dry-run publish (success)", publish_roster(roster, USER, publisher, MEMBER_MAP, audit, dry_run=True))
    show("3. Publish the same roster again (must be rejected)", publish_roster(roster, USER, publisher, MEMBER_MAP, audit, dry_run=True))
    show(
        "4. Duplicate roster identity (overwrite must be refused)",
        publish_roster(new_roster("r-2026-11"), USER, publisher, MEMBER_MAP, audit, dry_run=True),
    )

    flaky = MockPublisher(fail_after=10)
    failed_roster = new_roster("r-flaky")
    show("5. Failure mid-publish (rolled back, stays draft)", publish_roster(failed_roster, USER, flaky, MEMBER_MAP, audit, dry_run=True))
    print(f"\nRoster state after failure: {failed_roster.state}; records left in mock: {len(flaky.records)}")

    show("Audit events", {"events": audit})


if __name__ == "__main__":
    main()
