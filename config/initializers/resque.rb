resque_config = YAML.load(ERB.new(IO.read(Rails.root.join('config','resque.yml'))).result)

Resque.redis = resque_config[Rails.env]

Resque.inline = Rails.env.development?
