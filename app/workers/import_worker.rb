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
      di = DataImporter.new
      di.import_climbsf_rented

    # climbsf renting
    when "n33_f22b4acef257bfa904d548ef21050ca1eses" 
      logger.debug "Performing task db:import_climbsf_renting"
      di = DataImporter.new
      di.import_climbsf_renting
    
    # Zillow SF 
    when "n46_b5aee320718b31d44407ddde5ed62909eses" 
      logger.debug "Performing task db:import_zillow_sf"
      di = DataImporter.new
      di.import_zillow_sf      

    # Zillow Phoenix
    when "n53_70da17e3370067399d5095287282d302eses"
      logger.debug "Performing task db:import_zillow_ph"
      di = DataImporter.new
      di.import_zillow_ph

    # Zillow Alameda County
    when "n86_19de2d95d00239a0c9263ec9252b66bbeses"
      logger.debug "Performing task db:import_zillow_alameda_county"
      di = DataImporter.new
      di.import_zillow_alameda_county
    end    

  end  

end
