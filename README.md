# 🦞 ClawNOC Skills

[![Skills](https://img.shields.io/badge/skills-6-ff6b35)](https://github.com/clawnoc/clawnoc-skills)
[![Scripts](https://img.shields.io/badge/scripts-14-00d68f)](https://github.com/clawnoc/clawnoc-skills)
[![License](https://img.shields.io/badge/license-MIT-blue)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-OpenClaw-4a9eff)](https://github.com/openclaw)

AI Ops Agent skill pack for [OpenClaw](https://github.com/openclaw/openclaw). Automate CDN management, security scanning, monitoring, deployment verification, and documentation generation.

## Skills

| Skill | Scripts | Description |
|-------|---------|-------------|
| 🎯 clawnoc-noc | `noc-patrol.sh` | Full NOC pack — one-click patrol combining all skills |
| 🌐 clawnoc-cdn | `check-cache.sh` `invalidate-cloudfront.sh` | CDN cache management & diagnostics |
| 🔒 clawnoc-security | `check-ssl.sh` `check-ports.sh` `check-ssh-audit.sh` | Security scanning & audit |
| 📊 clawnoc-monitor | `check-system.sh` `check-disk-alert.sh` `check-health.sh` `alert-webhook.sh` | Monitoring & alerting |
| 🚀 clawnoc-deploy | `pre-deploy-check.sh` `post-deploy-verify.sh` | Deployment verification & rollback |
| 📋 clawnoc-doc | `gen-change-doc.sh` `gen-system-info.sh` | Auto documentation generation |

## Quick Start

```bash
# Install all skills
claw skill install clawnoc/clawnoc-noc

# Or install individually
claw skill install clawnoc/clawnoc-cdn
claw skill install clawnoc/clawnoc-security
```

## Usage

Talk to your agent in natural language:

```
"Help me clear CDN cache for www.example.com"
"Scan all SSL certificates expiry dates"
"Check disk and memory usage across all servers"
"Run a full NOC patrol"
"Generate a change document for today's operations"
```

Or run scripts directly:

```bash
# Full patrol
./skills/clawnoc-noc/noc-patrol.sh https://example.com

# Check system resources
./skills/clawnoc-monitor/check-system.sh

# SSL certificate check
./skills/clawnoc-security/check-ssl.sh example.com api.example.com

# Post-deploy verification (60s observation)
./skills/clawnoc-deploy/post-deploy-verify.sh https://example.com/health 60
```

## Supported Platforms

- Linux (CentOS / Ubuntu / Amazon Linux)
- macOS
- Cloud: AWS, GCP, Alibaba Cloud, Tencent Cloud, Volcengine

## License

MIT
