class WebhookController < ApplicationController
  def ping
    data_source = {
      "krake_name"    => params[:name],
      "krake_handle"  => params[:handle],
      "event_name"    => params[:event_name],
      "batch_time"    => params[:batch_time]
    }
    ImportWorker.perform_async data_source["krake_handle"]
  end
end