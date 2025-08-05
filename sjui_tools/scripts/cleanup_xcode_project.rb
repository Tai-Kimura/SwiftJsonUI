#!/usr/bin/env ruby
# frozen_string_literal: true

require 'xcodeproj'

def cleanup_project(project_path)
  project = Xcodeproj::Project.open(project_path)
  
  # Find and remove specific phantom groups
  phantom_groups = ['sjui_tools', 'Bindings']
  groups_removed = []
  
  project.main_group.groups.each do |group|
    if phantom_groups.include?(group.name) && group.files.empty? && group.groups.empty?
      puts "Removing phantom group: #{group.name}"
      groups_removed << group.name
      group.remove_from_project
    end
  end
  
  if groups_removed.any?
    project.save
    puts "Removed #{groups_removed.size} phantom groups: #{groups_removed.join(', ')}"
  else
    puts "No phantom groups found to remove."
  end
rescue => e
  puts "Error cleaning project: #{e.message}"
  puts e.backtrace.first(5).join("\n")
end

# Check command line arguments
if ARGV.empty?
  puts "Usage: #{$0} <path_to_xcodeproj>"
  exit 1
end

project_path = ARGV[0]
unless File.exist?(project_path)
  puts "Error: Project not found at #{project_path}"
  exit 1
end

cleanup_project(project_path)