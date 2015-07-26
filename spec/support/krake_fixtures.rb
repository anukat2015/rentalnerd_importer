module KrakeFixtures
  def krake_fixture(filename)
    File.new(krake_fixture_path + '/' + filename)
  end

  def krake_fixture_path
    File.expand_path("../../fixtures/krake", __FILE__)
  end
end
