# Lsky Pro+

这个目录是一个 1Panel 应用包，现已改为对齐官方 Docker 版本的部署方式，并补上了 1Panel 的数据库、PostgreSQL 和 Redis 关联自动配置。

## 官方链接

- 官网：https://www.lsky.pro
- 文档：https://docs.lsky.pro/guide/install
- Docker 镜像：https://hub.docker.com/r/0xxb/lsky-pro
- 开源仓库：https://github.com/lsky-org/lsky-pro

## 已调整内容

- 将运行镜像改为官方镜像 `0xxb/lsky-pro:latest`
- 将容器映射端口改为官方镜像使用的 `8000`
- 将持久化目录改为官方推荐挂载路径
  - `./data/lskypro -> /app/storage/app`
  - `./data/lskypro/themes -> /app/themes`
- 将应用元数据中的站点、文档和仓库链接改为官方地址
- 增加 1Panel 数据库表单，支持 MySQL、PostgreSQL 和 Redis 关联
- 通过 `latest/scripts/init.sh` 将 1Panel 生成的 `PANEL_DB_*`、`PANEL_REDIS_*` 自动转换为官方文档中的 `DB_*`、`REDIS_*`、`CACHE_STORE`、`SESSION_DRIVER`、`QUEUE_CONNECTION`
- `docker-compose.yml` 改为读取 1Panel 生成的 `.env`，容器直接使用官方环境变量

## 使用说明

首次启动前请确保 `./data/lskypro` 是空目录。安装时选择 1Panel 的数据库服务后，初始化脚本会自动写入官方所需的数据库和 Redis 环境变量：

- 数据库类型会自动映射为官方 `DB_CONNECTION`，其中 PostgreSQL 会转换为 `pgsql`
- 数据库端口默认按类型自动取值
  - MySQL: `3306`
  - PostgreSQL: `5432`
- Redis 未填写端口时默认使用 `6379`

如果后续需要手动调整，可继续参考官方文档中的 `.env` 配置说明。
