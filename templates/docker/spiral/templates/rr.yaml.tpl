version: "3"

rpc:
  listen: tcp://127.0.0.1:6001

server:
  command: "php app.php"
  relay: pipes

http:
  address: "{{HTTP_ADDRESS}}"
  middleware:
    - gzip
    - static
  pool:
    num_workers: {{NUM_WORKERS}}
    max_jobs: {{RR_HTTP_MAX_JOBS}}
    max_worker_memory: {{RR_HTTP_MAX_WORKER_MEMORY}}
    debug: {{RR_HTTP_DEBUG}}

logs:
  mode: "{{RR_LOG_MODE}}"
  level: "{{RR_LOG_LEVEL}}"
