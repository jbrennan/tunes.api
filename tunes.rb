require 'rubygems'
require "bundler/setup"
require 'fileutils'

require 'sinatra'
require "sinatra/reloader" if development?

require 'haml'
require 'json'
require 'data_mapper'
require 'email_veracity'
require 'redcarpet'

require './util/pbkdf2.rb'
require './util/config.rb'
require './util/constants.rb'



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
	haml :index
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

