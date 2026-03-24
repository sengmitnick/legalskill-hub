# Puma 配置
# 生产环境：Railway/Docker 单进程部署，使用多线程模式
# threads: min=3, max=5（内存友好；I/O 密集型场景线程比 worker 更高效）

threads_count = ENV.fetch("RAILS_MAX_THREADS", 5).to_i
threads threads_count, threads_count

# Use APP_PORT from environment, fallback to PORT, then default 3000
port ENV.fetch("APP_PORT") { ENV.fetch("PORT", "3000") }

# Worker 数量（0 = 单进程模式，适合 Railway 内存受限环境）
# 如果内存充足可设为 2，需同时将 cache_store 改为 Redis
workers ENV.fetch("WEB_CONCURRENCY", 0).to_i

# 每个 worker 预加载应用（copy-on-write 节省内存）
preload_app!

# Worker 复用后重连数据库
on_worker_boot do
  ActiveRecord::Base.establish_connection if defined?(ActiveRecord)
end

plugin :tmp_restart

pidfile ENV["PIDFILE"] if ENV["PIDFILE"]
