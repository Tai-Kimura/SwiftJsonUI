#!/usr/bin/env ruby

require 'xcodeproj'
require_relative '../xcode_project_manager'
require_relative '../../core/project_finder'

module SjuiTools
  module Binding
    module XcodeProject
      class CleanupReferences
        def initialize(project_file_path = nil)
          @project_file_path = project_file_path || Core::ProjectFinder.find_project_file
          @project = Xcodeproj::Project.open(@project_file_path)
        end
        
        def run
          puts "=== Cleaning up Xcode project references ==="
          
          remove_unwanted_references
          remove_unwanted_from_targets
          
          @project.save
          puts "=== Cleanup completed successfully! ==="
        end
        
        private
        
        def remove_unwanted_references
          puts "Removing unwanted file references..."
          
          files_to_remove = []
          
          # Walk through all files in the project
          @project.files.each do |file_ref|
            path = file_ref.path || ""
            name = file_ref.name || ""
            
            # Check against exclusion patterns
            if should_exclude?(path) || should_exclude?(name)
              puts "  Removing reference: #{path}"
              files_to_remove << file_ref
            end
          end
          
          # Remove the files
          files_to_remove.each do |file_ref|
            file_ref.remove_from_project
          end
          
          # Also check and remove groups
          groups_to_remove = []
          
          @project.main_group.recursive_children_groups.each do |group|
            if should_exclude_group?(group.path || group.name || "")
              puts "  Removing group: #{group.name}"
              groups_to_remove << group
            end
          end
          
          groups_to_remove.each do |group|
            group.remove_from_project
          end
        end
        
        def remove_unwanted_from_targets
          puts "Removing unwanted files from build targets..."
          
          @project.targets.each do |target|
            target.build_phases.each do |phase|
              next unless phase.respond_to?(:files)
              
              files_to_remove = []
              
              phase.files.each do |build_file|
                next unless build_file.file_ref
                
                path = build_file.file_ref.path || ""
                name = build_file.file_ref.name || ""
                
                if should_exclude?(path) || should_exclude?(name)
                  puts "  Removing from #{target.name}: #{path}"
                  files_to_remove << build_file
                end
              end
              
              files_to_remove.each do |build_file|
                phase.remove_build_file(build_file)
              end
            end
          end
        end
        
        def should_exclude?(path)
          excluded_patterns = ::SjuiTools::Binding::XcodeProjectManager::EXCLUDED_PATTERNS
          
          excluded_patterns.any? do |pattern|
            if pattern.end_with?('/')
              path.start_with?(pattern.chomp('/'))
            else
              path == pattern || File.basename(path) == pattern
            end
          end
        end
        
        def should_exclude_group?(name)
          excluded_groups = [
            'sjui_tools',
            'binding_builder',
            '.git',
            '.github',
            '.build',
            '.swiftpm',
            'Tests',
            'UITests',
            'Docs',
            'docs',
            'config',
            'installer'
          ]
          
          excluded_groups.include?(name)
        end
      end
    end
  end
end

# Command line execution
if __FILE__ == $0
  begin
    cleanup = SjuiTools::Binding::XcodeProject::CleanupReferences.new
    cleanup.run
  rescue => e
    puts "Error: #{e.message}"
    puts e.backtrace if ENV['DEBUG']
    exit 1
  end
end