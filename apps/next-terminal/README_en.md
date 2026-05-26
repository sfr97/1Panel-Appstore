## Overview

Next Terminal is a web-based interactive auditing bastion host integrating Apache Guacamole. It supports RDP/SSH/VNC/TELNET/Kubernetes access from the browser, with session auditing and recording.

## Default Account

- Username: `admin`
- Password: `admin`

## Ports

- Web UI: configurable (default 10809 → container 8088)
- SSH Server: configurable (default 10203 → container 2022)

## Data

- `./data`: persistent data (sqlite files included)
- `./logs`: logs
