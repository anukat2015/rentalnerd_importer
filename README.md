Pre-requisities
===
- Ruby version 2.1.1 
- MySql version 5.5.25

Setting up
===

Navigate to the root directory of the application folder and run the following commands

  ```
  gem install rails # Rails 4.1.1
  bundle install
  rake db:create
  rake db:migrate
  ```

Setting up the environmental variables
  ```
  DATABASE_NAME=rental_nerd
  DATABASE_HOST=127.0.0.1
  DATABASE_USERNAME=root
  DATABASE_PASSWORD=
  RN_REDIS_HOST=localhost
  RN_REDIS_PORT=6379
  SLACK_RENTAL_PREDICTIONS_CHANNEL=https://hooks.slack.com/services/...
  SLACK_CAP_PREDICTIONS_CHANNEL=https://hooks.slack.com/services/...
  SLACK_ALERTS_CHANNEL=https://hooks.slack.com/services/...
  SLACK_FATAL_CHANNEL=https://hooks.slack.com/services/...
  DOCUSIGN_USERNAME=...
  DOCUSIGN_PASSWORD=...
  DOCUSIGN_INTEGRATOR_KEY=...
  DOCUSIGN_ACCOUNT_ID=...
  ```

Starting up application
===

Starting up web server
---

Navigate to the root directory of the application folder and run the following commands
  ```
  rails s
  ```

Starting up sidekiq background service
---
Navigate to the root directory of the application folder and run the following commands
  ```
  foreman start
  ```