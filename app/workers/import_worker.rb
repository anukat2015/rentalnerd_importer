require 'rake'

class ImportWorker
  include Sidekiq::Worker

  sidekiq_options queue: :high

  def perform( repository_handle )
    RentalNerd::Application.load_tasks
    logger.debug "Performing importing with respository handle : #{repository_handle}"
    case repository_handle
    # climbsf rented
    when "n34_d7704e8247e565c7d2bd6705148bd338eses" 
      logger.debug "Performing task db:import_climbsf_rented"
      Rake::Task['db:import_climbsf_rented'].invoke

    # climbsf renting
    when "n33_f22b4acef257bfa904d548ef21050ca1eses" 
      logger.debug "Performing task db:import_climbsf_renting"
      Rake::Task['db:import_climbsf_renting'].invoke
    
    # Zillow SF 
    when "n46_b5aee320718b31d44407ddde5ed62909eses" 
      logger.debug "Performing task db:import_zillow_sf"
      Rake::Task['db:import_zillow_sf'].invoke
    end

  end  

end
