module RniFixtures
  def rni_fixture(filename)
    File.new(rni_fixture_path + '/' + filename)
  end

  def rni_fixture_path
    File.expand_path("../../fixtures", __FILE__)
  end
end
