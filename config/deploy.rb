set :rvm_ruby_string, '1.8.7-p358@bibapp'
$:.unshift(File.expand_path('./lib', ENV['rvm_path'])) # Add RVM's lib directory to the load path.
require "rvm/capistrano"
require 'bundler/capistrano'

set :rvm_type, :user  # Copy the exact line. I really mean :user here

default_run_options[:pty] = true

set :application, "Bibapp"
set :rails_env, ENV['RAILS_ENV'] || 'production'


#To deploy from the GitHub project
set :scm, :git
set :repository, "git@github.com:metrik/BibApp.git"
#To deploy a particular branch or tag:
#set :branch, "branch_or_tag_name"

#directories on the server to deploy the application
#the running instance gets links to [deploy_to]/current

set :deploy_via, :remote_cache
set :deploy_to, "/home/bibapp/public_html/bibapp"
set :current, "#{deploy_to}/current"
set :shared, "#{deploy_to}/shared"
set :shared_config, "#{shared}/config"
set :public, "#{current}/public"
set :branch, "master"

set :user, 'bibapp'
set :use_sudo, false

# Your HTTP server, Apache/etc
role :web, "conicyt-bibapp"
# This may be the same as your `Web` server
role :app, "conicyt-bibapp"
# This is where Rails migrations will run
role :db,  "conicyt-bibapp", :primary => true
#your slave db-server here
#role :db,  "your slave db-server here"

namespace :deploy do
  task :start do ; end
  task :stop do ; end
  task :restart, :roles => :app, :except => { :no_release => true } do
    run "touch #{current}/tmp/restart.txt"
  end
  
  desc "Setup a GitHub-style deployment."
  task :setup, :except => { :no_release => true } do
    run "git clone #{repository} #{current}"
  end
  
#  desc "Update the deployed code."
#  task :update_code, :except => { :no_release => true } do
    #run "cd #{current_path}; git pull origin #{branch}"
#    run "cd #{current_path}; git fetch origin; git reset --hard master"
#  end
  
#  task :create_symlink , :except => { :no_release => true } do
#  end
  

  desc "create a config directory under shared"
  task :create_shared_dirs do
    run "mkdir #{shared}/config"
    [:attachments, :groups, :people].each do | dir|
      run "mkdir #{shared}/system/#{dir}"
    end
  end

  desc "link shared configuration"
  task :link_config do
    ['database.yml', 'ldap.yml', 'personalize.rb', 'smtp.yml', 
     'solr.yml', 'sword.yml', 'thin.yml'].each do |file|
      run "ln -nfs #{shared_config}/#{file} #{current}/config/#{file}"
    end
  end

  desc "symlink shared subdirectories of public"
  task :symlink_shared_dirs do
    [:attachments, :groups, :people, :sherpa].each do |dir|
      run "ln -nfs #{public}/system/#{dir} #{public}/#{dir}"
    end
  end


  desc "Run this after update code"
  task :link_db_sqlite, :roles => :app do
    #Thin
    #invoke_command "ln -nfs #{shared_path}/config/thin.yml #{current_path}/config/thin.yml", :via => run_method
    invoke_command "ln -nfs #{shared_path}/config/bibapp_production #{current_path}/db/bibapp_production", :via => run_method
  end
end






set :thin_conf, "#{current_path}/config/thin.yml"   
task :start, :roles => :app do
 invoke_command "thin start -C #{thin_conf}" , :via => run_method        
end

task :stop, :roles => :app do
  invoke_command "thin stop -C #{thin_conf}" , :via => run_method            
end

task :restart, :roles => :app do
  invoke_command "thin restart -C #{thin_conf}" , :via => run_method
end


namespace :bibapp do
  [:stop, :start, :restart].each do |action|
    desc "#{action} Bibapp services" 
    task action do
      begin
        run "cd #{current}; RAILS_ENV=#{rails_env} rake bibapp:#{action}"
      rescue
        puts "Current directory doesn't exist yet"
      end
    end
  end
end

#The sleep is to make sure that solr has enough time to start up before
#running this.
namespace :solr do
  desc "Reindex solr"
  task :refresh_index do
    run "cd #{current}; sleep 10; RAILS_ENV=#{rails_env} rake solr:refresh_index --trace"
  end
end

namespace :bundler do


  task :bundle_new_release, :roles => [:web], :except => { :no_release => true } do
    #run "rm -rf #{current_path}/Gemfile.lock"
    run "cd #{current_path} && bundle install --without development test "
  end


end

after 'deploy:setup', 'deploy:create_shared_dirs'

after 'deploy:update', 'deploy:link_config'
after 'deploy:update', 'deploy:link_db_sqlite'
after 'deploy:update', 'deploy:symlink_shared_dirs'
after 'deploy:update', 'bundler:bundle_new_release'

#before 'deploy:update', 'bibapp:stop'

#after 'deploy:start', 'bibapp:start'
#after 'deploy:stop', 'bibapp:stop'

after 'deploy:restart', 'bibapp:restart'

after 'bibapp:start', 'solr:refresh_index'
after 'bibapp:restart', 'solr:refresh_index'
