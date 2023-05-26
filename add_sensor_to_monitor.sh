#!/bin/bash
if [ "$#" -ne 2 ]; then
    echo "Add hostname please"
    exit
fi
hostname=$1
influxdb_pass=$2
# Install telegraf
wget -q https://repos.influxdata.com/influxdata-archive_compat.key -O influxdata-archive_compat.key
echo '393e8779c89ac8d958f81f942f9ad7fb82a25e133faddaf92e15b16e6ac9ce4c influxdata-archive_compat.key' | sha256sum -c && cat influxdata-archive_compat.key | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/influxdata-archive_compat.gpg > /dev/null
echo 'deb [signed-by=/etc/apt/trusted.gpg.d/influxdata-archive_compat.gpg] https://repos.influxdata.com/debian stable main' | sudo tee /etc/apt/sources.list.d/influxdata.list
sudo apt-get update -y && sudo apt-get install -y telegraf

cat > /etc/telegraf/telegraf.d/custom.conf << EOF
# Global Agent Configuration
[agent]
  hostname = "$hostname"
  flush_interval = "10s"
  interval = "10s"


# Input Plugins
[[inputs.cpu]]
    percpu = true
    totalcpu = true
    collect_cpu_time = false
    report_active = false
[[inputs.disk]]
    ignore_fs = ["tmpfs", "devtmpfs", "devfs"]
[[inputs.io]]
[[inputs.mem]]
[[inputs.net]]
[[inputs.system]]
[[inputs.swap]]
[[inputs.netstat]]
[[inputs.processes]]
[[inputs.kernel]]

# Output Plugin InfluxDB
[[outputs.influxdb]]
  database = "telegraf"
  urls = [ "http://54.254.47.35:8086" ]
  username = "telegraf2"
  password = "$influxdb_pass"
  
#Telegraf provides telegraf command to manage the configuration, 
#including generate the configuration itself, run the command as below.
EOF
service telegraf restart
