#!/usr/bin/env ruby

require 'json'
require 'yaml'

outputs = JSON.load($stdin)

terraform_outputs = { 'terraform_outputs' => {} }
outputs['outputs'].each {|k, v|
  terraform_outputs['terraform_outputs'][k] = v.fetch("value")
}

puts YAML.dump(terraform_outputs)
