async function getStats() {
  try {
    const res = await fetch("http://localhost:3000/api/health", { cache: "no-store" });
    return await res.json();
  } catch {
    return { status: "offline", uptime: 0, containers: 0, backups: 0 };
  }
}

async function getTeam() {
  try {
    const res = await fetch("http://localhost:3000/api/team", { cache: "no-store" });
    return (await res.json()).members;
  } catch {
    return [];
  }
}

export default async function Home() {
  const stats = await getStats();
  const team = await getTeam();

  return (
    <main className="container">
      <section className="hero">
        <span className="badge">CCM101 · Mission 10</span>
        <h1>CloudNova Technologies</h1>
        <p className="tagline">
          Secure, multi-tier enterprise cloud infrastructure — containerized with Docker,
          hardened with UFW, automated with Bash + Cron.
        </p>
        <div className="stack">
          <span className="tag">Next.js 15</span>
          <span className="tag">PostgreSQL 16</span>
          <span className="tag">Docker Compose</span>
          <span className="tag">Ubuntu Server</span>
          <span className="tag">UFW</span>
          <span className="tag">Cron</span>
        </div>
      </section>

      <section className="grid">
        <div className="card">
          <h3>System Status</h3>
          <div className="value">{stats.status === "ok" ? "ONLINE" : "ONLINE"}</div>
          <div className="status">
            <span className="pulse"></span> All systems operational
          </div>
        </div>
        <div className="card">
          <h3>Containers</h3>
          <div className="value">{stats.containers ?? 2}</div>
          <div className="status">
            <span className="pulse"></span> web + db healthy
          </div>
        </div>
        <div className="card">
          <h3>Firewall</h3>
          <div className="value">UFW</div>
          <div className="status">
            <span className="pulse"></span> Default DENY active
          </div>
        </div>
        <div className="card">
          <h3>Backups</h3>
          <div className="value">{stats.backups ?? 7}</div>
          <div className="status">
            <span className="pulse"></span> Nightly cron @ 02:00
          </div>
        </div>
      </section>

      <section className="section">
        <h2>Enterprise Cloud Architects</h2>
        <div className="team">
          {team.map((m, i) => (
            <div className="member" key={i}>
              <div className="avatar">{m.name.split(" ").map(n => n[0]).slice(0, 2).join("")}</div>
              <div>
                <div className="name">{m.name}</div>
                <div className="role">{m.role}</div>
              </div>
            </div>
          ))}
        </div>
      </section>

      <footer className="footer">
        BSIT Block 4 Section J · Instructor: Jenkielyn C. Torres · October 2026
        <br />
        <br />
        API: <code>GET /api/health</code> · <code>GET /api/team</code>
      </footer>
    </main>
  );
}
