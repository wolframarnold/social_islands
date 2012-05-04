worker_processes 3
timeout 30

@resque_pid = nil

before_fork do |server, worker|
  @resque_pid ||= spawn("bundle exec rake resque:work QUEUES=fb_fetcher")
end
