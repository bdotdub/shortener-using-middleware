require 'rubygems'
require 'sinatra'
require 'shortener'
require 'thread'

module Rack
  class Shortener
    def initialize app
      @app = app
      @lock = Mutex.new
      @cache = {}
      @cache_updater = Thread.start do
        while true do
          refresh_cache
          sleep 60
        end
      end
    end

    def call env
      if env['PATH_INFO'] !~ /^\/admin/
        location = @cache[env['PATH_INFO']] || 'http://bwong.net/'
        return [301, { 'Location' => location, 'Content-Type' => 'text/html' }, ['Bye!']]
      end
      @app.call(env)
    end

    def refresh_cache
      # Pull new info from database
      puts "Refreshing cache"
      new_cache = {
        '/benny'=> [' http://bwong.net/', 'http://tumblr.bwong.net/', 'http://twitter.com/bdotdub', 'http://www.exitstrategynyc.com/', 'http://www.icombinator.net/' ].sort_by { rand }.first,
        '/news' => [ 'http://www.nytimes.com', 'http://www.cnn.com', 'http://news.ycombinator.com' ].sort_by { rand }.first,
        '/search' => [ 'http://www.google.com', 'http://bing.com', 'http://www.yahoo.com' ].sort_by { rand }.first,
        '/shop' => [ 'http://www.gilt.com' ].sort_by { rand }.first
      }
      @lock.synchronize do
        @cache = new_cache
      end
      puts "Cache is now: #{@cache.inspect}"
    end
  end
end

use Rack::Shortener
run Sinatra::Application
