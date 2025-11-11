# Grafana LGTM 增强版一键启动测试环境

本项目基于 Docker Compose，集成了指标、日志、Trace、数据库与可视化，适合本地开发与测试。

## 包含服务

- **Prometheus**：指标采集与查询
- **Loki**：日志存储与检索
- **Tempo**：分布式 Trace 存储
- **ClickHouse**：高性能列式数据库
- **Grafana**：统一可视化平台，预装多数据源插件
- **Promtail / Fluent Bit**：容器日志采集

## 快速启动

```bash
# 启动所有服务
cd grafana-lgtm
# 推荐使用 Docker Desktop
# 如首次运行建议拉取最新镜像
# docker compose pull

docker compose up -d
```


### 初始化 ClickHouse 数据库（可选）

```bash
docker exec -i clickhouse clickhouse-client -n < clickhouse-bootstrap.sql

## 访问入口

- Grafana: [http://localhost:3000](http://localhost:3000)  （默认账号：admin/admin）
- Prometheus: [http://localhost:9090](http://localhost:9090)
- Loki: [http://localhost:3100](http://localhost:3100)
- Tempo: [http://localhost:3200](http://localhost:3200)
- ClickHouse: [http://localhost:8123](http://localhost:8123)

## 日志与数据持久化

- 所有服务数据均持久化到本地卷，重启/升级不丢数据。
- 日志采集支持 Promtail/Fluent Bit，可对接 Loki/ClickHouse。

## 说明

- 镜像版本集中在 compose 文件顶部，升级只需改一处。
- 配置文件均可外置挂载，便于自定义。
- Grafana 已预装 ClickHouse 插件，可直接添加数据源。

---
如需自定义采集、数据源或仪表盘，请编辑对应配置文件或 Grafana UI。
