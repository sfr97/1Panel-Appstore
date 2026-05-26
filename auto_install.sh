#!/bin/bash

echo "$(date): [Init] Check..."

if ! command -v crontab &> /dev/null; then
    echo "crontab could not be found, please install it first."
    exit 1
fi

if command -v wget &> /dev/null; then
    downloader="wget -O"
elif command -v curl &> /dev/null; then
    downloader="curl -o"
else
    echo "Neither wget nor curl is installed. Please install one of them first."
    exit 1
fi

if [[ -w /home/task ]]; then
    task_dir="/home/task"
elif [[ ! -d /home/task ]]; then
    mkdir -p /home/task
    if [[ $? -ne 0 || ! -w /home/task ]]; then
        echo "No permission to write to /home/task."
    else
        task_dir="/home/task"
    fi
elif [[ -w /etc/task ]]; then
    task_dir="/etc/task"
elif [[ ! -d /etc/task ]]; then
    mkdir -p /etc/task
    if [[ $? -ne 0 || ! -w /etc/task ]]; then
        echo "No permission to write to /etc/task."
    else
        task_dir="/etc/task"
    fi
else
    echo "No permission to write to /home/task or /etc/task. Please run as a superuser."
    exit 1
fi

echo "$(date): [Init] Download the installation script..."

urls=(
    'https://raw.gitcode.com/fr97/1Panel-Appstore/raw/main/app_install.sh.sh'
    'https://raw.githubusercontent.com/sfr97/1Panel-Appstore/refs/heads/main/app_install.sh.sh'
)

download_successful=false

for url in "${urls[@]}"; do
    $downloader "$task_dir/app_install.sh" "$url"
    if [[ $? -eq 0 ]]; then
        download_successful=true
        break
    fi
done

echo "$(date): [Next] Deploy installation scripts..."

if [[ "$download_successful" = true && -f "$task_dir/app_install.sh" ]]; then
    if [[ -w "$task_dir/app_install.sh" ]]; then
        chmod +x "$task_dir/app_install.sh"

        crontab -l | grep -v "$task_dir/app_install.sh" | crontab -
        crontab -l | grep -v "$task_dir/app_install_zh.sh" | crontab -

        (crontab -l ; echo "0 */3 * * * /bin/bash $task_dir/app_install.sh") | crontab -

        echo "$(date): [Run] Update application list"

        /bin/bash "$task_dir/app_install.sh"
    else
        echo "No permission to change the script's permissions."
    fi
else
    echo "Script download failed. Please check your network connection."
fi

echo "$(date): [Auto] Installation completed."
