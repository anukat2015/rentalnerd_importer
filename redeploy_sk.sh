git checkout master -f
git pull origin master

bundle install

rake db:migrate

ps aux | awk '/sidekiq(.*)/ { print $2 }' | xargs kill
bundle exec sidekiq -e production -C config/sidekiq.yml -P tmp/pids/sidekiq.pid  -d

# To be restart manually if and when required
# kill -s 9 PID_OF_FOREMAN PROCESS - ps aux | grep foreman
# nohup foreman start > log/sidekiq.log 2>&1 &

# To run the console from the bundle
# Command:
#   bundle console