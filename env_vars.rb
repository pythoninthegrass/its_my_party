#!/usr/bin/env ruby

require 'dotenv'

# load environment variables from .env file and store them in a hash
env_vars = Dotenv.overload

# print only the variables that were loaded from the .env file
env_vars.sort.each do |key, value|
    puts "#{key}: #{value}"
end
