#!/usr/bin/ruby
module Efficiency
	class Config
		@@base_url = "ishepherdme@wangdl.synology.me:/var/services/homes/ishepherdme/git"
		@@nodes = {
			'component' => [
				
			],
			'apps' => [
				
			],
			'me' => [
				
			],
			'tweaker' => [
				
			],
			'scritps' => [
				
			]
		}

		def self.search_repo(path)	
			# puts "path = #{path}"			
			target = @@nodes.select { |k,v| v.include?(path)}			
			target_key = target.keys.last			
			target_val = target[target_key].find { |v| v == path }
			# print target_val			
			if target_key == 'apps' 
				# puts "target = #{target}"				
				target_val = 'apps/' + target_val
			end			
			@@base_url + '/' + target_val + '.git'
		end

		def self.nodes(key)
			@@nodes[key]
		end
	end
end
