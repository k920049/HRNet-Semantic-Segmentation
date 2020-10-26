sudo yum install -y jq

VOLUME_ID=$(aws ec2 create-volume \
    --size 100 \
    --region ap-northeast-2 \
    --availability-zone ap-northeast-2c \
    --volume-type gp2 \
    --tag-specifications 'ResourceType=volume,Tags=[{Key=Name,Value=DL-datasets-checkpoints}]' | jq -r ".VolumeId")
INSTANCE_ID=$(curl http://169.254.169.254/latest/meta-data/instance-id)

sleep 10

aws ec2 attach-volume \
    --volume-id ${VOLUME_ID} \
    --instance-id ${INSTANCE_ID} \
    --device /dev/sdf

sleep 10

sudo mkdir /dltraining
sudo mkfs -t xfs /dev/xvdf
sudo mount /dev/xvdf /dltraining
sudo chown -R ec2-user: /dltraining/
cd /dltraining
sudo mkdir datasets
sudo mkdir checkpoints