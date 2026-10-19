"""ServiceNow publisher interface and an in-memory mock for dev and tests."""
from __future__ import annotations

from typing import Protocol


class PublishError(Exception):
    def __init__(self, category: str, message: str, servicenow_id: str | None = None):
        super().__init__(message)
        self.category = category
        self.message = message
        self.servicenow_id = servicenow_id


class RosterPublisher(Protocol):
    def exists(self, identity: str) -> bool: ...

    def publish(self, identity: str, records: list[dict], idempotency_key: str) -> dict: ...

    def read_back(self, servicenow_id: str) -> list[dict]: ...

    def rollback(self, servicenow_id: str) -> None: ...


class MockPublisher:
    """In-memory publisher. `fail_after` simulates a failure mid-publish."""

    def __init__(self, fail_after: int | None = None, existing: set[str] | None = None):
        self.fail_after = fail_after
        self.identities: set[str] = set(existing or ())
        self.records: dict[str, list[dict]] = {}
        self.by_key: dict[str, dict] = {}
        self.identity_of: dict[str, str] = {}

    def exists(self, identity: str) -> bool:
        return identity in self.identities

    def publish(self, identity: str, records: list[dict], idempotency_key: str) -> dict:
        if idempotency_key in self.by_key:
            return self.by_key[idempotency_key]
        if identity in self.identities:
            raise PublishError("validation", f"Roster '{identity}' already exists; overwrite refused.")
        servicenow_id = f"mock-roster-{len(self.records) + 1:04d}"
        self.identities.add(identity)
        self.identity_of[servicenow_id] = identity
        self.records[servicenow_id] = []
        for index, record in enumerate(records):
            if self.fail_after is not None and index >= self.fail_after:
                raise PublishError("network", "Simulated connection failure.", servicenow_id)
            self.records[servicenow_id].append(dict(record))
        result = {"servicenow_id": servicenow_id, "link": f"https://mock.service-now.invalid/roster/{servicenow_id}"}
        self.by_key[idempotency_key] = result
        return result

    def read_back(self, servicenow_id: str) -> list[dict]:
        return [dict(r) for r in self.records.get(servicenow_id, [])]

    def rollback(self, servicenow_id: str) -> None:
        self.records.pop(servicenow_id, None)
        self.identities.discard(self.identity_of.pop(servicenow_id, ""))
        self.by_key = {k: v for k, v in self.by_key.items() if v["servicenow_id"] != servicenow_id}
