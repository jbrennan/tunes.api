tunes.api — A friendly JSON API on top of Tunes.io
==================================================

A few weeks ago I discovered the lovely [Tunes.io] [io] site by Everlook.ca. The site provides a playlist of new, mostly indie — and totally awesome — tracks every day.

But I found using it in a browser to be a little confining, so I've written a small Sinatra web app that can scrape the site (gently!) and provides a really small JSON API for non-browser clients.

To Install
----------

Clone and `cd` into the repo, then use `bundle install` to install all the dependencies. If you're running it on a local (i.e., dev) machine, use `ruby tunes.rb` to run it. If you're running on a hosted service, Rack should pick up the `config.ru` on its own.

To use
------

Because my host isn't too keen on scheduling background jobs, I've just included a simple URL for scraping. With the server running hit `/scrape` to set off a scrape. Then you can consume the API.

Scraping sounds so unpleasant
-----------------------------

It really does. And it can be unpleasant for the hosting service. So, I've tried to make the process as nice as possible. After the initial archive scrape, the script will only scrape new pages that it doesn't already have. Plus, it only needs to be run once per day.