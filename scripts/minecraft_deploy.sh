#!/bin/bash
set -e

# Variables from Terraform
MC_ROOT="${mc_root_dir}"
MC_BUCKET="${backup_bucket_name}"
JAVA_MX="${minecraft_ram}M"
JAVA_MS="${minecraft_ram}M"
BACKUP_FREQ="${backup_frequency}"  # in minutes
MC_VERSION="latest"
MINECRAFT_JAR="server.jar"

# Install dependencies
rpm -ivh https://corretto.aws/downloads/latest/amazon-corretto-21-aarch64-linux-jdk.rpm || true

yum install -y amazon-cloudwatch-agent jq

# Configure CloudWatch Logs agent
cat > /opt/aws/amazon-cloudwatch-agent/etc/config.json <<CWCONFIG
{
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/cloud-init-output.log",
            "log_group_name": "/minecraft/cloud-init",
            "log_stream_name": "{instance_id}"
          },
          {
            "file_path": "${mc_root_dir}/logs/latest.log",
            "log_group_name": "/minecraft/server",
            "log_stream_name": "{instance_id}",
            "timezone": "UTC"
          }
        ]
      }
    }
  }
}
CWCONFIG

# Start CloudWatch agent
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config \
  -m ec2 \
  -s \
  -c file:/opt/aws/amazon-cloudwatch-agent/etc/config.json


# Create minecraft user
adduser minecraft

# Sync from S3 first
mkdir -p $MC_ROOT
aws s3 sync s3://$MC_BUCKET/ $MC_ROOT/

# Pre-populate server.properties if it doesn't exist
if [[ ! -f "$MC_ROOT/server.properties" ]]; then
    cat > $MC_ROOT/server.properties <<PROPS
${server_properties}
PROPS
fi

# Pre-populate ops.json if it doesn't exist
if [[ ! -f "$MC_ROOT/ops.json" ]]; then
    cat > $MC_ROOT/ops.json <<OPS
${ops_json}
OPS
fi

# Download server if not in S3
if [[ ! -e "$MC_ROOT/$MINECRAFT_JAR" ]]; then
    wget -O $MC_ROOT/version_manifest.json https://launchermeta.mojang.com/mc/game/version_manifest.json
    MC_VERS=$(jq -r '.["latest"]["release"]' $MC_ROOT/version_manifest.json)
    VERSIONS_URL=$(jq -r '.["versions"][] | select(.id == "'$MC_VERS'") | .url' $MC_ROOT/version_manifest.json)
    SERVER_URL=$(curl -s $VERSIONS_URL | jq -r '.downloads.server.url')
    wget -O $MC_ROOT/$MINECRAFT_JAR $SERVER_URL
fi

# Accept EULA
cat > $MC_ROOT/eula.txt <<EULA
eula=true
EULA

# Create systemd service
cat > /etc/systemd/system/minecraft.service <<SYSTEMD
[Unit]
Description=Minecraft Server
After=network.target

[Service]
Type=simple
User=minecraft
WorkingDirectory=$MC_ROOT
ExecStart=/usr/bin/java -Xmx$JAVA_MX -Xms$JAVA_MS -jar $MINECRAFT_JAR nogui
Restart=on-abort

[Install]
WantedBy=multi-user.target
SYSTEMD

# S3 sync cron job
cat > /etc/cron.d/minecraft <<CRON
SHELL=/bin/bash
*/$BACKUP_FREQ * * * * minecraft /usr/bin/aws s3 sync $MC_ROOT/ s3://$MC_BUCKET/ --exclude "*.log" && echo "say [Server] World backup completed at $(date '+\%Y-\%m-\%d \%H:\%M:\%S UTC')" > /run/minecraft.stdin
CRON

# Set ownership
chown -R minecraft:minecraft $MC_ROOT

# Install monitor script
wget -O /tmp/deployment.sh https://raw.githubusercontent.com/aws-samples/cost-optimize-minecraft-server-on-ec2/refs/heads/main/deployment.sh
bash /tmp/deployment.sh

# Start service
systemctl daemon-reload
systemctl enable minecraft
systemctl start minecraft
