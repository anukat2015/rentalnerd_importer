class WebhookController < ApplicationController

  skip_before_filter :verify_authenticity_token, :only => [:ping]

  def ping
    data_source = {
      "krake_name"    => params[:krake_name],
      "krake_handle"  => params[:krake_handle],
      "event_name"    => params[:event_name],
      "batch_time"    => params[:batch_time]
    }
    ImportWorker.perform_async data_source["krake_handle"]
    render :json => {
      status: "success"
    }
  end
end