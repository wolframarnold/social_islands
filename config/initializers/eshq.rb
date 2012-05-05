eshq_config = YAML.load(ERB.new(IO.read(Rails.root.join('config','eshq.yml'))).result)[Rails.env]

eshq_config.each_pair do |key,val|
  ENV[key.upcase] = val
end

