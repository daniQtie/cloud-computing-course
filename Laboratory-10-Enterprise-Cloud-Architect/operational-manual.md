# CCM101 – Cloud Computing
## Enterprise Cloud Architect – Operational Manual

**Project:** Secure Multi-Tier Web Application
**Application Stack:** WordPress + MySQL
**Prepared by:** _[Your Name Here]_
**Section:** BSIT 2A
**Instructor:** Jenkielyn C. Torres
**Date:** October 2026

---

## 1. Executive Summary

This manual documents the design, deployment, hardening, and day-two operations of **CloudNova's** private cloud for the Fortune 500 client. The platform runs a **two-tier containerized WordPress stack** (WordPress + MySQL 8) on a hardened **Ubuntu Server** virtual machine. Data persistence is guaranteed through named Docker volumes, perimeter security through **UFW** with a default-deny policy, and operational resilience through a scheduled **Bash + Cron** backup pipeline with 7-day rotation.

The design satisfies every requirement laid down in Mission 10: planned architecture, multi-tier deployment, persistent storage, firewall hardening, autonomous automation, and executive-grade documentation.

---

## 2. Architecture Overview

See `architecture-diagram.svg` in this folder.

| Layer | Component | Purpose |
|---|---|---|
| Host | Windows 10 Laptop | Developer workstation (browser, SSH) |
| Hypervisor | VirtualBox / VMware (Type-2) | Isolates the server from the host |
| Guest OS | Ubuntu Server 24.04 LTS | Minimal headless Linux |
| Firewall | UFW (host-based) | Default DENY; allows only 22, 8080 |
| Runtime | Docker Engine + Compose v2 | Container orchestration |
| App Tier | `wordpress:6.5-apache` | Web/App server |
| Data Tier | `mysql:8.0` | Relational database |
| Storage | Docker named volumes `wp_data`, `db_data` | Survives reboots |
| Automation | Bash + cron | Nightly backup, log, rotate |

### Network Flow
`Browser :8080` → `UFW` → `Host port 8080` → `WordPress container :80` → `MySQL container :3306` (internal only).
Port 3306 is **never** exposed to the host.

---

## 3. Pre-Deployment Checklist

- [ ] Hypervisor installed (VirtualBox 7+ or VMware Workstation)
- [ ] Ubuntu Server 24.04 LTS ISO downloaded
- [ ] 2 vCPU, 4 GB RAM, 20 GB disk provisioned
- [ ] Network adapter: **Bridged** or **Host-Only** (static IP `192.168.56.10` recommended)
- [ ] SSH enabled during OS install
- [ ] Non-root admin user created (`admin`)
- [ ] GitHub repository `CCM101-jentorres` cloned on the VM

---

## 4. Deployment Procedure

### 4.1 Prepare the VM
```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y curl git ufw ca-certificates gnupg
```

### 4.2 Install Docker Engine + Compose
```bash
# Add Docker's official repo
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
  | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo $VERSION_CODENAME) stable" \
  | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Allow current user to run docker without sudo
sudo usermod -aG docker $USER
newgrp docker

docker --version
docker compose version
```

### 4.3 Deploy the Stack
```bash
sudo mkdir -p /opt/cloudnova
sudo chown $USER:$USER /opt/cloudnova
cd /opt/cloudnova

# Copy docker-compose.yml and .env.example from the GitHub repo
cp .env.example .env
nano .env                      # set strong passwords

docker compose up -d
docker compose ps              # should show both containers "Up (healthy)"
```

Open a browser on the host: `http://192.168.56.10:8080` and complete the WordPress wizard.

### 4.4 Verify Persistent Storage
```bash
docker volume ls | grep cloudnova
docker compose down            # containers stop
docker compose up -d           # bring back — data must still be present
```

---

## 5. Security Hardening (UFW)

```bash
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 22/tcp          # SSH
sudo ufw allow 8080/tcp        # WordPress
sudo ufw enable
sudo ufw status verbose
```

Expected output:
```
Status: active
Default: deny (incoming), allow (outgoing)
22/tcp                     ALLOW IN    Anywhere
8080/tcp                   ALLOW IN    Anywhere
```

