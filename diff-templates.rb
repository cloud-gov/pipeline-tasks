require 'yaml'

l1 = ARGV[0]
l2 = ARGV[1]
first = YAML.load_file(l1)
second = YAML.load_file(l2)

def compare_yaml_hash(cf1, cf2, context = [], diff = "")
  cf1.each do |key, value|

    unless cf2.key?(key)
      diff << "  MISSING - key : #{context.join(".")}.#{key}\n"
      next
    end

    value2 = cf2[key]
    if (value.class != value2.class)
      diff << "  VERIFY - Key value type mismatch : #{context.join(".")}.#{key}\n"
      next
    end

    if value.is_a?(Hash)
      compare_yaml_hash(value, value2, (context + [key]), diff)
      next
    end

    if value.is_a?(Array) && value2.is_a?(Array)
      if value.length > value2.length
        diff << "  CAUTION - Array length mismatch. Missing items? : #{context.join(".")}.#{key}\n"
        next
      end
    end

  end
  return diff
end

diff = compare_yaml_hash(first, second)
if diff.to_s.strip.length != 0
    puts "Comparing #{l2} to upstream:"
    puts diff
end

