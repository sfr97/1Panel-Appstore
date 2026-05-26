# XArrPay Merchant

这是 XArrPay Merchant 的 1Panel 本地应用目录。

## 行为

- 镜像内置完整项目到 `/opt/xarrpay-merchant`。
- 1Panel 只挂载一个目录到容器 `/app`。
- 容器启动时，如果 `/app` 是空挂载目录，会把 `/opt/xarrpay-merchant` 的完整项目复制到 `/app`。
- 如果 `/app` 已有内容，只补齐缺失的核心文件和空运行目录，不覆盖已有配置。
- 如果 1Panel 初始化了 `config/config.yml`，安装脚本会复制到挂载目录的 `config/config.yml`。
- 启动时由 `scripts/start.sh` 根据 `PANEL_DB_*` 环境变量生成 `/app/config/config.yaml`；如果 `/app/config/config.yml` 不存在，会同步补一份，已有 `config.yml` 不会被覆盖。

## 说明

- 这个目录是 1Panel 应用包，不在 1Panel 内构建镜像。
- 镜像 `xarrpay/xarrpay-merchant:1.5.0.0` 需要提前用外层项目构建并推送，且镜像内必须包含 `/opt/xarrpay-merchant`。
- 数据库端口按类型自动取默认值：MySQL/MariaDB `3306`，PostgreSQL `5432`。
- Redis 服务填写但端口为空时，默认使用 `6379`。
- 对外端口默认 `32000`。
