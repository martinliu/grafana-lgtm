# LGTM 可观测性堆栈

基于 Docker Compose 的本地可观测性平台，包含指标、日志、追踪的完整采集和可视化。

## 快速开始

```bash
docker compose up -d
```

访问 Grafana: http://localhost:3000 (admin/admin)

## 服务列表

| 服务 | 端口 | 功能 |
|------|------|------|
| **Prometheus** | 9090 | 指标采集和查询 |
| **Loki** | 3100 | 日志存储和查询 |
| **Tempo** | 3200 | 分布式追踪存储 |
| **Grafana** | 3000 | 统一可视化仪表板 |
| **Alloy** | 4317-4318 | OpenTelemetry 采集器 |

## 架构说明

### 数据流向

```
应用程序 (OTEL SDK)
    ↓
Alloy 采集器 (4317/4318 OTLP)
    ├→ Docker 日志 → Loki (3100)
    ├→ 服务指标 → Prometheus (9090)
    └→ 应用追踪 → Tempo (3200)
    ↓
Grafana (3000)
    └→ 统一可视化展示
```

### 核心组件

1. **Alloy** - 统一采集器
   - 自动采集容器日志（Docker)
   - 定期抓取服务指标（Prometheus targets）
   - OTLP 接收：gRPC (4317) + HTTP (4318)

2. **Prometheus** - 时间序列数据库
   - 存储指标数据（90 天保留）
   - 支持远程写入（Alloy → Prometheus）

3. **Loki** - 日志聚合系统
   - 存储所有容器日志
   - 支持高效的日志查询

4. **Tempo** - 追踪存储
   - 存储应用分布式追踪
   - 支持 OTLP 协议

5. **Grafana** - 可视化平台
   - 统一仪表板
   - 支持日志、指标、追踪查询

## 连接应用

```bash
# 设置 OTLP 导出器（gRPC）
export OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:4317

# 或 HTTP
export OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:4318
```

## 常用命令

```bash
# 查看容器状态
docker compose ps

# 查看日志
docker compose logs -f <service>

# 重启服务
docker compose restart <service>

# 停止所有
docker compose down

# 清理数据重开（谨慎）
docker compose down && rm -rf *-data data-alloy && docker compose up -d
```

## 数据持久化

所有服务数据持久化到本地卷：
- `prometheus-data` - 指标数据
- `loki-data` - 日志数据
- `tempo-data` - 追踪数据
- `grafana-data` - Grafana 配置
- `alloy-data` - Alloy 采集位点

## 配置说明

- `docker-compose.yml` - 服务编排
- `alloy-config.yaml` - Alloy 采集配置
- `prometheus.yml` - Prometheus 抓取配置
- `loki-local-config.yaml` - Loki 存储配置
- `tempo-local.yaml` - Tempo 配置
- `grafana/datasources.yml` - 预置数据源
- `grafana/dashboards.yml` - 预置仪表板

---
如需自定义采集、数据源或仪表盘，请编辑对应配置文件或 Grafana UI。
