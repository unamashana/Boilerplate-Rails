# Production cap file

server "reminderhawk.com", :app, :web, :db, :primary => true
set :repository,  "git@github.com:prateekdayal/SupportBee-Rails.git"
