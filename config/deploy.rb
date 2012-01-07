$:.unshift(File.expand_path('./lib', ENV['rvm_path']))
require 'rvm/capistrano'
require 'capistrano/ext/multistage'
#require "bundler/capistrano"

set :default_stage, 'staging'

# Campfire
require 'capistrano/campfire'

set :campfire_options, :account => 'supportbee',
                       :room => 'SupportBee',
                       :token => '3b6227280f2699d4a85144e131bfe73ee85581ba',
                       :ssl => true

set :application, "followgems"

set :deploy_to, "/home/rails/apps/#{application}"

# Server is defined in stage specific file
set :user, 'rails'    

set :scm, "git"
set :ssh_options, { :forward_agent => true }

set :rvm_ruby_string, '1.9.2-p180' # Defaults to 'default'

#set :scm_user,  Proc.new { Capistrano::CLI.ui.ask("SVN username: ")}
#set :scm_password, Proc.new { Capistrano::CLI.password_prompt("SVN password for #{scm_user}: ")} 
#set :repository, Proc.new { "--username #{scm_user} --password #{scm_password} #{repository_url}" } 
set :deploy_via, :remote_cache

set :use_sudo,  false

# Hooks to do specific stuff
after "deploy:update_code", "supportbee_site:config", 
                            "bundler:bundle_new_release",
                            "supportbee_site:symlink", 
                            "supportbee_site:brew_js",
                            "supportbee_site:migrate_and_seed"

after "deploy", "deploy:cleanup", 
                "campfire:after_deployment"

#after "deploy:restart", "supportbee_site:restart_bluepill"

before "deploy", "campfire:start_deployment"

namespace(:deploy) do
  task :restart, :role => :app do
    run <<-CMD
      cd #{release_path} && touch tmp/restart.txt
    CMD
  end
end

namespace(:campfire) do
  task :start_deployment do
    campfire_room.speak "[Deployment] #{ENV['USER']} is preparing to deploy #{application} to #{stage}" 
  end

  task :after_deployment do 
    campfire_room.speak "[Deployment] #{ENV['USER']} finished deploying #{application} to #{stage}" 
  end
end
    
namespace(:supportbee_site) do

  task :restart_bluepill, :role => :app do
    run <<-CMD
      cd #{release_path} && bluepill restart --no-privileged
    CMD
  end
  
  task :migrate_and_seed, :role => :db do
    run <<-CMD
      cd #{release_path} && bundle exec rake db:migrate RAILS_ENV=#{stage} --trace
    CMD
    run <<-CMD
      cd #{release_path} && bundle exec rake db:seed RAILS_ENV=#{stage} --trace
    CMD
  end

  task :brew_js, :role => :app do
    run <<-CMD
      cd #{release_path} && bundle exec rake barista:brew RAILS_ENV=#{stage} --trace
    CMD
  end

  task :config,  :roles => :app do
    %w(database.yml).each do |file|
      run <<-CMD
        ln -nfs #{shared_path}/system/#{file} #{release_path}/config/#{file}
      CMD
    end
  end

  task :symlink, :roles => :app do
    # Symlink sphinx index
    #run <<-CMD
      #ln -nfs #{shared_path}/assets/uploads #{release_path}/uploads
    #CMD

    run <<-CMD
      rm #{release_path}/public/system
    CMD
  end
end

namespace :bundler do
  task :create_symlink, :roles => :app do
    shared_dir = File.join(shared_path, 'bundle')
    release_dir = File.join(current_release, 'vendor', 'bundle')
    run("mkdir -p #{shared_dir} && ln -s #{shared_dir} #{release_dir}")
  end
  
  task :bundle_new_release, :roles => :app do
    bundler.create_symlink
    run "cd #{release_path} && bundle install --without test:development --deployment"
  end
  
  task :lock, :roles => :app do
    run "cd #{current_release} && bundle lock;"
  end
  
  task :unlock, :roles => :app do
    run "cd #{current_release} && bundle unlock;"
  end
end


require './config/boot'
