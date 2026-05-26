# ANI-RSS

ANI-RSS is an auto anime RSS subscription and download tool for anime fans. It supports Docker quick deployment, auto episode tracking, download, and push, compatible with mainstream downloaders (qBittorrent, Aria2, etc.), making anime following smarter and easier.

![](https://raw.githubusercontent.com/xiaoY233/PicList/main/public/assets/ANI-RSS.png)

![](https://img.shields.io/badge/Copyright-arch3rPro-ff9800?style=flat&logo=github&logoColor=white)

## Main Features

- **Anime RSS Subscription**: Auto subscribe to anime updates, support multiple sources.
- **Auto Download & Push**: Integrate with qBittorrent, Aria2, etc., auto push download tasks.
- **Multi-Platform Support**: Compatible with Docker, Linux, Synology NAS, etc.
- **Flexible Config**: Custom sources, download path, push rules, etc.
- **Web UI**: Intuitive web management.
- **Multi-User & Permissions**: Support multi-user collaboration and permission control.
- **Logs & Notification**: Detailed logs, various notification methods.

## Deployment Modes

ANI-RSS is recommended to be deployed via Docker, supporting both host and bridge network modes:

- **host mode (recommended)**: Use host network, fixed port, suitable for full network capability.
- **bridge mode**: Custom port mapping, suitable for port isolation and unified management.

> Config directory (in container): `/config`, host path customizable, recommended to persist.

## Typical Use Cases

- Auto anime tracking and download, real-time episode push
- Multi-source anime RSS aggregation and management
- Home/Personal NAS anime automation
- Multi-user collaboration and permission management

## Platform & Architecture Support

- Docker, Linux, Synology NAS, etc.
- Supports amd64, arm64, arm/v7, etc.

## Quick Deployment (Docker Example)

**host network mode (recommended)**
```yaml
version: "3"
services:
  ani-rss:
    image: wushuo894/ani-rss:latest
    container_name: ani-rss
    environment:
      - PUID=0
      - PGID=0
      - UMASK=022
      - PORT=7789
      - CONFIG=/config
      - TZ=Asia/Shanghai
    volumes:
      - ./ani-rss-config:/config
      - /your/media/path:/Media
    restart: always
    network_mode: host
```

**bridge network mode**
```yaml
version: "3"
services:
  ani-rss:
    image: wushuo894/ani-rss:latest
    container_name: ani-rss
    environment:
      - PUID=0
      - PGID=0
      - UMASK=022
      - PORT=7789
      - CONFIG=/config
      - TZ=Asia/Shanghai
    volumes:
      - ./ani-rss-config:/config
      - /your/media/path:/Media
    ports:
      - "7789:7789"
    restart: always
```

## FAQ

- **Q: Default admin port and credentials?**
  A: Default port 7789, username/password: admin/admin.
- **Q: How to persist config?**
  A: Mount host directory to `/config`, e.g. `./ani-rss-config:/config`.
- **Q: Which downloaders are supported?**
  A: qBittorrent, Aria2, etc.
- **Q: Which platforms are supported?**
  A: Docker, Linux, Synology NAS, etc.
- **Q: Official docs?**
  A: [https://docs.wushuo.top/deploy/docker](https://docs.wushuo.top/deploy/docker)

## Official Docs & Support

- Website: [https://docs.wushuo.top/](https://docs.wushuo.top/)
- Install Guide: [https://docs.wushuo.top/deploy/docker](https://docs.wushuo.top/deploy/docker)
- GitHub: [https://github.com/wushuo894/ani-rss](https://github.com/wushuo894/ani-rss) 