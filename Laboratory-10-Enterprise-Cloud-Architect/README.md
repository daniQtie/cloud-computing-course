# Laboratory 10 — Enterprise Cloud Architect

**Course:** CCM101 — Cloud Computing
**Mission:** Mission 10 — The Enterprise Cloud Architect
**Stack:** WordPress 6.5 + MySQL 8.0 on Ubuntu Server, hardened with UFW, automated via Bash + Cron.

## Folder Contents

| File | Purpose |
|---|---|
| `README.md` | This file — index + quick start |
| `architecture-diagram.svg` | Network + container topology diagram |
| `docker-compose.yml` | Infrastructure-as-Code definition of the multi-tier stack |
| `.env.example` | Template for secrets (copy to `.env` on the VM) |
| `automation-script.sh` | Disaster-recovery / backup script (runs via cron) |
| `operational-manual.md` | Full handover manual for the client's IT team |
| `final-reflection.md` | Reflection synthesizing Missions 1 → 10 |

## Quick Deployment (on the VM)

```bash
git clone https://github.com/<your-user>/CCM101-jentorres.git
cd CCM101-jentorres/Laboratory-10-Enterprise-Cloud-Architect
cp .env.example .env            # edit passwords
docker compose up -d
```

Then open `http://<vm-ip>:8080` from the host browser.

## Requirement Coverage

| Mission 10 Requirement | Satisfied By |
|---|---|
| 1 — Base Infrastructure & Architecture Design | `architecture-diagram.svg` + Section 2 of manual |
| 2 — Deployment (Compose + persistent volumes) | `docker-compose.yml` (volumes `db_data`, `wp_data`) |
| 3 — Security (UFW, default deny) | Section 5 of manual |
| 4 — Automation (Bash + Cron) | `automation-script.sh` + Section 6 of manual |
| 5 — Documentation | `operational-manual.md` + `final-reflection.md` |

> *An Architect does not follow a manual; they write it.*
