-- 1) 确保 Grafana 用户存在且有读取 system 的权限（如你已创建可忽略密码行）
CREATE USER IF NOT EXISTS grafana IDENTIFIED BY 'StrongPass123!';
GRANT SELECT ON system.* TO grafana;
GRANT SELECT ON *.* TO grafana; -- 看板里偶尔会查非 system 表，可按需放宽/收紧

-- 2) 造一张 MergeTree 表并写入数据，触发 part/merge 日志，便于“Cluster/Data/Query Analysis” 看板
CREATE DATABASE IF NOT EXISTS demo;
CREATE TABLE IF NOT EXISTS demo.mt
(
  d  Date,
  id UInt64
)
ENGINE = MergeTree
PARTITION BY d
ORDER BY id;

INSERT INTO demo.mt SELECT today(), number FROM numbers(500000);
OPTIMIZE TABLE demo.mt FINAL; -- 触发合并，产生 system.part_log 事件

-- 3) 批量跑一些查询，产生 query_log / query_thread_log / event_log / trace_log
SET log_queries = 1;
SELECT count() FROM demo.mt;
SELECT sum(id) FROM demo.mt WHERE id % 7 = 0;
SELECT avg(id) FROM demo.mt WHERE id < 100000;

-- 4) 立即把内存中的日志刷盘到 *_log 表
SYSTEM FLUSH LOGS;
