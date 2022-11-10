#!/usr/bin/env python3

import json
import pprint as pp
import sys

# Read in the VM data
vm_data_file = "vm_list.json"
vm_template_file = "cc-reframe-821.template"

def read_data_file(filename):
    with open(filename) as vdf:
        vm_data = json.load(vdf)

        print("VM data: {}".format(vm_data))
        return(vm_data)

# Create node arrays
def create_node_array(p_name, config, projects, ib=True):
    # Define the text for the partition
    param_text = """
    [[nodearray {}]]
    Extends = nodearraybase
    MachineType = ${}_machine_type
    ImageName = ${}_image_name
    MaxCoreCount = ${}_max_cores
    Azure.MaxScalesetSize = $MaxScalesetSize
    Interruptible = $UseLowPrio
    MaxPrice = $SpotMaxPrice
    AdditionalClusterInitSpecs = ${}_init_specs

""".format(p_name,p_name,p_name,p_name,p_name)
    print(param_text)

    if ib == True:
        config.append("slurm.hpc = true")
    
    # Format config
    cfg_str = ""
    for option in config:
        cfg_str += "        {}\n".format(option)
    
    # Format projects
    project_str = ""
    for project in projects:
        project_str += "        [[[{}]]]\n".format(project)

    param_text += """
        [[[configuration]]]
        slurm.partition = {}
{}

{}

""".format(p_name, cfg_str, project_str)

    print("{}".format(param_text))   
    return(param_text)

# Create the needed parameters
def create_max_cores_params(vm_size,max_cores=384):
    param_text = """
        [[[parameter {}_max_cores]]]
        Label = Max {} Cores
        Description = The total number of {} execute cores to start
        DefaultValue = {}
        Config.Plugin = pico.form.NumberTextBox
        Config.MinValue = 1
        Config.IntegerOnly = true:
""".format(vm_size,vm_size,vm_size,max_cores)
    print("Parameters for {}:\n{}".format(vm_size,param_text))

    return(param_text)

def create_machine_type_params(p_name,vm_size):
    param_text = """
        [[[parameter {}_machine_type]]]
        Label = {} VM Type
        Description = The VM type for {} execute nodes
        ParameterType = Cloud.MachineType
        DefaultValue = {}
""".format(p_name,p_name,p_name,vm_size)
    print("Parameters for {}:\n{}".format(p_name,param_text))

    return(param_text)

def create_image_name_params(p_name,img_name="cycle.image.centos7"):
    param_text="""
        [[[parameter {}_image_name]]]
        Label = {} OS
        ParameterType = Cloud.Image
        Config.OS = linux
        DefaultValue = {}
""".format(p_name,p_name,img_name)

    print("Parameters for {}:\n{}".format(p_name,param_text))

    return(param_text)

def create_init_specs_params(p_name,init_specs="=undefined"):
    param_text = """
        [[[parameter {}_init_specs]]]
        Label = {} Cluster-Init
        DefaultValue = {}
        Description = Cluster init specs to apply to {} execute nodes
        ParameterType = Cloud.ClusterInitSpecs
""".format(p_name,p_name,init_specs,p_name)
    print("Parameters for {}:\n{}".format(p_name,param_text))

    return(param_text)

def format_list_for_template(my_list,fmt_str):
    # Format projects
    new_str = ""
    for item in my_list:
        new_str += fmt_str.format(item)

    return(new_str)


# Update the template file
def create_cc_template(out_template,partitions,machine_types,max_cores,image_names,init_specs,db_url,db_user,db_passwd):
    with open(vm_template_file) as vtf:
        tmp_file = vtf.read()

        #search for lines to replace
        tmp_str = format_list_for_template(partitions,"    {}")
        tmp_file = tmp_file.replace("<-------Add partion information here------->", tmp_str)
        tmp_str = format_list_for_template(machine_types,"    {}")
        tmp_file = tmp_file.replace("<-------Add machine type information here------->", tmp_str)
        tmp_str = format_list_for_template(max_cores,"    {}")
        tmp_file = tmp_file.replace("<-------Add max core information here------->", tmp_str)
        tmp_str = format_list_for_template(image_names,"    {}")
        tmp_file = tmp_file.replace("<-------Add image name information here------->", tmp_str)
        tmp_str = format_list_for_template(init_specs,"    {}")
        tmp_file = tmp_file.replace("<-------Add init specs information here------->", tmp_str)
        tmp_file = tmp_file.replace("<-------DB URL------->", db_url)
        tmp_file = tmp_file.replace("<-------DB user------->", db_user)
        tmp_file = tmp_file.replace("<-------DB password------->", db_passwd)

        # Write out new template file
        with open(out_template,"w") as otf:
            otf.write(tmp_file) 


