#!/bin/bash
# Get instance ID, Instance AZ, Volume ID and Volume AZ
INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
INSTANCE_AZ=$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone)
AWS_REGION=ap-northeast-2


VOLUME_ID=$(aws ec2 describe-volumes --region $AWS_REGION --filter Name=tag:Name,Values=DL-datasets-checkpoints Name=status,Values=available --query "Volumes[].VolumeId" --output text)
VOLUME_AZ=$(aws ec2 describe-volumes --region $AWS_REGION --filter Name=tag:Name,Values=DL-datasets-checkpoints Name=status,Values=available  --query "Volumes[].AvailabilityZone" --output text)

# Proceed if Volume Id is not null or unset
if [ $VOLUME_ID ]; then
		# Check if the Volume AZ and the instance AZ are same or different.
		# If they are different, create a snapshot and then create a new volume in the instance's AZ.
		echo "Found volume $VOLUME_ID"
		if [ $VOLUME_AZ != $INSTANCE_AZ ]; then
		    echo "Migrating volume to $INSTANCE_AZ"
				SNAPSHOT_ID=$(aws ec2 create-snapshot \
						--region $AWS_REGION \
						--volume-id $VOLUME_ID \
						--description "`date +"%D %T"`" \
						--tag-specifications 'ResourceType=snapshot,Tags=[{Key=Name,Value=DL-datasets-checkpoints-snapshot}]' \
						--query SnapshotId --output text)

				aws ec2 wait --region $AWS_REGION snapshot-completed --snapshot-ids $SNAPSHOT_ID
				aws ec2 --region $AWS_REGION  delete-volume --volume-id $VOLUME_ID

				VOLUME_ID=$(aws ec2 create-volume \
						--region $AWS_REGION \
								--availability-zone $INSTANCE_AZ \
								--snapshot-id $SNAPSHOT_ID \
						--volume-type gp2 \
						--tag-specifications 'ResourceType=volume,Tags=[{Key=Name,Value=DL-datasets-checkpoints}]' \
						--query VolumeId --output text)
				aws ec2 wait volume-available --region $AWS_REGION --volume-id $VOLUME_ID
		fi
		# Attach volume to instance
		aws ec2 attach-volume --region ${AWS_REGION} --volume-id ${VOLUME_ID} --instance-id ${INSTANCE_ID} --device /dev/sdf
		sleep 10

		# Mount volume and change ownership, since this script is run as root
		mkdir /dltraining
		mount /dev/xvdf /dltraining
		chown -R ec2-user: /dltraining/
		cd /home/ec2-user/

    # Get training code
    # git clone https://github.com/jeasung-pf/pytorch-deeplab-xception.git
    # chown -R ec2-user: /home/ec2-user/pytorch-deeplab-xception
    # cd /home/ec2-user/pytorch-deeplab-xception/segmentation
    # chmod +x /home/ec2-user/pytorch-deeplab-xception/segmentation/train_voc.sh

		# Initiate training using the tensorflow_36 conda environment
		# sudo -H -u ec2-user bash -c "source /home/ec2-user/anaconda3/bin/activate pytorch_p36; pip install pycocotools tensorboardX tqdm numpy==1.16.0 requests; ./train_voc.sh"
else
    echo "No such volume as $VOLUME_ID"
fi

# After training, clean up by cancelling spot requests and terminating itself
# SPOT_FLEET_REQUEST_ID=$(aws ec2 describe-spot-instance-requests --region $AWS_REGION --filter "Name=instance-id,Values='$INSTANCE_ID'" --query "SpotInstanceRequests[].Tags[?Key=='aws:ec2spot:fleet-request-id'].Value[]" --output text)
# aws ec2 cancel-spot-fleet-requests --region $AWS_REGION --spot-fleet-request-ids $SPOT_FLEET_REQUEST_ID --terminate-instances
