
require 'httparty'
require 'redis'
require 'sinatra/base'
require 'sinatra/reloader'

require_relative 'server'

run GamerInput::Server
