#!/usr/bin/env python3
import json as js
import re
#####################################################################################
### Input File
js_input_file = "/mnt/resource/reframe/reports/cc-startup.json"
#####################################################################################

js_file = open(js_input_file)
vm_report = js.load(js_file)

num_failures = vm_report["session_info"]["num_failures"]
if num_failures > 0:
	first_failed_test = vm_report["runs"][0]["testcases"][0]["name"]
	reason_for_failure = vm_report["runs"][0]["testcases"][0]["fail_reason"]
	print("{}:{}:{}".format(num_failures,first_failed_test,reason_for_failure))
else:
	print("Success!")
