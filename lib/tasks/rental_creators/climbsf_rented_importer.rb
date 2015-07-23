require './lib/tasks/rental_creators/rental_creator'

class ClimbsfRentedImporter
  include RentalCreator  

  def get_matching_record_from_batch rental_log, job_id
    RentalLog.where( 
      origin_url: rental_log[:origin_url], 
      rental_import_job_id: job_id,
      source: rental_log[:source]
    ).first      
  end

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
  
  def get_matching_transaction rental_diff
    property = get_matching_property rental_diff
    query = RentalTransaction.where( property_id: property[:id] )

    unless rental_diff[:date_rented].nil?
      query = query.where(date_rented: rental_diff[:date_rented] )
    end

    unless rental_diff[:date_listed].nil?
      query = query.where(date_listed: rental_diff[:date_listed] )
    end

    query.first
  end

  def create_transaction rental_diff
    transaction = get_matching_transaction rental_diff

    # This transaction was never priorly captured
    if transaction.nil?
      property = get_matching_property rental_diff

      days_on_market = -1
      if !rental_diff[:date_rented].nil? && rental_diff[:date_rented]  == 0
        days_on_market = (
          rental_diff[:date_listed] / rental_diff[:date_rented] 
        ).to_i / 1.day
      end

      RentalTransaction.create!(
        property_id: property[:id],
        price: rental_diff[:price],
        transaction_status: "closed",
        date_listed: rental_diff[:date_listed],
        date_rented: rental_diff[:date_rented],
        days_on_market: days_on_market,
        is_latest: is_latest_transaction(rental_diff)
      )  

    # This transaction was priorly captured
    else
      transaction.transaction_status = "closed"
      transaction.date_rented = rental_diff[:date_rented]
      if !rental_diff[:date_rented].nil? && rental_diff[:date_rented]  == 0
        transaction.days_on_market = (
          transaction[:date_listed] / rental_diff[:date_rented] 
        ).to_i / 1.day
      end
      transaction.save!
    end
  end  

end