require 'json'

namespace :db do
  desc "imports the neighborhoods provided in the shapefile called shape_file.json"  
  task :import_neighborhoods_sf => :environment do 
    puts "Importing neighborhoods data"
    file = File.read('./lib/tasks/model_files/shape_file_sf.json')
    data = JSON.parse(file)

    data["features"].each do |row|
      
      if row["geometry"]["type"] == "MultiPolygon"
        row["geometry"]["coordinates"].each_index do |index|
          sub_area = row["geometry"]["coordinates"][index][0]
          n_name = row["properties"]["nbrhood"]
          n_name = "#{n_name} #{index}"
          puts "\t#{n_name}"
          nb = Neighborhood.where(name: n_name).first
          nb = Neighborhood.create!( name: n_name ) if nb.nil?
          nb.empty_vertices!

          sub_area.each do |coord| 
            nv = NeighborhoodVertex.create(longitude: coord[0], latitude: coord[1])
            nb.add_vertex nv            
          end
          nb.update(shapefile_source: "SF")
        end

      elsif row["geometry"]["type"] == "Polygon"
        n_name = row["properties"]["nbrhood"]  
        puts "\t#{n_name}"
        nb = Neighborhood.where(name: n_name).first
        nb = Neighborhood.create!( name: n_name ) if nb.nil?
        nb.empty_vertices!

        row["geometry"]["coordinates"][0].each do |coord|        

          nv = NeighborhoodVertex.create(longitude: coord[0], latitude: coord[1])
          nb.add_vertex nv
        end
        nb.update(shapefile_source: "SF")
      end

    end
  end

  desc "updates the shapefile source for a Neighborhood"  
  task :update_neighborhoods_name_ph => :environment do 
    puts "Importing neighborhoods data"
    file = File.read('./lib/tasks/model_files/shape_file_sf.json')
    data = JSON.parse(file)

    data["features"].each do |row|
      
      if row["geometry"]["type"] == "MultiPolygon"
        row["geometry"]["coordinates"].each_index do |index|
          sub_area = row["geometry"]["coordinates"][index][0]
          n_name = row["properties"]["nbrhood"]
          n_name = "#{n_name} #{index}"
          puts "\t#{n_name}"
          nb = Neighborhood.where(name: n_name).first
          nb.update(shapefile_source: "SF") unless nb.nil?
          
        end

      elsif row["geometry"]["type"] == "Polygon"
        n_name = row["properties"]["nbrhood"]  
        puts "\t#{n_name}"
        nb = Neighborhood.where(name: n_name).first
        nb.update(shapefile_source: "SF") unless nb.nil?
      end

    end
  end  
end