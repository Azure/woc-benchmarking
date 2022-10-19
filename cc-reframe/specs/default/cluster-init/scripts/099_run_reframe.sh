#!/bin/bash

REFRAME_DIR=/shared/azure_nhc/reframe
SCRATCH_DIR=/shared/azure_nhc/scratch
mkdir -p $SCRATCH_DIR

# Determine the OS version
version=`/bin/bash ${REFRAME_DIR}/azure_nhc/utils/common.sh`
export PATH=/opt/cycle/jetpack/bin:$PATH

reframe_cfg="azure_ex.py"
if [ "$version" == "almalinux-8" ]
then
    reframe_cfg="azure_almalinux_8.py"
elif [ "$version" == "centos-7" ]
then
    export PATH=/opt/rh/rh-python38/root/usr/bin:$PATH
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
    mkdir -p ${SCRATCH_DIR}/reports
    ./bin/reframe -C azure_nhc/config/${reframe_cfg} --force-local --report-file ${SCRATCH_DIR}/reports/${HOSTNAME}-cc-startup.json -c azure_nhc/run_level_2 -R -s ${SCRATCH_DIR}/stage/${HOSTNAME} -o ${SCRATCH_DIR}/output/${HOSTNAME} -r --performance-report

}

function check_reframe {
    echo "Hello check_reframe"
    # Get VM ID
    vmId=$(curl -H Metadata:true "http://169.254.169.254/metadata/instance?api-version=2019-06-04" | jq '.compute.vmId')

    # Get Reframe error
    status=$(python3 ${REFRAME_DIR}/azure_nhc/utils/check_reframe_report.py -f ${SCRATCH_DIR}/reports/${HOSTNAME}-cc-startup.json)

    # Add the VM ID and error to the jetpack log
    jetpack log "$HOSTNAME:$vmId:$status"

    # Keep the VM up
    jetpack keepalive forever

    # If possible, trigger IcM ticket and get it out of rotation
}

trap check_reframe ERR

run_reframe
