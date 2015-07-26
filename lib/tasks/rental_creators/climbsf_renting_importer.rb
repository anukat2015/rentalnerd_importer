require './lib/tasks/rental_creators/rental_creator'

class ClimbsfRentingImporter
  include RentalCreator  

  DEFAULT_TRANSACTION_TYPE = "rental"

  def is_changed? old_log, new_log

    if old_log[:price] != new_log[:price]
      puts "\trecord change detected\n"
      puts "\n"
      ap old_log
      ap new_log
      return true
    else
      return false
    end
  end
  
  # The default date_listed value to be used to create a property transaction record if it does not exist
  def get_default_date_listed
    Date.today
  end

end
