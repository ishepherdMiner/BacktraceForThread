#!/usr/bin/ruby
require_relative 'core_ui'

module Efficiency
	class Git
		@cmd

		def self.clone(url,branch = 'master',output = nil)
			is_exists =  Dir.exist?File.expand_path(output)
			if !is_exists
				if branch == 'master'
					@cmd = "git clone #{url} #{output}"	
				else
					@cmd = "git clone -b #{branch} #{url} #{output}"
				end
				
				CoreUI.puts "#{@cmd}"
				system @cmd
			else
				CoreUI.warn "dst dir:#{url} is exists"
			end
		end
	end
end 