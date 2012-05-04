# For Resque to book up stack, according to: https://github.com/defunkt/resque
require 'resque/tasks'
task "resque:setup" => :environment