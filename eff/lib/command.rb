require_relative 'config'
require_relative 'git'

module Efficiency

	class Command
		def self.clone_components(branch = 'master',output = nil)
			self.clone_group('components',branch,output)
		end

		def self.clone_apps(branch = 'master',output = nil)
			self.clone_group('apps',branch,output)
		end

		def self.clone_me(branch = 'master',output = nil)
			self.clone_group('me',branch,output)
		end

		def self.clone_group(key,branch = 'master',output = nil)
			if output.nil?
				Config::nodes(key).map { |e| Config::search_repo(e) }
				.each { |e| 
					Git::clone(e,branch,nil) 
				}	
			else
				Config::nodes(key).map { |e| Config.search_repo(e)}				
				.each { |e|					
					Git::clone(e,branch,output+"#{e.split('/').last}") 
				}
			end
			
		end		
	end
end