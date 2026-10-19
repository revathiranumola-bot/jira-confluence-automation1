import { render, screen } from "@testing-library/react";
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
