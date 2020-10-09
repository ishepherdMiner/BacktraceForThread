# puts File.dirname(__FILE__)
# TODO
# Dir["#{File.dirname(__FILE__)}/lib/**/*.rb"].each { |file| require file  }

require_relative 'lib/config'
require_relative 'lib/git'
require_relative 'lib/command'