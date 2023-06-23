#!/bin/bash  
  
NVME_DISKS_NAME=`ls /dev/nvme*n1`
NVME_DISKS=`ls -latr /dev/nvme*n1 | wc -l`

echo "Number of NVMe Disks: $NVME_DISKS"

if [ "$NVME_DISKS" == "0" ]
then
    exit 0
else
    MNT_POINT=/mnt/resource_nvme
    mkdir -p $MNT_POINT
    
    # Create raid disk
    mdadm --create /dev/md128 -f --run --level 0 --raid-devices $NVME_DISKS $NVME_DISKS_NAME

    # Setup the disk
    mkfs.xfs -f /dev/md128

    # Mount the disk
    blkid
    string=`blkid | grep md128`
    arrIN=(${string// / })
    name_str=${arrIN[1]}
    arrIN2=(${name_str//=/ })
    DISK_NAME=${arrIN2[1]}

    echo  "UUID=${DISK_NAME} $MNT_POINT xfs defaults 0 0" >> /etc/fstab
    systemctl daemon-reload
    systemctl reset-failed
fi

chmod 1777 $MNT_POINT
mount /mnt/resource_nvme
