require 'rake'

class ImportWorker
  include Sidekiq::Worker

  sidekiq_options queue: :high

  def perform( repository_handle )
    RentalNerd::Application.load_tasks

    case repository_handle
    # climbsf rented
    when "n34_d7704e8247e565c7d2bd6705148bd338eses" 
      Rake::Task['db:import_climbsf_rented'].invoke

    # climbsf renting
    when "n33_f22b4acef257bfa904d548ef21050ca1eses" 
      Rake::Task['db:import_climbsf_renting'].invoke
    end
    
  end  

end
