# NetBird Client

这是一个适用于 **1Panel 本地应用** 的 **NetBird 客户端容器** 封装，用于把当前服务器加入现有的 NetBird 网络。

## 说明

- 基于官方镜像：`netbirdio/netbird`
- 默认使用 `NB_SETUP_KEY` 自动注册
- 默认持久化目录：`./data/netbird`
- 默认启用能力：
  - `NET_ADMIN`
  - `SYS_ADMIN`
  - `SYS_RESOURCE`

> NetBird 官方 Docker 文档推荐为客户端增加 `SYS_ADMIN` 和 `SYS_RESOURCE`，并在 Docker Compose 示例中使用 `network_mode: host`。如为自建管理端，可通过 `NB_MANAGEMENT_URL` 指向你的管理地址。

## 安装参数

- **Image Tag**：镜像标签，默认 `latest`
- **Client Name**：NetBird 节点名称
- **Setup Key**：从 NetBird 控制台生成的 Setup Key
- **Management URL**：自建 NetBird 管理端地址；如果留空，将使用默认地址
- **Network Mode**：
  - `host`：推荐，和官方 Compose 示例更接近
  - `bridge`：更贴近普通容器网络模式
- **Disable NetBird SSH Server**：是否禁用 NetBird SSH Server

## 安装后检查

进入容器查看日志：

```bash
docker logs -f <容器名>
```

查看状态（若镜像内包含 CLI）：

```bash
docker exec -it <容器名> netbird status
```

## 数据目录

- `./data/netbird`：NetBird 客户端持久化数据

## 兼容建议

1. 建议宿主机内核支持 WireGuard/TUN。
2. 如使用自建 NetBird，`NB_MANAGEMENT_URL` 请填写完整地址，例如：
   - `https://netbird.example.com`
   - `https://api.example.com:443`
3. 如果发现 Docker 网桥模式下识别到的公网 IP 不正确，优先改为 `host` 模式。
