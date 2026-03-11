# 🦞 ClawNOC Skills

AI Ops Agent skill pack for [OpenClaw](https://github.com/openclaw/openclaw).

## Skills

| Skill | Description |
|-------|-------------|
| clawnoc-noc | Full NOC pack — all skills combined |
| clawnoc-cdn | CDN cache management & diagnostics |
| clawnoc-security | Security scanning & audit |
| clawnoc-monitor | Monitoring & alerting |
| clawnoc-deploy | Deployment verification & rollback |
| clawnoc-doc | Auto documentation generation |

## Install

```bash
# Install all skills
claw skill install clawnoc/clawnoc-noc

# Or install individually
claw skill install clawnoc/clawnoc-cdn
```

## Usage

Talk to your agent in natural language:

```
"Help me clear CDN cache for www.example.com"
"Scan API keys in all cloud projects"
"Check disk and memory usage across all servers"
"Verify the latest deployment is healthy"
"Generate a change document for today's operations"
```

## License

MIT
