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