# Examples

Sample outputs from ClawNOC skills (sanitized).

## check-cache.sh

```
$ ./check-cache.sh https://www.example.com/
HTTP/2 200
x-cache: Hit from cloudfront
age: 3847
cache-control: max-age=86400
✅ Cache HIT — Age: 3847s
```

## check-ssl.sh

```
$ ./check-ssl.sh example.com api.example.com
example.com      — Expires: 2026-09-15 — 187 days remaining ✅
api.example.com  — Expires: 2026-04-02 —  21 days remaining ⚠️
```

## check-disk-alert.sh

```
$ ./check-disk-alert.sh 85
/dev/xvda1  78% — OK
/dev/xvdf   92% — ⚠️ ALERT: exceeds 85% threshold
```

## check-system.sh

```
$ ./check-system.sh
CPU: 23.4% | MEM: 2.1G/4.0G (52%) | DISK: 78% | Load: 0.42 0.38 0.31 | Uptime: 47 days
```

## noc-patrol.sh

```
$ ./noc-patrol.sh
=== ClawNOC Full Patrol ===
[System]  CPU: 23% | MEM: 52% | DISK: 78% | Load: 0.42
[SSL]     example.com: 187 days ✅ | api.example.com: 21 days ⚠️
[Ports]   22/tcp ssh | 80/tcp nginx | 443/tcp nginx | 3000/tcp node
[Health]  https://www.example.com/ — 200 OK (0.234s) ✅
[Disk]    All partitions below 85% ✅
=== Patrol Complete: 4 OK, 1 WARN, 0 FAIL ===
```
