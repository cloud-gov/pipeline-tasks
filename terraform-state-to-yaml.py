#!/usr/bin/env python3

import yaml
import sys
import json


terraform_outputs_dict = {'terraform_outputs':{}}
terraform_outputs = terraform_outputs_dict['terraform_outputs']
json_file = json.load(sys.stdin)
outputs = json_file['outputs']
for key in outputs:
    terraform_outputs[key] = outputs[key]['value']
yaml.dump(terraform_outputs_dict,sys.stdout)
sys.stdin.close();
sys.stdout.close();
