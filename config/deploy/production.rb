# Production cap file

server "followgems.com", :app, :web, :db, :primary => true
set :repository,  "git@github.com:prateekdayal/FollowGems.git"
set :branch, "master"
