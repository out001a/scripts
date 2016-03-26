## author
shanhuanming <out001a@gmail.com>

## How to Use

1. Edit `conf/process` to config your processes to be monitored.
2. Make scripts under `alert` and script `worker.sh` executable.
    chmod +x alert/* worker.sh
3. Run it repeatly with crontab
    `*/5 * * * * ./worker.sh >> ./log/worker.log 2>&1`
