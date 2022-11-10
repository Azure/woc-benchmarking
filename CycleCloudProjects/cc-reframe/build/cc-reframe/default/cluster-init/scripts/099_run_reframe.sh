#!/bin/bash
  
set -x

function run_reframe {
    echo "Hello run_reframe()"
    # Setup environment
    cd /usr/local/reframe
    . share/completions/reframe.bash
    
    # Run reframe tests
    . /etc/profile.d/modules.sh
    ./bin/reframe -C azure_nhc/config/azure_ex.py -c azure_nhc/network/ib/ib_count.py -s /mnt/resource/reframe/stage -o /mnt/resource/reframe/output -r --performance-report

}

function check_reframe {
    echo "Hello check_reframe"
    # Get VM ID
    vmId=$(curl -H Metadata:true "http://169.254.169.254/metadata/instance?api-version=2019-06-04" | jq '.compute.vmId')

    # Get Reframe error

    # Add the VM ID and error to the jetpack log

    # If possible, trigger IcM ticket and get it out of rotation
}

trap check_reframe ERR

run_reframe
