git checkout master -f
git pull origin master

bundle install

rake db:migrate

RAILS_ENV=production bundle exec rake assets:precompile

ps aux | awk '/rails s.*-p 3002/ { print $2 }' | xargs kill
nohup bundle exec rails s -e production -p 3002 > log/production.log 2>&1 &

# To be restart manually if and when required
# kill -s 9 PID_OF_FOREMAN PROCESS - ps aux | grep foreman
# nohup foreman start > log/sidekiq.log 2>&1 &

# To run the console from the bundle
# Command:
#   bundle console