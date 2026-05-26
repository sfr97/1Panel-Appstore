# 魔方财务系统（ZJMF）

魔方财务系统是一套基于 PHP + MySQL 的财务与业务管理系统。这份 1Panel 应用模板会在应用层完成源码初始化和安装页默认值预填，便于在 1Panel 中直接部署。

## 应用说明

- 使用镜像：`mengfox/zjmf-finance:latest`
- 数据目录挂载：`./data/zjmf-finance:/var/www/html`
- 启动包装脚本：`latest/scripts/start-wrapper.sh`
- 安装模板来源：`/var/www/html/public/install.html`
- 数据库配置模板：`/var/www/html/public/install/config.php`

## 初始化流程

1. 1Panel 安装时先执行 `latest/scripts/init.sh`
2. `init.sh` 仅负责准备 `./data/zjmf-finance` 持久化目录
3. 容器启动前由 `start-wrapper.sh` 在空目录时自动初始化源码
4. 如果系统尚未安装，会将 1Panel 表单中的数据库信息和后台路径预填到 `install.html`
5. 随后进入官方安装流程，由程序自行导入数据库并生成正式配置

## 1Panel 表单参数

安装时请填写：

- 数据库服务
- 数据库端口
- 数据库编码
- 数据库名
- 数据库用户
- 数据库密码
- 后台路径
- HTTP 端口

其中：

- 数据库地址、库名、用户、密码、端口会预填到安装页表单
- 后台路径会预填到安装页的“后台路径”字段

## 运行说明

- Web 根目录固定为 `/public`
- 镜像已启用 `ionCube Loader`
- 已按官方安装文档要求关闭 `opcache`
- 如果你之前使用过旧模板并残留根目录 `config.php`，请删除 `./data/zjmf-finance/config.php` 后重启应用，以重新进入安装页

## 参考链接

- 安装文档：[魔方财务系统安装使用教程](https://www.idcsmart.com/wiki_list/640.html)
- 官方网站：[IDCsmart](https://www.idcsmart.com/)