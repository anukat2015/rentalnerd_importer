class GetdataDownloader
  class << self
    def get_file(url)
      temp_file = Tempfile.new( "getdata" )
      temp_file << open(url).read
      temp_file.rewind
      temp_file
    end
  end
end