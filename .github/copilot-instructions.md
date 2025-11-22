## 快速上手提示（给 AI 代码代理）

下面的说明专注于让 AI 代理在本仓库中快速完成常见改动（配置、仪表盘、采集规则、示例查询）。只记录可在代码中发现并可执行的模式与约定。

### 大体架构（必须先了解）
- 本项目是一个基于 Docker Compose 的本地可观测性堆栈（指标、日志、追踪、可视化）。核心服务在 `docker-compose.yml`：
  - `prometheus` (9090) — 指标采集/查询，TSDB 保留为 2160h（90 天），配置文件：`prometheus.yml`
  - `loki` (3100) — 日志存储，配置：`loki-local-config.yaml`
  - `tempo` (3200/4317) — 分布式追踪存储，配置：`tempo-local.yaml`
  - `grafana` (3000) — 可视化；预置数据源与看板在 `grafana/datasources.yml` 和 `grafana/dashboards/`；覆盖配置 `grafana/custom.ini`
  - `alloy` (4317/4318/12345) — 采集器，读取 Docker socket 自动采集容器日志并转发到 Loki/Prometheus/Tempo，配置在 `alloy-config.yaml`

### 关键约定与可修改点（在代码中可直接修改）
- 镜像版本统一在 `docker-compose.yml` 顶部的 `x-versions` 节中定义，修改版本请更新这里。
- Grafana 的数据源和仪表盘通过文件预置：修改 `grafana/datasources.yml` 或将 JSON 放到 `grafana/dashboards/`，Grafana 会自动 provision（参见 `grafana/dashboards.yml`）。
- Alloy 依赖宿主机 Docker socket：`/var/run/docker.sock` 被挂载为只读。修改采集行为请编辑 `alloy-config.yaml`。
- Prometheus 的保留时间在 `docker-compose.yml` 的 `command` 中以 `--storage.tsdb.retention.time` 指定。

### 常用开发/调试命令（必知）
- 启动：`docker compose up -d`（仓库 README 也有）
- 查看服务与状态：`docker compose ps`
- 查看某服务日志：`docker compose logs -f grafana` 或 `docker compose logs -f alloy`
- 停止/清理：`docker compose down`。若需要重置数据卷，手工删除命名卷目录或使用 `docker volume rm`（注意数据丢失风险）。

### 健康检查与端点（用于自动化与调试）
- Prometheus readiness: `http://localhost:9090/-/ready`
- Loki readiness: `http://localhost:3100/ready`
- Grafana health: `http://localhost:3000/api/health`
- Tempo 查询端口: `http://localhost:3200`（没有容器内健康 probe）

### OTLP / 追踪 接入要点（常被误写）
- Grafana 的 OTLP 配置在 `docker-compose.yml` 环境变量中，关键点：`GF_TRACING_OPENTELEMETRY_OTLP_ADDRESS=tempo:4317`（写成 `host:port`，不要加 `http://`）。
- Alloy 暴露 OTLP gRPC/HTTP：容器映射 `4317:4317` 和 `4318:4318`，外部应用可通过 `OTEL_EXPORTER_OTLP_ENDPOINT=localhost:4317` 或 `localhost:4318` 发送追踪。

### 仪表盘与查询示例（直接可复制）
- JVM 堆内存（Prometheus 查询示例，见 `grafana/dashboards/springboot-observability.json`）:
  - `process_runtime_jvm_memory_usage{service_name="springboot-otel-demo", type="heap"}`
- Loki 日志标签示例（同看板）:
  - `{service_name="springboot-otel-demo"}`

### 变更推荐流程（对 AI 的具体建议）
1. 修改配置文件（例如 `prometheus.yml`、`alloy-config.yaml`、或 `grafana/dashboards/*`）。
2. 运行 `docker compose up -d`（或仅重启受影响服务 `docker compose restart <service>`）。
3. 用健康端点或 `docker compose logs -f <service>` 验证是否生效。

### 编辑注意事项（易错点）
- 修改 Grafana 数据源时，请同时保持 `url` 指向容器名（例如 `http://prometheus:9090`），不要写 `localhost`（在容器内解析为容器自身）。
- `depends_on` 中部分服务使用 `condition: service_healthy`，而 `tempo` 使用 `condition: service_started`（因为镜像未提供健康检查），AI 代理在调整依赖顺序时要保留这一差异。
- Alloy 需要访问 Docker socket，CI 或受限环境里可能无法运行；在这些环境中先跳过与 Alloy 相关的端到端测试或模拟其输出。

如果你需要我把说明合并为更短或更技术化的版本，或补充 CI/本地 macOS 特定注意点（例如 Docker Desktop 的 socket 权限），告诉我我会迭代。
