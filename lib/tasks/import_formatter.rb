module ImportFormatter
  class << self

    def to_integer(value_string)
      return_int = nil
    end

    # Given the following value returns a float value
    #
    #   Params:
    #     value_string: (4,000.00)
    #
    #   Returns:
    #     float: -4000.00
    #
    def to_float(value_string)
      return_float = 0
      if !value_string.nil? && value_string != "N/A" && value_string !="-"

        # Convert to negative
        if value_string.include?("(") && value_string.include?(")") 
          value_string = value_string.delete("(").delete(")")
          value_string = "-" + value_string
        end
        return_float = value_string.delete(",").to_f 
      end
      return_float
    end

    # Given the following value returns a float value
    #
    #   Params:
    #     value_string: (4,000.00)
    #
    #   Returns:
    #     float: -4000.00
    #
    def to_decimal(value_string)
      return_float = 0
      if !value_string.nil? && value_string != "N/A" && value_string !="-"

        # Convert to negative
        if value_string.include?("(") && value_string.include?(")") 
          value_string = value_string.delete("(").delete(")")
          value_string = "-" + value_string
        end
        return_float = value_string.delete(",")
      end
      BigDecimal.new(return_float)
    end    

    # Removes the breakline in a string unless its nil
    # If string is NIl returns empty string
    def to_string(raw_string)
      processed_string = ''
      processed_string = raw_string.sub("\n", " ") unless raw_string.nil?
    end

    # Given a String of the format DD/MM/YYYY returns the actual date object
    # If nil returns nil
    def to_date(raw_string)
      return nil if raw_string.nil?
      Date.strptime(raw_string,"%m/%d/%Y") rescue nil
    end

    # Given a String of the format DD/MM/YYYY returns the actual date object
    # If nil returns nil
    def to_date_short_year(raw_string)
      return nil if raw_string.nil?
      Date.strptime(raw_string,"%m/%d/%y") rescue nil
    end

  end
end