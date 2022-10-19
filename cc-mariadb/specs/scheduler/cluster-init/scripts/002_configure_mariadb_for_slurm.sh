#!/bin/bash

DB_HOSTNAME=${HOSTNAME}
DB_ADMIN_USERNAME=slurm
DB_USER_PASSWORD=Password1234!

#Setting up database for slurm

mysql -u ${DB_ADMIN_USERNAME} -e "create user 'slurm'@'localhost' identified by '${DB_USER_PASSWORD}'; grant all on slurm_acct_db.* TO 'slurm'@'localhost'; create database slurm_acct_db;"

#Modifying slurm.conf to be database aware
cat << EOS >> /etc/slurm/slurm.conf
# for Accounting
AccountingStorageType=accounting_storage/slurmdbd
AccountingStorageHost=${HOSTNAME}
JobAcctGatherType=jobacct_gather/linux
JobAcctGatherFrequency=30
EOS

#Setting up the slurmdbd.conf file
cat << EOS > /etc/slurm/slurmdbd.conf
ArchiveEvents=yes
ArchiveJobs=yes
ArchiveResvs=yes
ArchiveSteps=no
ArchiveSuspend=no
ArchiveTXN=no
ArchiveUsage=no
AuthInfo=/var/run/munge/munge.socket.2
AuthType=auth/munge
DbdHost=${DB_HOSTNAME}
DebugLevel=info
PurgeEventAfter=1month
PurgeJobAfter=12month
PurgeResvAfter=1month
PurgeStepAfter=1month
PurgeSuspendAfter=1month
PurgeTXNAfter=12month
PurgeUsageAfter=24month
LogFile=/var/log/slurmdbd.log
SlurmUser=slurm
StoragePass=${DB_USER_PASSWORD}
StorageType=accounting_storage/mysql
StorageUser=slurm
EOS

#Set up slurmdb.log file
touch /var/log/slurmdbd.log
chown slurm /var/log/slurmdbd.log

 # restart slurm daemon
/usr/sbin/slurmdbd 
 systemctl stop slurmctld
 systemctl start slurmctld
 sleep 10


