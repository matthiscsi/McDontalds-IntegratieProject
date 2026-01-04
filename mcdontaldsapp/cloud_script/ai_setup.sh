#!/bin/bash

set -e
PROJECT_ID="inbound-decker-475607-d6" 
INSTANCE_NAME="ollama-vm"
ZONE="europe-west1-b"  
MACHINE_TYPE="n2-highmem-8"  
BOOT_DISK_SIZE="100GB"  
IMAGE_FAMILY="ubuntu-2204-lts"
IMAGE_PROJECT="ubuntu-os-cloud"

echo "Creating VM in België with Ollama..."
gcloud config set project $PROJECT_ID

gcloud compute firewall-rules create allow-ollama \
    --allow tcp:11434 \
    --source-ranges 0.0.0.0/0 \
    --quiet 2>/dev/null || true

gcloud compute instances create $INSTANCE_NAME \
    --zone=$ZONE \
    --machine-type=$MACHINE_TYPE \
    --provisioning-model=SPOT \
    --instance-termination-action=STOP \
    --boot-disk-size=$BOOT_DISK_SIZE \
    --boot-disk-type=pd-standard \
    --image-family=$IMAGE_FAMILY \
    --image-project=$IMAGE_PROJECT \
    --maintenance-policy=TERMINATE \
    --metadata=startup-script='#!/bin/bash
    apt-get update
    apt-get upgrade -y
    curl -fsSL https://ollama.com/install.sh | sh
    
    # Configure Ollama to listen on all interfaces
    mkdir -p /etc/systemd/system/ollama.service.d
    cat > /etc/systemd/system/ollama.service.d/override.conf << EOF
[Service]
Environment="OLLAMA_HOST=0.0.0.0:11434"
EOF
    
    systemctl daemon-reload
    systemctl restart ollama
    
    # Pull model (dit duurt 15-20 minuten)
    ollama pull gemma2:27b
    '

EXTERNAL_IP=$(gcloud compute instances describe $INSTANCE_NAME --zone=$ZONE --format="get(networkInterfaces[0].accessConfigs[0].natIP)")

echo ""
echo "✅ VM Created!"
echo "IP: $EXTERNAL_IP"
echo "Ollama URL: http://$EXTERNAL_IP:11434"
echo ""
echo "⏰ Wait 20 minutes for Gemma 27B download to complete."
echo "💰 SPOT instance = 70% goedkoper (~€50/maand)"