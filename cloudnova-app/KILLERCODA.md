# CloudNova — KillerCoda Deployment Guide

Deploy the full stack on a fresh browser-based Ubuntu sandbox in under 5 minutes.
Perfect for the **live defense / video demo** — no local VM, no storage needed.

---

## Prerequisites

- A **GitHub account** with this project pushed to a public repo
  (e.g. `https://github.com/<your-user>/CCM101-jentorres`)
- A **web browser** (Chrome / Edge / Firefox)
- A **screen recorder** (OBS, Loom, built-in Xbox Game Bar on Windows: `Win + G`)

---

## Step 1 — Open a KillerCoda Ubuntu playground

1. Go to **https://killercoda.com/playgrounds/scenario/ubuntu**
2. Click **"Start Scenario"** — a terminal opens inside your browser.
3. Wait until you see a `$` prompt. (About 10 seconds.)

> KillerCoda already comes with Docker preinstalled.

---

## Step 2 — Clone the repo

Paste into the terminal:

```bash
git clone https://github.com/<your-github-user>/CCM101-jentorres.git
cd CCM101-jentorres/cloudnova-app
```

> Replace `<your-github-user>` with the actual GitHub username.

---

## Step 3 — Run the one-command deployer

```bash
chmod +x deploy.sh backup.sh
./deploy.sh
```

That single script:
- ✅ Installs Docker if missing
- ✅ Builds the Next.js image
- ✅ Starts both containers (web + db)
- ✅ Configures UFW with default-deny
- ✅ Installs the backup script + cron entry

Expected final output:
```
Deployment complete
Web UI: http://172.17.0.1:3000
Logs:   sudo docker compose logs -f
Backup: sudo /usr/local/bin/cloudnova-backup.sh
```

---

## Step 4 — Open the app in the browser

In KillerCoda, click the **"+"** tab bar → **"Select port to view on Host 1"** → type `3000`.
The CloudNova landing page should load with the team members and live status cards.

---

## Step 5 — Prove each requirement for the demo

Run these in order and screen-record each command's output:

### 5.1 Multi-tier + persistent volumes
```bash
sudo docker compose ps
sudo docker volume ls | grep cloudnova
```

### 5.2 Firewall (default deny)
```bash
sudo ufw status verbose
```

### 5.3 Automation (bash + cron)
```bash
sudo crontab -l
sudo /usr/local/bin/cloudnova-backup.sh
ls -lh /var/backups/cloudnova/
```

### 5.4 Persistence proof
```bash
sudo docker compose down
sudo docker compose up -d
# refresh browser — data still there
```

---

## Troubleshooting

| Issue | Fix |
|---|---|
| `permission denied` on docker | prepend `sudo` |
| Port 3000 shows blank page | wait 10s for Next.js to compile, then refresh |
| `ufw: command not found` | `sudo apt install -y ufw` |
| KillerCoda session expired | sessions last ~1 hour — restart |

---

## Checklist for the Video

- [ ] Scene 1 — architecture diagram
- [ ] Scene 2 — `docker compose ps` + `docker volume ls`
- [ ] Scene 3 — browser showing the Next.js portal
- [ ] Scene 4 — `sudo ufw status verbose`
- [ ] Scene 5 — `sudo crontab -l` + manual backup run + `ls /var/backups`
- [ ] Scene 6 — pan over GitHub repo
