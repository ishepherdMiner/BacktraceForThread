#!/usr/bin/ruby
# encoding: utf-8 

$:.unshift File.dirname(__FILE__)

# require '../efficiency/autoload'
require 'find'
require 'fileutils'

module Efficiency
	def self.lack_good_name 
		source_dir = "/Users/shepherd/Developer/apps/20201006-OCLint/OCLint"
		target_dir = "/Users/shepherd/Developer/battle/llvm-project"
		search_dir = []
		Find.find(source_dir) do |path|
			if !path["podspec"] && !path[".DS_Store"] && File.file?(path)
				search_dir << path
			end	
		end	

		cp_search_dir = search_dir
		while cp_search_dir.count > 0
			puts "待遍历数组:#{cp_search_dir}"
			search_dir.each do |path|
				if !File.directory?(path)
					puts "开始遍历:======= #{path} ======="
	  				File.open(path, "r:ASCII-8BIT") do |file|
		  				file.each_line do |line|
							regexA = /#include <clang\/.*.h>/
							regexB = /#include "clang\/.*"/
							regexC = /#include "llvm\/.*"/
							regexD = /#include "llvm-c\/.*"/
							regexE = /#include ".*\.def"/
							regexF = /class .*;/
							if line.match(regexA)
								header_path = line.split(' ').last.gsub(/\</,"").gsub(/\>/,"")					
							elsif line.match(regexB) 
								header_path = line.split(' ').last.gsub(/\"/,"")
							elsif line.match(regexC) || line.match(regexD) || line.match(regexE)
								header_path = line.split(' ').last.gsub(/\"/,"")
							elsif line.match(regexF)
								puts line
								puts path								
							end
							unless header_path.nil?
								unless cp_search_dir.include?("#{source_dir}/#{header_path}")
									puts "新增:#{header_path}"
									cp_search_dir << "#{source_dir}/#{header_path}"
									self.cp_header(source_dir,target_dir,header_path)
								end								
							end
						end
					end
					puts "完成遍历:======= #{path} ======="
				end
				cp_search_dir.delete(path)
			end			
			search_dir = cp_search_dir
		end
	end

	def self.cp_header(source_dir,target_dir,header_path)
		header_dirname = File.dirname(header_path)				
		#puts header_dirname
		if !File.directory?("#{source_dir}/#{header_dirname}")
			FileUtils.mkdir_p("#{source_dir}/#{header_dirname}", :mode => 0777)
		end
		if !File.file?("#{source_dir}/#{header_path}")
			Find.find(target_dir) do |path|					
				if path[header_path] && File.basename(header_path) == File.basename(path)
					puts "找到:#{path}"
					FileUtils.cp(path,"#{source_dir}/#{header_path}")
				end
			end
		else
			puts "存在:#{source_dir}/#{header_path}"
		end		
	end
end

Efficiency.lack_good_name()
