#!/bin/bash

# Install prometheus
# https://www.fosslinux.com/10398/how-to-install-and-configure-prometheus-on-centos-7.htm
# https://endoflife.date/prometheus



function prometheus_install() 
{
    set -e
    local appName=prometheus
    local version=2.53.3
    local data=/var/lib/$appName
    local port=9090
    # local prometheus_config=
    # local file_config=
    # local INSTALL_DIR=/usr/share
    # echo $@
    local _parameters=
    read_application_arguments $@ 
    if [ -n "$_parameters" ]; then set $_parameters; fi

    # data=${data:-"$1"}
    # data=${data%"/"} 
    # INSTALL_DIR=${INSTALL_DIR%"/"} 

    case `platform_name` in 
        alpine)  
            install prometheus
            exit 0;
        ;;
    esac


    if ! getent passwd $appName > /dev/null 2>&1; then
        sudo groupadd --system $appName
        sudo useradd --no-create-home --shell /bin/false -g $appName $appName
    fi
    
    
    sudo mkdir -p /etc/$appName /var/lib/$appName
    sudo chown $appName:$appName /etc/$appName /var/lib/$appName
    
    if [ ! -f /tmp/prometheus-$version.tar.gz ];
    then 
      curl -fSL  https://github.com/prometheus/prometheus/releases/download/v${version}/prometheus-${version}.linux-amd64.tar.gz -o /tmp/prometheus-$version.tar.gz
    fi
    cd /tmp
    tar -xvzf prometheus-$version.tar.gz && rm -f prometheus-$version.tar.gz
    rm -rf prometheus-$version && mv prometheus-$version.linux-amd64 prometheus-$version
    #
    sudo cp prometheus-$version/prometheus /usr/bin/
    sudo cp prometheus-$version/promtool /usr/bin/
    sudo chown prometheus:prometheus /usr/bin/prometheus
    sudo chown prometheus:prometheus /usr/bin/promtool
    #
    sudo cp -r prometheus-$version/consoles /etc/prometheus
    sudo cp -r prometheus-$version/console_libraries /etc/prometheus
    sudo chown -R prometheus:prometheus /etc/prometheus/consoles
    sudo chown -R prometheus:prometheus /etc/prometheus/console_libraries
    rm -r prometheus-$version
    #
    # sudo vim /etc/prometheus/prometheus.yml

    if [ ! -f /etc/prometheus/prometheus.yml ]; then sudo touch /etc/prometheus/prometheus.yml; fi
    sudo tee /etc/prometheus/prometheus.yml << EOF > /dev/null
global:
  scrape_interval: 10s

scrape_configs:
  - job_name: 'prometheus_master'
    scrape_interval: 5s
    static_configs:
      - targets: ['localhost:$port']
EOF
    sudo chown prometheus:prometheus /etc/prometheus/prometheus.yml
            
    if [[ -d /etc/systemd/system && ! -f /etc/systemd/system/prometheus.service ]]; then

      # sudo touch /etc/systemd/system/prometheus.service
      if [ ! -f /etc/default/prometheus ]; then sudo touch /etc/default/prometheus; fi
      sudo tee /etc/systemd/system/prometheus.service << EOF > /dev/null
[Unit]
Description=Prometheus
Wants=network-online.target
After=network-online.target

[Service]
#User=prometheus
Group=prometheus
Type=simple
EnvironmentFile=/etc/default/prometheus
ExecStart=/usr/bin/prometheus \
--config.file /etc/prometheus/prometheus.yml \
--storage.tsdb.path /var/lib/prometheus/ \
--web.listen-address 0.0.0.0:$port \
--web.console.templates=/etc/prometheus/consoles \
--web.console.libraries=/etc/prometheus/console_libraries \$OPTIONS

[Install]
WantedBy=multi-user.target
EOF

    sudo systemctl daemon-reload
    # sudo systemctl enable prometheus
    # sudo systemctl unmask prometheus.service

  fi
}


