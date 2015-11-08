require 'json'

namespace :db do
  desc "imports the parks provided in the shapefile called shape_file_sf_parks.json"  
  task :import_parks_sf => :environment do 
    puts "Importing park data"
    file = File.read('./lib/tasks/model_files/shape_file_sf_parks.json')
    data = JSON.parse(file)    

    data["features"].each do |row|

      if row["geometry"]["type"] == "MultiPolygon"
        row["geometry"]["coordinates"].each_index do |index|
          sub_area = row["geometry"]["coordinates"][index][0]
          p_name = row["properties"]["map_park_n"]
          p_name = "#{p_name} #{index}"
          puts "\t#{p_name}"
          pk = Park.where(name: p_name).first
          pk = Park.create!( name: p_name, size: row["properties"]["sqft"] ) if pk.nil?
          pk.empty_vertices!

          sub_area.each do |coord| 
            pv = ParkVertex.create(longitude: coord[0], latitude: coord[1])
            pk.add_vertice pv            
          end
          pk.update(shapefile_source: "SF")
        end


      elsif row["geometry"]["type"] == "Polygon"
        p_name = row["properties"]["map_park_n"]  
        puts "\t#{p_name}"
        pk = Park.where(name: p_name).first
        pk = Park.create!( name: p_name, size: row["properties"]["sqft"] ) if pk.nil?
        pk.empty_vertices!

        row["geometry"]["coordinates"][0].each do |coord|        
          pv = ParkVertex.create(longitude: coord[0], latitude: coord[1])
          pk.add_vertice pv
        end
        pk.update(shapefile_source: "SF")
      end
    end        
  end  
end