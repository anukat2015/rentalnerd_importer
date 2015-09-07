require 'spec_helper'

RSpec.describe Neighborhood, type: :model do

  def google_map_request
    stub_request(:get, /.*maps.googleapis.com.*address.*/).to_return(:status => 200, :body => rni_fixture("google_map_location.json"), :headers => {})
    stub_request(:get, /.*maps.googleapis.com.*elevation.*/).to_return(:status => 200, :body => rni_fixture("google_elevation.json"), :headers => {})
  end

  before do
    google_map_request
  end  

  context "add_vertice" do
    let(:neighborhood) { create(:neighborhood) }

    describe "#add_vertice" do 

      it "adds a new vertex to the Neighborhood" do
        vertex = create(:neighborhood_vertex)
        neighborhood.add_vertice vertex
        added_vertex = NeighborhoodVertex.where( neighborhood_id: neighborhood.id ).first
        added_vertex.id.should == vertex.id
        added_vertex.vertex_order.should == 0
      end

      it "adds two vertices to the Neighborhood" do
        vertex = create(:neighborhood_vertex)
        neighborhood.add_vertice vertex

        vertex_2 = create(:neighborhood_vertex)
        neighborhood.add_vertice vertex_2

        neighborhood.neighborhood_vertices.size.should == 2
        vertex_2.vertex_order.should == 1
      end

      it "adds a vertices that was assigned to Neighborhood but with no order" do
        vertex = create(:neighborhood_vertex)
        neighborhood.add_vertice vertex

        vertex_2 = create(:neighborhood_vertex, neighborhood_id: neighborhood.id, vertex_order: nil )
        neighborhood.reload
        neighborhood.add_vertice vertex_2

        neighborhood.neighborhood_vertices.size.should == 2
        vertex_2.vertex_order.should == 1
      end

    end

    describe "#is_complete?" do
      it "returns false when neighborhood has less than 3 vertices " do
        vertex = create(:neighborhood_vertex)
        neighborhood.add_vertice vertex
        neighborhood.is_complete?.should == false
      end

      it "returns true when neighborhood has more than or equals to 3 vertices " do
        3.times {
          vertex = create(:neighborhood_vertex)
          neighborhood.add_vertice vertex
        }

        neighborhood.is_complete?.should == true        
      end      
    end

    describe "#recompute_max_min" do
      it "sets the maximum latitude" do
        vertex_1 = create(:neighborhood_vertex, latitude: 100)
        vertex_2 = create(:neighborhood_vertex, latitude: 50)
        neighborhood.add_vertice vertex_1
        neighborhood.add_vertice vertex_2
        neighborhood.max_latitude.should == 100
      end

      it "sets the minimum latitude" do
        vertex_1 = create(:neighborhood_vertex, latitude: 100)
        vertex_2 = create(:neighborhood_vertex, latitude: 50)
        neighborhood.add_vertice vertex_1
        neighborhood.add_vertice vertex_2
        neighborhood.min_latitude.should == 50
      end

      it "sets the maximum longitude" do
        vertex_1 = create(:neighborhood_vertex, longitude: 100)
        vertex_2 = create(:neighborhood_vertex, longitude: 50)
        neighborhood.add_vertice vertex_1
        neighborhood.add_vertice vertex_2
        neighborhood.max_longitude.should == 100
      end

      it "sets the minimum longitude" do
        vertex_1 = create(:neighborhood_vertex, longitude: 100)
        vertex_2 = create(:neighborhood_vertex, longitude: 50)
        neighborhood.add_vertice vertex_1
        neighborhood.add_vertice vertex_2
        neighborhood.min_longitude.should == 50
      end

    end

    describe "#guess" do
      it "returns a list of neighborhoods that a property might potentially belong to" do
        property = create(:property )
        n1 = create(:neighborhood, min_latitude: 0, max_latitude: 100, min_longitude: 0, max_longitude: 100)
        n2 = create(:neighborhood, min_latitude: 100, max_latitude: 200, min_longitude: 0, max_longitude: 100)
        n3 = create(:neighborhood, min_latitude: 0, max_latitude: 100, min_longitude: 100, max_longitude: 200)

        property.update( longitude: 50, latitude: 50 )
        ns = Neighborhood.guess property
        ns.size.should == 1
        ns.first.id.should == n1.id
      end
    end

    describe "#get_all_edges" do
      it "returns a list of edges" do
        vertex_1 = create(:neighborhood_vertex, latitude: 0, longitude: 0)
        vertex_2 = create(:neighborhood_vertex, latitude: 100, longitude: 0)
        vertex_3 = create(:neighborhood_vertex, latitude: 0, longitude: 100)
        neighborhood.add_vertice vertex_1
        neighborhood.add_vertice vertex_2
        neighborhood.add_vertice vertex_3

        edges = neighborhood.get_all_edges
        edges.size.should == 3
        edges[0].start_vertex.id.should == vertex_1.id
        edges[0].end_vertex.id.should   == vertex_2.id

        edges[1].start_vertex.id.should == vertex_2.id
        edges[1].end_vertex.id.should   == vertex_3.id

        edges[2].start_vertex.id.should == vertex_3.id
        edges[2].end_vertex.id.should   == vertex_1.id
      end
    end

    describe "#get_all_qualified_edges" do
      it "no edges with latitude ending after the latitude of the given property" do
        vertex_1 = create(:neighborhood_vertex, latitude: 0, longitude: 0)
        vertex_2 = create(:neighborhood_vertex, latitude: 25, longitude: 0)
        vertex_3 = create(:neighborhood_vertex, latitude: 0, longitude: 25)
        neighborhood.add_vertice vertex_1
        neighborhood.add_vertice vertex_2
        neighborhood.add_vertice vertex_3        

        property = create(:property )
        property.update( longitude: 50, latitude: 50 )

        edges = neighborhood.get_all_qualified_edges property
        edges.size.should == 0
      end

      it "returns a list of edges with latitude ending after the latitude of the given property" do
        vertex_1 = create(:neighborhood_vertex, latitude: 0, longitude: 0)
        vertex_2 = create(:neighborhood_vertex, latitude: 100, longitude: 0)
        vertex_3 = create(:neighborhood_vertex, latitude: 0, longitude: 100)
        vertex_4 = create(:neighborhood_vertex, latitude: -100, longitude: 0)
        vertex_5 = create(:neighborhood_vertex, latitude: 0, longitude: -100)

        neighborhood.add_vertice vertex_1
        neighborhood.add_vertice vertex_2
        neighborhood.add_vertice vertex_3
        neighborhood.add_vertice vertex_4
        neighborhood.add_vertice vertex_5

        property = create(:property )
        property.update( longitude: 50, latitude: 50 )

        edges = neighborhood.get_all_qualified_edges property
        edges.size.should == 2
      end      
    end

    describe "#belongs_here?" do
      it "returns true when property is right on an edge" do 
        vertex_1 = create(:neighborhood_vertex, latitude: 0, longitude: 0)
        vertex_2 = create(:neighborhood_vertex, latitude: 100, longitude: 0)
        vertex_3 = create(:neighborhood_vertex, latitude: 0, longitude: 100)
        vertex_4 = create(:neighborhood_vertex, latitude: -100, longitude: 0)
        vertex_5 = create(:neighborhood_vertex, latitude: 0, longitude: -100)

        neighborhood.add_vertice vertex_1
        neighborhood.add_vertice vertex_2
        neighborhood.add_vertice vertex_3
        neighborhood.add_vertice vertex_4
        neighborhood.add_vertice vertex_5        

        property = create(:property )
        property.update( longitude: 49, latitude: 49 )
        neighborhood.belongs_here?(property).should == true
      end

      it "returns true when property is within the boundaries" do 
        vertex_1 = create(:neighborhood_vertex, latitude: 0, longitude: 0)
        vertex_2 = create(:neighborhood_vertex, latitude: 100, longitude: 0)
        vertex_3 = create(:neighborhood_vertex, latitude: 0, longitude: 100)
        vertex_4 = create(:neighborhood_vertex, latitude: -100, longitude: 0)
        vertex_5 = create(:neighborhood_vertex, latitude: 0, longitude: -100)

        neighborhood.add_vertice vertex_1
        neighborhood.add_vertice vertex_2
        neighborhood.add_vertice vertex_3
        neighborhood.add_vertice vertex_4
        neighborhood.add_vertice vertex_5        

        property = create(:property )
        property.update( longitude: 25, latitude: 25 )
        neighborhood.belongs_here?(property).should == true
      end      

      it "returns true when property is right on a vertex" do 
        vertex_1 = create(:neighborhood_vertex, latitude: 0, longitude: 0)
        vertex_2 = create(:neighborhood_vertex, latitude: 100, longitude: 0)
        vertex_3 = create(:neighborhood_vertex, latitude: 0, longitude: 100)
        vertex_4 = create(:neighborhood_vertex, latitude: -100, longitude: 0)
        vertex_5 = create(:neighborhood_vertex, latitude: 0, longitude: -100)

        neighborhood.add_vertice vertex_1
        neighborhood.add_vertice vertex_2
        neighborhood.add_vertice vertex_3
        neighborhood.add_vertice vertex_4
        neighborhood.add_vertice vertex_5        

        property = create(:property )
        property.update( longitude: 0, latitude: 0 )
        neighborhood.belongs_here?(property).should == true
      end

      it "returns false when property is outside of boundary slightly to the east" do 
        vertex_1 = create(:neighborhood_vertex, latitude: 0, longitude: 0)
        vertex_2 = create(:neighborhood_vertex, latitude: 100, longitude: 0)
        vertex_3 = create(:neighborhood_vertex, latitude: 0, longitude: 100)
        vertex_4 = create(:neighborhood_vertex, latitude: -100, longitude: 0)
        vertex_5 = create(:neighborhood_vertex, latitude: 0, longitude: -100)

        neighborhood.add_vertice vertex_1
        neighborhood.add_vertice vertex_2
        neighborhood.add_vertice vertex_3
        neighborhood.add_vertice vertex_4
        neighborhood.add_vertice vertex_5        

        property = create(:property )
        property.update( longitude: 51, latitude: 51 )
        neighborhood.belongs_here?(property).should == false
      end

      it "returns false when property is outside of boundary slightly to the west" do 
        vertex_1 = create(:neighborhood_vertex, latitude: 0, longitude: 0)
        vertex_2 = create(:neighborhood_vertex, latitude: 100, longitude: 0)
        vertex_3 = create(:neighborhood_vertex, latitude: 0, longitude: 100)
        vertex_4 = create(:neighborhood_vertex, latitude: -100, longitude: 0)
        vertex_5 = create(:neighborhood_vertex, latitude: 0, longitude: -100)

        neighborhood.add_vertice vertex_1
        neighborhood.add_vertice vertex_2
        neighborhood.add_vertice vertex_3
        neighborhood.add_vertice vertex_4
        neighborhood.add_vertice vertex_5        

        property = create(:property )
        property.update( longitude: -51, latitude: -51 )
        neighborhood.belongs_here?(property).should == false
      end

      it "returns false when property is outside of boundary slightly to the north" do 
        vertex_1 = create(:neighborhood_vertex, latitude: 0, longitude: 0)
        vertex_2 = create(:neighborhood_vertex, latitude: 100, longitude: 0)
        vertex_3 = create(:neighborhood_vertex, latitude: 0, longitude: 100)
        vertex_4 = create(:neighborhood_vertex, latitude: -100, longitude: 0)
        vertex_5 = create(:neighborhood_vertex, latitude: 0, longitude: -100)

        neighborhood.add_vertice vertex_1
        neighborhood.add_vertice vertex_2
        neighborhood.add_vertice vertex_3
        neighborhood.add_vertice vertex_4
        neighborhood.add_vertice vertex_5        

        property = create(:property )
        property.update( longitude: 0, latitude: 101 )
        neighborhood.belongs_here?(property).should == false
      end      

      it "returns false when property is outside of boundary slightly to the south" do 
        vertex_1 = create(:neighborhood_vertex, latitude: 0, longitude: 0)
        vertex_2 = create(:neighborhood_vertex, latitude: 100, longitude: 0)
        vertex_3 = create(:neighborhood_vertex, latitude: 0, longitude: 100)
        vertex_4 = create(:neighborhood_vertex, latitude: -100, longitude: 0)
        vertex_5 = create(:neighborhood_vertex, latitude: 0, longitude: -100)

        neighborhood.add_vertice vertex_1
        neighborhood.add_vertice vertex_2
        neighborhood.add_vertice vertex_3
        neighborhood.add_vertice vertex_4
        neighborhood.add_vertice vertex_5        

        property = create(:property )
        property.update( longitude: 0, latitude: -101 )
        neighborhood.belongs_here?(property).should == false
      end      

    end

    describe "#empty_vertices!" do
      it "removes all vertices associated with neighborhood" do
        vertex_1 = create(:neighborhood_vertex, latitude: 0, longitude: 0)
        vertex_2 = create(:neighborhood_vertex, latitude: 100, longitude: 0)
        vertex_3 = create(:neighborhood_vertex, latitude: 0, longitude: 100)
        vertex_4 = create(:neighborhood_vertex, latitude: -100, longitude: 0)
        vertex_5 = create(:neighborhood_vertex, latitude: 0, longitude: -100)

        neighborhood.add_vertice vertex_1
        neighborhood.add_vertice vertex_2
        neighborhood.add_vertice vertex_3
        neighborhood.add_vertice vertex_4
        neighborhood.add_vertice vertex_5        
        neighborhood.neighborhood_vertices.size.should == 5

        neighborhood.empty_vertices!
        neighborhood.neighborhood_vertices.size.should == 0
      end

      it "does not remove vertices not associated with neighborhood" do
        neighborhood_2 = create(:neighborhood)
        vertex_6 = create(:neighborhood_vertex, latitude: 0, longitude: 0)
        neighborhood_2.add_vertice vertex_6        

        neighborhood.empty_vertices!
        neighborhood.neighborhood_vertices.size.should == 0
        neighborhood_2.neighborhood_vertices.size.should == 1
      end
    end

  end

end