require "rubygems"
require "mechanize"

def scrape should_fetch_playlist, process_track
	
	puts "Fetching archive list"
	agent = Mechanize.new
	page = agent.get("http://tunes.io/archive.jsp")
	
	archive_links = page.links_with(:href => /playlist.jsp/)
	puts "Found archives online: " + archive_links.inspect
	
	archive_links.each do |archive_link|
		date = archive_link.text
		should = should_fetch_playlist.call(date)
		puts "Should? " + should
		
		if should_fetch_playlist.call(date) == false
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
			
			process_track.call link, text, date, index
			
			index = index + 1
			
			puts "Found #{text} at #{link}"
		end
	end
end
