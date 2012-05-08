worker_processes 2
timeout 30

@resque_pid = nil

before_fork do |server, worker|
  @resque_pid ||= spawn("bundle exec rake resque:work VERBOSE=1 QUEUES=fb_fetcher")
end
