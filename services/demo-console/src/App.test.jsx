import { cleanup, render, screen, waitFor, within } from "@testing-library/react";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { axe, toHaveNoViolations } from "jest-axe";
import App from "./App.jsx";

expect.extend(toHaveNoViolations);

const catalog = {
  services: [
    {
      name: "go-api",
      kind: "service",
      runtime: "go",
      port: 8010,
      required: true,
      check: { type: "http", url: "http://127.0.0.1:8010/health" }
    },
    {
      name: "redis",
      kind: "cache",
      runtime: "compose",
      port: 6379,
      health_url: "http://127.0.0.1:6379/health"
    },
    {
      name: "notes",
      kind: "service",
      runtime: "python",
      check: { type: "file", path: "notes.txt" }
    }
  ]
};

function responseFor(payload, ok = true, status = 200) {
  return Promise.resolve({
    ok,
    status,
    json: () => Promise.resolve(payload)
  });
}

function metric(name) {
  const container = screen.getByText(name).closest(".summary-metric");
  return within(container).getByText(/\d+/, { selector: "strong" });
}

describe("Base Demo Console", () => {
  beforeEach(() => {
    vi.stubGlobal("fetch", vi.fn());
  });

  afterEach(() => {
    cleanup();
    vi.unstubAllGlobals();
    vi.restoreAllMocks();
  });

  it("shows a visible loading state while the catalog request is pending", () => {
    fetch.mockReturnValue(new Promise(() => {}));

    render(<App />);

    expect(screen.getByText("loading")).toBeVisible();
    expect(screen.getByRole("status")).toHaveTextContent("Loading service catalog…");
    expect(screen.getByRole("heading", { name: "Base Demo Console" })).toBeVisible();
  });

  it("renders catalog services, summary counts, and state vocabulary after a successful response", async () => {
    fetch.mockReturnValue(responseFor(catalog));

    render(<App />);

    expect(await screen.findByText("ready")).toBeVisible();
    expect(fetch).toHaveBeenCalledWith("/service-catalog.json");
    expect(screen.getByText("go-api")).toBeVisible();
    expect(screen.getByText("redis")).toBeVisible();
    expect(screen.getByText("notes")).toBeVisible();
    expect(metric("Total")).toHaveTextContent("3");
    expect(metric("Services")).toHaveTextContent("2");
    expect(metric("Infrastructure")).toHaveTextContent("1");
    expect(metric("UI")).toHaveTextContent("0");
    expect(screen.getByText("required")).toHaveClass("state-required");
    expect(screen.getByText("optional")).toHaveClass("state-optional");
    expect(screen.getByText("cataloged")).toHaveClass("state-cataloged");
    expect(screen.getByRole("columnheader", { name: "Name" })).toBeInTheDocument();
    expect(screen.getAllByRole("cell")).toHaveLength(15);
  });

  it("renders an empty catalog as a successful response with zero counts", async () => {
    fetch.mockReturnValue(responseFor({ services: [] }));

    render(<App />);

    expect(await screen.findByText("ready")).toBeVisible();
    expect(metric("Total")).toHaveTextContent("0");
    expect(screen.getByRole("table", { name: "Service catalog" })).toBeInTheDocument();
    expect(screen.getAllByRole("row")).toHaveLength(1);
    expect(screen.getByRole("status")).toHaveTextContent("No services are cataloged yet.");
  });

  it("shows an unavailable state when the catalog request fails", async () => {
    fetch.mockReturnValue(responseFor({}, false, 503));

    render(<App />);

    expect(await screen.findByText("unavailable")).toBeVisible();
    expect(screen.getByRole("alert")).toHaveTextContent("Service catalog unavailable.");
    expect(screen.getByRole("region", { name: "Service summary" })).toBeInTheDocument();
  });

  it("shows an unavailable state when the catalog request is rejected", async () => {
    fetch.mockRejectedValue(new Error("offline"));

    render(<App />);

    expect(await screen.findByText("unavailable")).toBeVisible();
    expect(screen.getByRole("alert")).toHaveTextContent("Service catalog unavailable.");
  });

  it("keeps the rendered catalog discoverable through the current accessibility surface", async () => {
    fetch.mockReturnValue(responseFor(catalog));

    const { container } = render(<App />);

    await waitFor(() => expect(screen.getByText("ready")).toBeInTheDocument());
    expect(screen.getByRole("heading", { name: "Base Demo Console" })).toBeInTheDocument();
    expect(screen.getByRole("region", { name: "Service summary" })).toBeInTheDocument();
    expect(screen.getByRole("region", { name: "Service catalog" })).toBeInTheDocument();
    expect(screen.getByRole("table", { name: "Service catalog" })).toBeInTheDocument();
    expect(screen.getAllByRole("row")).toHaveLength(4);
    expect(screen.getAllByRole("columnheader")).toHaveLength(6);
    expect(screen.getAllByRole("rowheader")).toHaveLength(3);

    const results = await axe(container);
    expect(results).toHaveNoViolations();
  });
});
