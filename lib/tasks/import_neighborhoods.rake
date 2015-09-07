require 'json'

namespace :db do
  desc "imports the neighborhoods provided in the shapefile called shape_file.json"  
  task :import_neighborhoods => :environment do 
    puts "Importing neighborhoods data"
    file = File.read('./lib/tasks/shape_file.json')
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
            nb.add_vertice nv            
          end

        end

      else row["geometry"]["type"] == "Polygon"
        n_name = row["properties"]["nbrhood"]  
        puts "\t#{n_name}"
        nb = Neighborhood.where(name: n_name).first
        nb = Neighborhood.create!( name: n_name ) if nb.nil?
        nb.empty_vertices!

        row["geometry"]["coordinates"][0].each do |coord|        

          nv = NeighborhoodVertex.create(longitude: coord[0], latitude: coord[1])
          nb.add_vertice nv
        end
      end

    end
  end
end