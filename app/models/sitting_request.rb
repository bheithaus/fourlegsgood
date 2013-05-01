
require 'addressable/uri'

class SittingRequest < ActiveRecord::Base
  attr_accessible :owner_id, :start_date, :end_date, :status

  validates :owner_id, :start_date, :end_date, :status, presence: true

  belongs_to :owner, class_name: "User"

  def self.usersOfRequested

    query = "SELECT *
	    	 FROM users 
	   		 JOIN sitting_requests 
	   		 ON users.id = sitting_requests.owner_id
			 WHERE sitting_requests.status = 'requested'"

    ActiveRecord::Base.connection.execute(query);
  end


  def self.geocodedAddresses(users)
  queries = []

  users.each do |user|
				queries << Addressable::URI.new(
				  :scheme => "http",
				  :host => "maps.googleapis.com",
				  :path => "/maps/api/geocode/json",
				  :query_values => {:address => "#{user.address}",
				                     :sensor => "false"
				                    }
				  ).to_s
		end
	geocode_responses = queries.map do |query|
		JSON.parse(RestClient.get(query))
		end

	latlongs = geocode_responses.map do |gc_response|
		lat = gc_response["results"][0]["geometry"]["location"]["lat"]
		lng = gc_response["results"][0]["geometry"]["location"]["lng"]
		[lat, lng]
		end
	end


	def self.addressesofRequested
		usersToGeocode = []
		usersAlreadyGeocoded = []
		self.usersOfRequested.each do |user|
			if (user["lat"]== nil || user["lng"]== nil) 
			 	usersToGeocode<<user
			else
				usersAlreadyGeocoded<<user
			end
		end
		self.geocodeAddresses(usersToGeocode)
	end


end
