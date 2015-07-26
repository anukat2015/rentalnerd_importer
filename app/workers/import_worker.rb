require 'rake'

class ImportWorker
  include Sidekiq::Worker

  sidekiq_options queue: :high

  def perform( repository_handle )
    RentalNerd::Application.load_tasks

    case repository_handle
    # climbsf rented
    when "n19_485a52895ca152c9f9f74554627048e2eses" 
      Rake::Task['db:import_climbsf_rented'].invoke

    # climbsf renting
    when "n4_46fae6367035ff1e0e869e80d4fccc71eses" 
      Rake::Task['db:import_climbsf_renting'].invoke
    end
    
  end  

end