def main():
    vm_data = read_data_file(vm_data_file)
    new_partitions = []
    new_image_names = []
    new_max_cores = []
    new_init_specs = []
    new_machine_types = []
   
    for partition in vm_data["partitions"]:
        projects = []
        
        # Gather any configs to be added to the partion
        configs = []
        if "cycle_config" in vm_data:
            configs += vm_data["cycle_config"]
        if "cycle_config" in vm_data["partitions"][partition]:
            configs += vm_data["partitions"][partition]["cycle_config"]

        # Gather any projects to be added to the partion
        projects = []
        if "default_cycle_projects" in vm_data:
            projects += vm_data["default_cycle_projects"]
        if "projects" in vm_data["partitions"][partition]:
            projects += vm_data["partitions"][partition]["projects"]

        # Check to see if they have set the ib value in the file
        ib = True
        if "ib" in vm_data["partitions"][partition]:
            ib = vm_data["partitions"][partition]["ib"]
        
        # configure node array
        new_partitions.append(create_node_array(partition, configs, projects, ib))

        #
        # Setup max cores parameters
        #

        # Check to see if max cores is set or we can calculate it
        max_cores = 120
        if "max_cores" in vm_data and "cores_per_vm" not in vm_data["partitions"][partition]:
            max_cores = vm_data["max_cores"]
        elif "cores_per_vm" in vm_data["partitions"][partition] and "number_of_vms" in vm_data["partitions"][partition]:
            max_cores = int(vm_data["partitions"][partition]["cores_per_vm"]) * int(vm_data["partitions"][partition]["number_of_vms"])
        else:
            print('Not able to find "cores_per_vm" and "number_of_vms" for partition {}'.format(partition))
            max_cores = 120

        new_max_cores.append(create_max_cores_params(partition,max_cores))


        # Find the right image name for this partition
        img_name = ""
        if "vm_image_name" in vm_data and "vm_image_name" not in vm_data["partitions"][partition]:
            img_name = vm_data["vm_image_name"]
        elif "vm_image_name" in vm_data["partitions"][partition]:
            img_name = vm_data["partitions"][partition]["vm_image_name"]
        else:
            print('Not able to find "vm_image_name" for partition {} or a default one'.format(partition))
            print('Exiting'.format(partition))
            sys.exit(-1)

        new_image_names.append(create_image_name_params(partition,img_name))

        # Find the right init specs for this partition
        init_specs = ""
        if "init_specs" in vm_data and "init_specs" not in vm_data["partitions"][partition]:
            init_specs = vm_data["init_specs"]
        elif "init_specs" in vm_data["partitions"][partition]:
            init_specs = vm_data["partitions"][partition]["init_specs"]
        else:
            print('Not able to find "init_specs" for partition {} or a default one'.format(partition))
            init_specs = "=undefined"

        new_init_specs.append(create_init_specs_params(partition,init_specs))

        # Find the right machine type for this partition
        machine_type = ""
        if "name" in vm_data["partitions"][partition]:
            machine_type = vm_data["partitions"][partition]["name"]
        else:
            print('Not able to find a machine type ("name") for partition {}'.format(partition))
            print('Exiting'.format(partition))
            sys.exit(-1)

        new_machine_types.append(create_machine_type_params(partition,machine_type))

    print("Machine Types: {}".format(new_machine_types))
    print("Max Cores: {}".format(new_max_cores))
    print("Image Names: {}".format(new_image_names))
    print("Init Specs: {}".format(new_init_specs))

    # Write out updated template file
    # Get DB information
    db_url = db_user = db_passwd = ""
    if "db_url" in vm_data:
        db_url = vm_data["db_url"]
    if "db_user" in vm_data:
        db_user = vm_data["db_user"]
    if "db_password" in vm_data:
        db_passwd = vm_data["db_password"]
    create_cc_template("cc-reframe-mod-821.txt",new_partitions,new_machine_types,new_max_cores,new_image_names,new_init_specs,db_url,db_user,db_passwd)

if __name__ == "__main__":
    main()
