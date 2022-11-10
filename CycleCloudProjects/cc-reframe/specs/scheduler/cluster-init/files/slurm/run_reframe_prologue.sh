#!/bin/bash

# Determine the OS version
REFRAME_DIR="/shared/azure_nhc/reframe"
SCRATCH_DIR="/shared/azure_nhc/scratch"
version=`/bin/bash ${REFRAME_DIR}/azure_nhc/utils/common.sh`

reframe_cfg="azure_ex.py"
if [ "$version" == "almalinux-8" ]
then
    reframe_cfg="azure_almalinux_8.py"
elif [ "$version" == "centos-7" ]
then
    export PATH=/opt/rh/rh-python38/root/usr/bin:$PATH
    ln -s /opt/rh/rh-python38/root/usr/bin/python3.8 /usr/bin/python3
    reframe_cfg="azure_centos_7.py"
elif [ "$version" == "centos-8" ]
then
    reframe_cfg="azure_centos_8.py"
elif [ "$version" == "ubuntu-20" ]
then
    reframe_cfg="azure_ubuntu_20.py"
fi  

set -x

function run_reframe {
    echo "Hello run_reframe()"
    # Setup environment
    cd ${REFRAME_DIR}
    . reframe_venv/bin/activate
    . share/completions/reframe.bash

    # Run reframe tests
    . /etc/profile.d/modules.sh
    mkdir -p ${REFRAME_DIR}/reports
    ./bin/reframe -C azure_nhc/config/${reframe_cfg} --report-file ${SCRATCH_DIR}/reports/${HOSTNAME}-cc-slurm-prologue.json -c ${REFRAME_DIR}/azure_nhc/run_level_1 -s ${SCRATCH_DIR}/stage/${HOSTNAME} -o ${SCRATCH_DIR}/output/${HOSTNAME} -R -r --performance-report --force-local
    echo "status: $?"
}

function check_reframe {
    echo "Hello check_reframe"
    # Get VM ID
    vmId=$(curl -H Metadata:true "http://169.254.169.254/metadata/instance?api-version=2019-06-04" | jq '.compute.vmId')

    # Get Reframe error
    status=$(python3 ${REFRAME_DIR}/azure_nhc/utils/check_reframe_report.py)

    # Add the VM ID and error to the jetpack log
    /opt/cycle/jetpack/bin/jetpack log "$HOSTNAME:$vmId:$status"

    # Place the node in a drained state
    #scontrol update nodename=$HOSTNAME state=DRAIN Reason="$status"

    # If possible, trigger IcM ticket and get it out of rotation
}

trap check_reframe ERR

run_reframe
