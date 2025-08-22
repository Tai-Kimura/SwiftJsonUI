#!/usr/bin/env ruby
# frozen_string_literal: true

require 'xcodeproj'

def cleanup_project(project_path)
  project = Xcodeproj::Project.open(project_path)
  
  # Get project name
  project_name = File.basename(project_path, '.xcodeproj')
  
  # Find and remove specific phantom groups
  phantom_groups = ['sjui_tools', 'Bindings', 'binding_builder', project_name]
  groups_removed = []
  
  # Check all groups at the root level
  project.main_group.groups.to_a.each do |group|
    # Remove if it's a phantom group (empty and matches patterns)
    if phantom_groups.include?(group.name) && group.files.empty? && group.groups.empty?
      puts "Removing phantom group: #{group.name}"
      groups_removed << group.name
      group.remove_from_project
    elsif group.name == project_name && group != project.main_group
      # Special case: duplicate project name group
      puts "Removing duplicate project group: #{group.name}"
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