import { fireEvent, render, screen } from "@testing-library/react";
import { MemoryRouter } from "react-router-dom";
import { describe, expect, it } from "vitest";
import App from "./App.jsx";

function renderAt(path) {
  window.history.replaceState({}, "", path);
  return render(
    <MemoryRouter initialEntries={[path]}>
      <App />
    </MemoryRouter>
  );
}

describe("roster application shell", () => {
  it("shows a clearly labelled local prototype and empty roster state", () => {
    renderAt("/");

    expect(screen.getByText("LOCAL PROTOTYPE")).toBeInTheDocument();
    expect(screen.getByText("No roster drafts yet")).toBeInTheDocument();
    expect(screen.getByText(/no ServiceNow changes are made/i)).toBeInTheDocument();
  });

  function fillSetup(overrides = {}) {
    const values = {
      "Start date": "2026-10-20",
      "End date": "2026-10-31",
      "Time zone": "Asia/Kolkata",
      "Local demo member IDs": " demo-alice \n demo-bob \n",
      ...overrides
    };
    for (const [label, value] of Object.entries(values)) {
      fireEvent.change(screen.getByLabelText(new RegExp(label)), { target: { value } });
    }
  }

  describe("local setup preview flow", () => {
    it.each(["Configure roster", "Set up a roster"])("opens setup using %s", (name) => {
      renderAt("/");
      fireEvent.click(screen.getByRole("link", { name }));
      expect(screen.getByRole("heading", { name: "Roster setup" })).toBeInTheDocument();
      expect(screen.getByRole("button", { name: "Preview setup" })).toBeInTheDocument();
    });

    it("reports all missing fields without submitting", () => {
      renderAt("/setup");
      fireEvent.click(screen.getByRole("button", { name: "Preview setup" }));
      expect(screen.getByRole("alert")).toHaveTextContent("Setup was not submitted");
      for (const label of ["Start date", "End date", "Time zone", "Local demo member IDs"]) {
        expect(screen.getByLabelText(new RegExp(label))).toHaveAttribute("aria-invalid", "true");
      }
      expect(screen.queryByRole("heading", { name: "Setup summary" })).not.toBeInTheDocument();
    });

    it.each([
      [{ "End date": "2026-10-19" }, /End date must be on or after/],
      [{ "Time zone": "Not/AZone" }, /Enter a recognized named time zone/],
      [{ "Time zone": "+05:30" }, /Enter a named time zone/],
      [{ "Local demo member IDs": "demo-alice\n demo-alice " }, /Member IDs must be unique/],
      [{ "Local demo member IDs": " \n " }, /Enter at least one approved local demo member ID/]
    ])("rejects invalid setup inputs: %j", (overrides, error) => {
      renderAt("/setup");
      fillSetup(overrides);
      fireEvent.click(screen.getByRole("button", { name: "Preview setup" }));
      expect(screen.getByRole("alert")).toBeInTheDocument();
      expect(screen.getByText(error)).toBeInTheDocument();
      expect(screen.queryByRole("heading", { name: "Setup summary" })).not.toBeInTheDocument();
    });

    it("shows the submitted inputs, supports editing, and clears previous errors", () => {
      renderAt("/setup");
      fireEvent.click(screen.getByRole("button", { name: "Preview setup" }));
      fillSetup();
      fireEvent.click(screen.getByRole("button", { name: "Preview setup" }));
      expect(screen.getByRole("heading", { name: "Setup summary" })).toBeInTheDocument();
      expect(screen.getByRole("status")).toHaveTextContent("No roster has been generated or saved");
      for (const text of ["2026-10-20", "2026-10-31", "Asia/Kolkata", "demo-alice", "demo-bob"]) {
        expect(screen.getByText(text)).toBeInTheDocument();
      }
      expect(screen.queryByRole("alert")).not.toBeInTheDocument();
      fireEvent.click(screen.getByRole("link", { name: "Edit setup" }));
      expect(screen.getByLabelText(/Start date/)).toHaveValue("2026-10-20");
      expect(screen.getByLabelText(/Local demo member IDs/)).toHaveValue("demo-alice\ndemo-bob");
      fillSetup({ "End date": "2026-11-01" });
      fireEvent.click(screen.getByRole("button", { name: "Preview setup" }));
      expect(screen.getByText("2026-11-01")).toBeInTheDocument();
      fireEvent.click(screen.getByRole("link", { name: "Roster overview" }));
      expect(screen.getByText("No roster drafts yet")).toBeInTheDocument();
    });

    it("accepts a single-day period and UTC without inventing defaults", () => {
      renderAt("/setup");
      fillSetup({ "End date": "2026-10-20", "Time zone": " UTC " });
      fireEvent.click(screen.getByRole("button", { name: "Preview setup" }));
      expect(screen.getByText("UTC")).toBeInTheDocument();
      expect(screen.getByRole("heading", { name: "Setup summary" })).toBeInTheDocument();
    });

    it("does not claim a result exists after remounting the application", () => {
      const { unmount } = renderAt("/setup");
      fillSetup();
      fireEvent.click(screen.getByRole("button", { name: "Preview setup" }));
      unmount();
      renderAt("/generation");
      expect(screen.getByText(/No setup preview is available/)).toBeInTheDocument();
      expect(screen.queryByRole("heading", { name: "Setup summary" })).not.toBeInTheDocument();
      fireEvent.click(screen.getByRole("link", { name: "Start roster setup" }));
      expect(screen.getByLabelText(/Start date/)).toHaveValue("");
    });
  });

  it("provides the required roster workflow routes", () => {
    renderAt("/setup");

    expect(screen.getByRole("heading", { name: "Roster setup" })).toBeInTheDocument();
    expect(screen.getByRole("navigation", { name: "Roster workflow" })).toBeInTheDocument();
  });

  it("renders an understandable not-found route", () => {
    renderAt("/not-a-route");

    expect(screen.getByRole("heading", { name: "Page not found" })).toBeInTheDocument();
  });
});
