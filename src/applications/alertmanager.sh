#!/bin/bash

# Install alertmanager


function alertmanager_install() 
{
    set -e
    local appName=alertmanager
    local version=0.24.0
    # local data=/var/lib/$appName
    local data_dir=/var/lib/$appName
    # local INSTALL_DIR=/usr/share
    local port=
    
    local _parameters=
    read_application_arguments $@ 
    if [ -n "$_parameters" ]; then set $_parameters; fi

    # case `platform_name` in 
    #     alpine)  
    #         install alertmanager
    #         exit 0;
    #     ;;
    # esac

    cd /tmp
    # https://linuxhint.com/install-configure-prometheus-alert-manager-ubuntu/
    curl -fSL https://github.com/prometheus/alertmanager/releases/download/v$version/alertmanager-$version.linux-amd64.tar.gz -o /tmp/alertmanager-$version.tar.gz
    tar xzf /tmp/alertmanager-$version.tar.gz && rm -f /tmp/alertmanager-$version.tar.gz

    # sudo mkdir -p $INSTALL_DIR/$appName-$version

    sudo mkdir -p $data_dir /etc/$appName
    sudo cp -f alertmanager-$version.linux-amd64/amtool /usr/bin
    sudo cp -f alertmanager-$version.linux-amd64/alertmanager /usr/bin
    sudo cp -f alertmanager-$version.linux-amd64/alertmanager.yml /etc/$appName
    
    #  $INSTALL_DIR/$appName-$version && rm -rf alertmanager-$version.linux-amd64/
    # sudo rm -rf $INSTALL_DIR/$appName
    # sudo ln -s $INSTALL_DIR/$appName-$version $INSTALL_DIR/$appName

    if ! getent passwd $appName > /dev/null 2>&1; then
        sudo groupadd --system $appName
        sudo useradd --no-create-home --shell /bin/false -g $appName $appName
    fi

    sudo chown -Rf $appName:$appName $data_dir /etc/$appName
    # sudo rm -rf /etc/$appName/alertmanager.yml /usr/bin/alertmanager
    # sudo ln -s $INSTALL_DIR/$appName/alertmanager /usr/bin


    if [[ -d /etc/systemd/system ]]; then
      sudo tee /etc/systemd/system/$appName.service << EOF > /dev/null
[Unit]
Description=Alertmanager for prometheus
Wants=network-online.target
After=network-online.target

[Service]
Restart=always
User=$appName
ExecStart=$INSTALL_DIR/$appName/alertmanager --config.file=/etc/alertmanager/alertmanager.yml --storage.path=/var/lib/alertmanager
# ExecReload=/bin/kill -HUP \$MAINPID
TimeoutStopSec=20s
SendSIGKILL=no

[Install]
WantedBy=multi-user.target
EOF
    fi


}


