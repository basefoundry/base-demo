import { useEffect, useMemo, useState } from "react";

const CATALOG_URL = "/service-catalog.json";

function stateFor(service) {
  if (service.required) {
    return "required";
  }
  if (service.health_url) {
    return "optional";
  }
  return "cataloged";
}

function healthLabel(service) {
  if (service.health_url) {
    return service.health_url;
  }
  if (service.check?.type === "command") {
    return service.check.command.join(" ");
  }
  if (service.check?.type === "file") {
    return `file:${service.check.path}`;
  }
  if (service.check?.type === "compose") {
    return `compose:${service.check.service}`;
  }
  return service.check?.type || "-";
}

function groupCounts(services) {
  return services.reduce(
    (counts, service) => {
      counts.total += 1;
      counts[service.kind] = (counts[service.kind] || 0) + 1;
      return counts;
    },
    { total: 0 }
  );
}

export default function App() {
  const [catalog, setCatalog] = useState({ services: [] });
  const [loadState, setLoadState] = useState("loading");

  useEffect(() => {
    fetch(CATALOG_URL)
      .then((response) => {
        if (!response.ok) {
          throw new Error(`catalog ${response.status}`);
        }
        return response.json();
      })
      .then((payload) => {
        setCatalog(payload);
        setLoadState("ready");
      })
      .catch(() => {
        setLoadState("unavailable");
      });
  }, []);

  const services = catalog.services || [];
  const counts = useMemo(() => groupCounts(services), [services]);

  return (
    <main className="console-shell">
      <header className="console-header">
        <div>
          <p className="eyebrow">Representative Environment</p>
          <h1>Base Demo Console</h1>
        </div>
        <div className={`catalog-state catalog-state-${loadState}`}>{loadState}</div>
      </header>

      <section className="summary-grid" aria-label="Service summary">
        <div className="summary-metric">
          <span>Total</span>
          <strong>{counts.total}</strong>
        </div>
        <div className="summary-metric">
          <span>Services</span>
          <strong>{counts.service || 0}</strong>
        </div>
        <div className="summary-metric">
          <span>Infrastructure</span>
          <strong>{(counts.database || 0) + (counts.cache || 0)}</strong>
        </div>
        <div className="summary-metric">
          <span>UI</span>
          <strong>{counts.ui || 0}</strong>
        </div>
      </section>

      <section className="service-panel" aria-label="Service catalog">
        <div className="service-table" role="table">
          <div className="service-row service-row-head" role="row">
            <span>Name</span>
            <span>Kind</span>
            <span>Runtime</span>
            <span>Port</span>
            <span>Health</span>
            <span>State</span>
          </div>
          {services.map((service) => (
            <div className="service-row" role="row" key={service.name}>
              <span className="service-name">{service.name}</span>
              <span>{service.kind}</span>
              <span>{service.runtime}</span>
              <span>{service.port || "-"}</span>
              <span className="health-cell">{healthLabel(service)}</span>
              <span className={`state-pill state-${stateFor(service)}`}>{stateFor(service)}</span>
            </div>
          ))}
        </div>
      </section>
    </main>
  );
}
