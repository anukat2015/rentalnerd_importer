# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

# Version 1:
# Rake::Task["db:reseed_standards"].execute
# Rake::Task["db:reseed_curriculum_maps"].execute
# Rake::Task["db:reseed_questions"].execute
# Rake::Task["db:reseed_question_standards"].execute
# Rake::Task["db:reseed_users_schools_districts"].execute

# Version 2:


# Miscellaneous
Rake::Task["db:import_neighborhoods_sf"].execute
Rake::Task["db:import_neighborhoods_ph"].execute

Rake::Task["db:import_prediction_model_sf"].execute
Rake::Task["db:import_prediction_model_ph"].execute

Rake::Task["db:import_luxurious_addresses"].execute

Rails.cache.clear