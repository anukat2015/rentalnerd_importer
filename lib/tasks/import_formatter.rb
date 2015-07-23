module ImportFormatter
  class << self
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
        if value_string.include?("(") && value_string.include?(")") 
          value_string = value_string.delete("(").delete(")")
          value_string = "-" + value_string
        end

        return_float = value_string.delete(",").to_f 
      end
      return_float
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
      issue_date = Date.strptime(raw_string,"%m/%d/%Y") unless raw_string.nil?
    end

  end
end