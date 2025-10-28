#!/usr/bin/env ruby

require 'json'
require 'yaml'

# Ensure stdin containing Terraform state is treated as UTF-8, which addresses
# issues with the json gem when the US-ASCII is set as the environment language
# See https://github.com/ruby/json/issues/697#issuecomment-2807524053
$stdin.set_encoding("UTF-8")

outputs = JSON.load($stdin)

terraform_outputs = { 'terraform_outputs' => {} }
outputs['outputs'].each {|k, v|
  terraform_outputs['terraform_outputs'][k] = v.fetch("value")
}

puts YAML.dump(terraform_outputs)
