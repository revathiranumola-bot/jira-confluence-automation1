from dataclasses import replace
from datetime import date

from roster.core import Settings, generate_draft, validate_roster
from roster.publish import publish_roster
from roster.publisher import MockPublisher

MEMBERS = [f"member-{n}" for n in range(1, 6)]
MEMBER_MAP = {m: f"sn-user-{n:03d}" for n, m in enumerate(MEMBERS, start=1)}


def draft(roster_id="r-test", confirmed=True):
    return generate_draft(roster_id, date(2026, 11, 1), 6, MEMBERS, Settings(confirmed=confirmed))


def test_draft_has_84_shifts_and_is_valid():
    roster = draft()
    assert len(roster.assignments) == 84
    assert validate_roster(roster)["valid"]


def test_rest_violation_is_a_hard_failure():
    roster = draft()
    first, second = roster.assignments[0], roster.assignments[1]
    roster.assignments[1] = replace(second, primary=first.primary)
    result = validate_roster(roster)
    assert not result["valid"]
    assert any(f["rule"] == "rest_under_12h" for f in result["hard_failures"])


def test_missing_shift_is_a_hard_failure():
    roster = draft()
    roster.assignments.pop(5)
    result = validate_roster(roster)
    assert any(f["rule"] == "missing_primary" for f in result["hard_failures"])


def test_publish_success():
    roster, audit = draft(), []
    result = publish_roster(roster, "sm", MockPublisher(), MEMBER_MAP, audit)
    assert result["status"] == "published"
    assert result["records"] == 84
    assert roster.state == "published"
    assert audit[-1]["outcome"] == "published"


def test_unconfirmed_settings_block_real_publish_but_not_dry_run():
    blocked = publish_roster(draft(confirmed=False), "sm", MockPublisher(), MEMBER_MAP, [])
    assert blocked["status"] == "failed"
    dry = publish_roster(draft(confirmed=False), "sm", MockPublisher(), MEMBER_MAP, [], dry_run=True)
    assert dry["status"] == "published" and dry["dry_run"]


def test_published_roster_cannot_be_republished():
    roster, publisher = draft(), MockPublisher()
    publish_roster(roster, "sm", publisher, MEMBER_MAP, [])
    again = publish_roster(roster, "sm", publisher, MEMBER_MAP, [])
    assert again["status"] == "failed" and again["roster_state"] == "published"


def test_existing_identity_is_not_overwritten():
    publisher = MockPublisher(existing={"r-test"})
    result = publish_roster(draft(), "sm", publisher, MEMBER_MAP, [])
    assert result["status"] == "failed" and result["roster_state"] == "draft"


def test_unmapped_member_fails():
    partial_map = {k: v for k, v in MEMBER_MAP.items() if k != "member-3"}
    result = publish_roster(draft(), "sm", MockPublisher(), partial_map, [])
    assert result["status"] == "failed" and result["details"] == ["member-3"]


def test_partial_failure_rolls_back_and_stays_draft():
    roster, publisher = draft(), MockPublisher(fail_after=10)
    result = publish_roster(roster, "sm", publisher, MEMBER_MAP, [])
    assert result["status"] == "failed" and result["error_category"] == "network"
    assert roster.state == "draft"
    assert publisher.records == {}
    assert not publisher.exists("r-test")
