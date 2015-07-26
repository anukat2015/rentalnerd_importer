require './lib/tasks/rental_creators/rental_creator'

class ClimbsfRentedImporter
  include RentalCreator  

  DEFAULT_TRANSACTION_TYPE = PropertyTransactionLog::TRANSACTION_TYPES["rental"]

  def is_changed? old_log, new_log

    if old_log[:price] != new_log[:price] || old_log[:date_rented] != new_log[:date_rented]
      puts "\trecord change detected\n"
      puts "\n"
      ap old_log
      ap new_log
      return true
    else
      return false
    end
  end

end














