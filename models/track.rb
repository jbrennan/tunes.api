require 'rubygems'
require 'dm-core'
require 'dm-timestamps'

require './models/archive.rb'

class Track
	include DataMapper::Resource

	property :id,	Serial
	property :track_name, Text
	property :track_number, Integer
	property :track_artist_name, Text
	property :track_file_url, Text
	property :created_at,	DateTime
	property :updated_at, 	DateTime

	belongs_to :archive
end