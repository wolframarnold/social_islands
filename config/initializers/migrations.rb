if !Rails.env.test? and !(defined? Rake and Rake.application.top_level_tasks.grep(/^db:/))
  # Stop all other tasks and server calls if pending migrations
  if Mongoid::Migrator.new(:up,Mongoid::Migrator.migrations_path).pending_migrations.present?
    raise "There are pending data migrations. Please run 'rake db:migrate'"
  end
end