Additional hardening performed:
- `PermitRootLogin no` and `PasswordAuthentication no` in `/etc/ssh/sshd_config`
- Automatic security updates: `sudo apt install -y unattended-upgrades`
- `.env` file is `chmod 600` and excluded from git via `.gitignore`
- MySQL port `3306` is **not** published to the host — only reachable inside the `backend` Docker network.

---

## 6. Automation & Disaster Recovery

### 6.1 Install the Backup Script
```bash
sudo cp automation-script.sh /usr/local/bin/cloudnova-backup.sh
sudo chmod +x /usr/local/bin/cloudnova-backup.sh
sudo mkdir -p /var/backups/cloudnova
sudo touch /var/log/cloudnova-backup.log
```

### 6.2 Schedule with Cron
Edit root's crontab:
```bash
sudo crontab -e
```
Add:
```
# CloudNova nightly backup at 02:00
0 2 * * *  /usr/local/bin/cloudnova-backup.sh >> /var/log/cloudnova-backup.log 2>&1
```

### 6.3 Verify
```bash
sudo /usr/local/bin/cloudnova-backup.sh      # manual dry-run
ls -lh /var/backups/cloudnova/
tail -n 20 /var/log/cloudnova-backup.log
```

What the script does, step by step:
1. Confirms Docker and the DB container are up.
2. Runs `mysqldump --all-databases --single-transaction`, gzips the output.
3. `tar`s the `wp_data` volume (uploads, themes, plugins).
4. Hits `http://localhost:8080` for a health check.
5. Deletes any backup older than **7 days**.
6. Logs size + timestamp of every run.

### 6.4 Restore Procedure (should disaster strike)
```bash
# 1. Stop the stack
cd /opt/cloudnova && docker compose down

# 2. Restore DB
gunzip < /var/backups/cloudnova/db_<timestamp>.sql.gz \
  | docker exec -i cloudnova_db mysql -uroot -p"$MYSQL_ROOT_PASSWORD"

# 3. Restore WP files
docker run --rm -v laboratory-10-enterprise-cloud-architect_wp_data:/target \
  -v /var/backups/cloudnova:/backup alpine:3.20 \
  sh -c "cd /target && tar -xzf /backup/wp_<timestamp>.tar.gz"

# 4. Start again
docker compose up -d
```

---

## 7. Day-Two Operations Cheat Sheet

| Task | Command |
|---|---|
| View running containers | `docker compose ps` |
| Tail WP logs | `docker compose logs -f wordpress` |
| Tail DB logs | `docker compose logs -f db` |
| Restart stack | `docker compose restart` |
| Update images | `docker compose pull && docker compose up -d` |
| Disk use | `df -h && docker system df` |
| Firewall status | `sudo ufw status numbered` |
| List backups | `ls -lh /var/backups/cloudnova/` |
| Last backup log | `tail -n 50 /var/log/cloudnova-backup.log` |

---

## 8. Troubleshooting Playbook

| Symptom | Likely Cause | Remedy |
|---|---|---|
| Browser can't reach `:8080` | UFW blocking / wrong IP | `sudo ufw status`, check VM IP with `ip a` |
| WordPress “Error establishing DB connection” | DB container not healthy | `docker compose logs db` — usually wrong `.env` password |
| Disk filling up | Old backups not rotated | Check `RETENTION_DAYS`, cron timing |
| Cron job never ran | Not in root's crontab | `sudo crontab -l`, check `/var/log/syslog` |
| Lost admin password | — | Use `wp-cli` inside container: `docker exec -it cloudnova_wp wp user update ...` |

---

## 9. Live Defense Deployment (KillerCoda / Fresh Instance)

In a brand-new Ubuntu shell, the entire stack can be rebuilt in under 5 minutes:
```bash
git clone https://github.com/<your-user>/CCM101-jentorres.git
cd CCM101-jentorres/Laboratory-10-Enterprise-Cloud-Architect
cp .env.example .env
docker compose up -d
```
That single sequence — plus the UFW block and the cron entry — reproduces production.

---

## 10. Sign-off

Prepared and defended by the **Enterprise Cloud Architect**.
_"An Architect does not follow a manual; they write it."_
