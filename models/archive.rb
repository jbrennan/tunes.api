require 'rubygems'
require 'dm-core'
require 'dm-timestamps'

require './models/track.rb'

class Archive
	include DataMapper::Resource

	property :id,	Serial
	property :archive_name, String
	property :archive_date, DateTime
	property :created_at,	DateTime
	property :updated_at, 	DateTime
	
	property :archive_url, Text

	has n, :tracks
end