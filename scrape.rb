require "rubygems"
require "mechanize"

agent = Mechanize.new
page = agent.get("http://tunes.io/archive.jsp")

archive_links = page.links_with(:href => /playlist.jsp/)

archive_links.each do |archive_link|
	date = archive_link.text
	puts "Visiting archive for date: " + date
	archive = archive_link.click
	
	track_links = archive.search("ul.playlist li a")
	
	track_links.each do |track|
		link = track[:href]
		text = track.content
		
		puts "Found #{text} at #{link}"
	end
end