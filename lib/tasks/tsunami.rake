namespace :db do
  desc "removes all property related records and do a fresh start"  
  task :tsunami => :environment do 
    ActiveRecord::Base.connection.execute "TRUNCATE import_diffs"
    ActiveRecord::Base.connection.execute "TRUNCATE import_logs"
    ActiveRecord::Base.connection.execute "TRUNCATE import_jobs"
    ActiveRecord::Base.connection.execute "TRUNCATE prediction_results"
    ActiveRecord::Base.connection.execute "TRUNCATE properties"
    ActiveRecord::Base.connection.execute "TRUNCATE property_neighborhoods"
    ActiveRecord::Base.connection.execute "TRUNCATE property_transaction_logs"
    ActiveRecord::Base.connection.execute "TRUNCATE property_transactions"
  end
end