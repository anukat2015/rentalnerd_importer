class CashFlow < ActiveRecord::Base
	# Calculation based on formula found at http://www.financeformulas.net/Loan_Payment_Formula.html
	#
	# Calculate a payment given:
	#
	# rate - annual percentage rate, not decimal
	# bal - loan balance
	# term - term of the loan in months
	#
	def self.payment(rate, bal, term)
	  # Convert annual rate to monthly and make it decimal.
	  r = rate / 1200
	 
	  # Numerator
	  n = r * bal
	 
	  # Denominator
	  d = 1 - (1 + r)**-term
	 
	  # Calc the monthly payment.
	  pmt = n / d
	end

	def self.taxes(price)
		taxes = price * 0.0128 / 12
	end

	def self.insurance(price)
		insurance = price * 0.003 / 12
	end

	def self.loan_amt(price, rent, rate, term)
		pmt = payment(rate, 1, term)
		loan_amt = [0.7 * (rent - taxes(price) - insurance(price)) / pmt, 0.7 * price].min
	end

	def self.net_return(price, loan_amt, noi)
		net_return = 1200 * noi / (price - loan_amt)  
	end

end