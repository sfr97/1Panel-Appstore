# 智简魔方业务管理系统v10

智简魔方业务管理系统v10 是一套基于 PHP + MySQL 的业务管理核心系统。
这份 1Panel 应用模板只在应用层做初始化适配，不依赖继续修改 1Panel 宿主机计划任务。

## 应用说明

- 使用镜像：`mengfox/zjmf:latest`
- 数据目录挂载：`./data/zjmf:/var/www/html`
- 启动包装脚本：`latest/scripts/start-wrapper.sh`
- 安装模板来源：`/var/www/html/public/install/config.php`
- 正式配置文件：`/var/www/html/config.php`

## 初始化流程

1. 1Panel 安装时先执行 `latest/scripts/init.sh`
2. `init.sh` 只负责准备 `./data/zjmf` 持久化目录
3. 容器启动前由 `start-wrapper.sh` 完成源码初始化、安装页默认值预填和安装脚本补丁
4. 如果系统尚未安装，会把 1Panel 表单里的数据库信息预填到安装页
5. 随后进入官方安装流程，由程序自行导入数据库并最终生成根目录 `config.php`

## 自动化任务

应用启动后会由镜像内置的 `supervisord` 自动托管以下四个任务：

- `php /var/www/html/cron/cron.php`：每 60 秒执行一次
- `php /var/www/html/cron/task.php`：每 5 秒执行一次
- `php /var/www/html/cron/on_demand_cron.php`：每 60 秒执行一次
- `php /var/www/html/cron/task_notice.php`：每 5 秒执行一次

因此安装完成后，不需要再额外在宿主机或 1Panel 面板里手工创建这四个计划任务。
如果后台“自动化”页仍然提示异常，请先重启应用一次，并检查容器日志里是否能看到 `supervisord` 已启动这些内置任务进程。

## 与官方安装流程的关系

上游程序的实际逻辑是：

- 根目录没有 `config.php` 时，`/index.php` 会跳转到 `/install/index.html`
- 安装步骤会先生成 `config.simple.php`
- 最后一步才会把 `config.simple.php` 重命名为根目录 `config.php`

因此这份 1Panel 模板不会提前生成根目录 `config.php`，否则会跳过官方安装页并导致未初始化数据库时首页 500。

## 1Panel 表单参数

安装时请填写：

- 数据库服务
- 数据库端口
- 数据库编码
- 数据库名
- 数据库用户
- 数据库密码
- 后台目录
- HTTP 端口

其中：

- 数据库地址、库名、用户、密码、端口会预填到安装页数据库表单
- 后台目录会在安装脚本里替换默认随机后台目录

## 安装完成后 404 的原因

如果安装完成后点击后台地址出现 OpenResty 404，通常不是容器内伪静态失效，而是安装脚本生成后台地址时没有带上 1Panel/OpenResty 的反代子路径。
这份模板已经在 `start-wrapper.sh` 里补丁修复了安装脚本的后台地址生成逻辑。

## 出现 500 的排查

如果你之前使用过旧版本模板，可能已经在 `./data/zjmf` 下生成了旧的根目录 `config.php`。
这会让官方安装页被跳过，并直接进入未完成初始化的程序，从而返回 500。

这种情况下请删除：

- `./data/zjmf/config.php`

然后重启应用，再重新进入安装页。

## 参考链接

- 项目仓库：[idcsmart/ZJMF-CBAP](https://github.com/idcsmart/ZJMF-CBAP)
- 安装文档：[业务系统使用文档](https://www.idcsmart.com/wiki_list/933.html)