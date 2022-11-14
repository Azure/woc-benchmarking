#!/bin/bash

sed -i 's/ConstrainCores=yes/#ConstrainCores=yes/g' /sched/cgroup.conf

systemctl restart slurmctld
