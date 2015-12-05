class CashFlowController < ActionController::Base
  before_filter :sanitize_page_params

  def index
  	@taxes = CashFlow.taxes(params[:price])
  	@insurance = CashFlow.insurance(params[:price])

  	@loan_amt = CashFlow.loan_amt(params[:price], params[:rent], params[:rate], 30*12)
  	@pmt = CashFlow.payment(params[:rate], @loan_amt, 30*12)
  	@PITI = @pmt + @taxes + @insurance
  	@NOI = params[:rent] - @PITI
  	@net_return = CashFlow.net_return(params[:price], @loan_amt, @NOI)

  end

  private

  def sanitize_page_params
    params[:rate] = params[:rate].to_f
    params[:price] = params[:price].to_i
    params[:rent] = params[:rent].to_i
  end
end