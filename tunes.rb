require 'rubygems'
require "bundler/setup"
require 'fileutils'

require 'sinatra'
require "sinatra/reloader" if development?

require 'haml'
require 'json'
require 'data_mapper'
require 'email_veracity'
require 'maruku'


require './scrape.rb'
require './util/pbkdf2.rb'
require './util/config.rb'
require './util/constants.rb'

require "./models/archive.rb"
require "./models/track.rb"



enable :logging
use Rack::CommonLogger


DataMapper.finalize
DataMapper.setup(:default, "sqlite3://#{Dir.pwd}/db_#{SiteName.downcase.gsub(' ', '_')}.sqlite3")
DataMapper.auto_upgrade!


configure :production do
	enable :dump_errors
	enable :logging
	enable :raise_errors
end


helpers do
	
	def permalink_for_article(article)
		
	end
	
	def base_url
		url = "http://#{request.host}"
		request.port == 80 ? url : url + ":#{request.port}"
	end
	
	
	def markdown
		if nil == $markdown
			$markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML, :autolink => true, :no_intra_emphasis => true, :fenced_code_blocks => true)
		end
		return $markdown
	end
	
	
	def render_markdown(text)
		rendered = markdown.render(text)
		return Redcarpet::Render::SmartyPants.render(rendered)
	end
	
	
	def pretty_date(date)
		date.strftime("%A, %B %e %Y")
	end
	
	def pretty_origin_date(date)
		"Created on " + pretty_date(date)
	end
		
	
	def sanitize_string(string)
		string.downcase.gsub(/[^a-zA-Z\d]/, "_")
	end
	
end



before "/debug*" do
	redirect "/" if !DebugPagesEnabled
end


before "/api/*" do
	content_type 'application/json'
	
	if request.request_method.upcase == 'POST'
		@data = JSON.parse(request.body.read)
	end
	
end

get '/' do
	# api-documentation page
	# api-documentation page
	doc_md = File.new("public/documentation.text", "r").read
	markdown = Maruku.new(doc_md)
	# read in the markdown, parse it, and stick it in a variable. then render with haml
	@documentation_html = markdown.to_html
	
	
	haml(:index)
end


get '/scrape' do
	
	puts "going to start the fetch"
	internal_scrape
	"Done"
end


def internal_scrape

	puts "Fetching archive list"
	agent = Mechanize.new
	agent.user_agent_alias = 'Friendly Tunes.io scraper bot by jbrennan@nearthespeedoflight.com'
	page = agent.get("http://tunes.io/archive.jsp")

	archive_links = page.links_with(:href => /playlist.jsp/)
	puts "Found archives online: " + archive_links.inspect

	archive_links.each do |archive_link|
		date = archive_link.text
		

		if should_fetch_playlist(date) == false
			puts "Skipping playlist for date " + date
			next
		end

		puts "Visiting archive for date: " + date
		archive = archive_link.click

		track_links = archive.search("ul.playlist li a")
		index = 0
		track_links.each do |track|
			link = track[:href]
			text = track.content

			process_track link, text, date, index

			index = index + 1

			puts "Found #{text} at #{link}"
		end
	end
end


def should_fetch_playlist(date)
	archive = Archive.first(:archive_name => date)
	puts "archive was nil" if archive == nil
	return archive == nil
end


def process_track(link, text, date, index)
	archive = Archive.first_or_create(:archive_name => date)
	
	parts = text.partition(" - ")
	artist_name = parts[0]
	track_name = parts[2]
	
	track = Track.first_or_create(:track_name => track_name, :track_artist_name => artist_name)
	track.track_file_url = link
	track.track_number = index
	track.archive = archive
	
	track.save
	archive.save
end




###
# Debug pages
###

get '/debug' do
	# list all debug pages
	@models = Array.new
	DataMapper::Model.descendants.each do |model|
		@models << model
	end
	
	@models.each do |m|
		m.properties.each do |p|
			puts p.name.to_s
		end
	end
	
	haml :debug
end

get '/debug/:class' do
	@class_name = params[:class]
	class_instance = Kernel.const_get(@class_name)
	return "No matching class" if nil == class_instance
	
	@properties = Array.new
	class_instance.properties.each do |property|
		@properties << property
	end
	
	@instances = Array.new
	collection = class_instance.all
	
	return "No rows for class #{@class_name}" if collection == nil or collection.empty?
	
	collection.each do |row|
		@instances << row
	end
	haml :debug_instances
end

get '/debug/:class/:id' do
	@class_name = params[:class]
	class_instance = Kernel.const_get(@class_name)
	return "No matching class" if nil == class_instance
	
	@object = class_instance.first(:id => params[:id])
	haml :debug_object
end



#########################
# API
#########################


get '/api/1/playlists.list' do
	playlists = Archive.all(:order => [:archive_name.desc])
	names = []
	playlists.each do |playlist|
		names << playlist.archive_name
	end
	
	return {
		:status => "OK",
		:playlists => names
	}.to_json
end


get '/api/1/playlists.tracks/:playlist_name' do
	playlist = Archive.first(:archive_name => params[:playlist_name])
	return {
		:status => "error"
	}.to_json if nil == playlist
	
	raw_tracks = Track.all(:archive => playlist, :order => [:track_number.asc])
	tracks = []
	
	raw_tracks.each do |track|
		tracks << {
			:track_name => track.track_name,
			:track_number => track.track_number,
			:track_artist_name => track.track_artist_name,
			:track_url => track.track_file_url
		}
	end
	
	return {
		:status => "OK",
		:tracks => tracks
	}.to_json
end



### Utilities


# Check to make sure the supplied list exists
def check_parameters *required
	required.each { |p|
		params[p].strip! if params[p] and params[p].is_a? String
		if !params[p] or (p.is_a? String and params[p].length == 0)
			return false
		end
	}
	true
end


def check_json_parameters hash, *required
	required.each do |p|
		hash[p].strip! if hash[p] and hash[p].is_a? String
		if !hash[p] or (hash[p].is_a? String and hash[p].length == 0)
			return false
		end
	end
	true
end


def api_error(error_message)
	return {
		:status => APIStatusError,
		:error => error_message
	}.to_json
end


def api_OK
	return {
		:status => APIStatusOK
	}.to_json
end

