require './lib/tasks/rental_creators/rental_creator'

class ClimbsfRentedImporter
  include RentalCreator  

  DEFAULT_TRANSACTION_TYPE = "rental"

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

  def create_transaction rental_diff
    property = get_matching_property rental_diff[:origin_url]
    transaction = RentalTransaction.guess property[:id], rental_diff[:date_rented], rental_diff[:date_listed], DEFAULT_TRANSACTION_TYPE

    # This transaction was never priorly captured
    if transaction.nil?
      
      days_on_market = nil
      if !rental_diff[:date_rented].nil?
        days_on_market = (
          rental_diff[:date_rented] - rental_diff[:date_listed] 
        ).to_i / 1.day
      end

      is_latest = RentalTransaction.is_latest_transaction property[:id], rental_diff[:date_rented], rental_diff[:date_listed], "rental"
      RentalTransaction.create!(
        property_id: property[:id],
        price: rental_diff[:price],
        transaction_status: "closed",
        date_listed: rental_diff[:date_listed],
        date_rented: rental_diff[:date_rented],
        days_on_market: days_on_market,
        is_latest: is_latest,
        transaction_type: DEFAULT_TRANSACTION_TYPE
      )  

    # This transaction was priorly captured
    else
      transaction.transaction_status = "closed"
      transaction.date_rented = rental_diff[:date_rented]
      if !rental_diff[:date_rented].nil?
        transaction.days_on_market = (
          rental_diff[:date_rented] - rental_diff[:date_listed] 
        ).to_i / 1.day
      end
      transaction.save!
    end
  end  

end