#!/usr/bin/env ruby

require 'set'
require 'fileutils'

module SjuiTools
  module Binding
    module Tools
      class CleanupDuplicateReferences
        def self.cleanup(project_path)
          pbxproj_path = File.join(project_path, 'project.pbxproj')
          
          unless File.exist?(pbxproj_path)
            puts "Error: project.pbxproj not found at #{pbxproj_path}"
            return false
          end
          
          content = File.read(pbxproj_path)
          original_content = content.dup
          
          # Find app name
          app_name = File.basename(project_path, '.xcodeproj')
          
          # Track file references by their base name
          file_refs = {}
          
          # Find all PBXFileReference entries
          content.scan(/([A-F0-9]{24}) \/\* (.+?) \*\/ = \{[^}]*?isa = PBXFileReference[^}]*?path = "?([^";}]+)"?[^}]*?\}/) do |uuid, name, path|
            base_name = File.basename(path)
            file_refs[base_name] ||= []
            file_refs[base_name] << {uuid: uuid, name: name, path: path}
          end
          
          # Find duplicates and determine which to keep
          uuids_to_remove = Set.new
          paths_to_fix = {}
          
          file_refs.each do |base_name, refs|
            if refs.size > 1
              puts "Found #{refs.size} references for #{base_name}:"
              refs.each do |ref|
                puts "  - UUID: #{ref[:uuid]}, Path: #{ref[:path]}"
              end
              
              # Keep the one with the shorter/correct path (without app name prefix)
              correct_ref = refs.min_by { |r| r[:path].length }
              
              # Prefer paths without the app name prefix
              refs.each do |ref|
                if ref[:path].start_with?("#{app_name}/")
                  # This path has incorrect prefix
                  if ref != correct_ref
                    uuids_to_remove.add(ref[:uuid])
                    puts "  Removing duplicate: #{ref[:uuid]} with path #{ref[:path]}"
                  else
                    # Fix the path by removing prefix
                    new_path = ref[:path].sub(/^#{Regexp.escape(app_name)}\//, '')
                    paths_to_fix[ref[:uuid]] = {old: ref[:path], new: new_path}
                    puts "  Fixing path for #{ref[:uuid]}: #{ref[:path]} -> #{new_path}"
                  end
                elsif ref != correct_ref
                  uuids_to_remove.add(ref[:uuid])
                  puts "  Removing duplicate: #{ref[:uuid]}"
                end
              end
            elsif refs.size == 1 && refs[0][:path].start_with?("#{app_name}/")
              # Single reference but with wrong prefix
              ref = refs[0]
              new_path = ref[:path].sub(/^#{Regexp.escape(app_name)}\//, '')
              paths_to_fix[ref[:uuid]] = {old: ref[:path], new: new_path}
              puts "Fixing path for #{base_name}: #{ref[:path]} -> #{new_path}"
            end
          end
          
          # Fix paths
          paths_to_fix.each do |uuid, path_info|
            # Fix in PBXFileReference
            content.gsub!(/#{uuid} \/\* .+? \*\/ = \{([^}]*?)path = "?#{Regexp.escape(path_info[:old])}"?([^}]*?)\}/) do
              "#{uuid} /* #{File.basename(path_info[:new])} */ = {#{$1}path = #{path_info[:new]}#{$2}}"
            end
          end
          
          # Remove duplicate references
          uuids_to_remove.each do |uuid|
            # Remove from PBXBuildFile
            content.gsub!(/[A-F0-9]{24} \/\* .+? \*\/ = \{[^}]*?fileRef = #{uuid}[^}]*?\};?\n/, '')
            
            # Remove from PBXFileReference  
            content.gsub!(/#{uuid} \/\* .+? \*\/ = \{[^}]*?isa = PBXFileReference[^}]*?\};?\n/, '')
            
            # Remove from groups
            content.gsub!(/(children = \([^)]*?)#{uuid} \/\* .+? \*\/,?\s*([^)]*?\))/) do
              children_start = $1
              children_end = $2
              # Clean up any double commas or trailing commas
              result = "#{children_start}#{children_end}"
              result.gsub!(/,\s*,/, ',')
              result.gsub!(/\(\s*,/, '(')
              result.gsub!(/,\s*\)/, ')')
              result
            end
            
            # Remove from PBXSourcesBuildPhase
            content.gsub!(/(files = \([^)]*?)#{uuid} \/\* .+? \*\/,?\s*([^)]*?\))/) do
              files_start = $1
              files_end = $2
              result = "#{files_start}#{files_end}"
              result.gsub!(/,\s*,/, ',')
              result.gsub!(/\(\s*,/, '(')
              result.gsub!(/,\s*\)/, ')')
              result
            end
          end
          
          if content != original_content
            # Backup original
            backup_path = "#{pbxproj_path}.backup.#{Time.now.to_i}"
            FileUtils.cp(pbxproj_path, backup_path)
            puts "Created backup: #{backup_path}"
            
            # Write cleaned content
            File.write(pbxproj_path, content)
            puts "Cleaned up duplicate references in #{pbxproj_path}"
            puts "Removed #{uuids_to_remove.size} duplicate references"
            puts "Fixed #{paths_to_fix.size} incorrect paths"
            true
          else
            puts "No duplicate references found"
            false
          end
        end
      end
    end
  end
end

# Run if executed directly
if __FILE__ == $0
  if ARGV.empty?
    puts "Usage: #{$0} <path_to_xcodeproj>"
    exit 1
  end
  
  SjuiTools::Binding::Tools::CleanupDuplicateReferences.cleanup(ARGV[0])
end