#!/usr/bin/env ruby

require "fileutils"
require "pathname"
require "json"
require 'xcodeproj'
require_relative '../project_finder'
require_relative '../config_manager'

module SjuiTools
  module Core
    module Setup
      class LibrarySetup
        def initialize(project_file_path = nil)
          if project_file_path
            @project_file_path = project_file_path
          else
            @project_file_path = Core::ProjectFinder.find_project_file
          end
          
          @project = Xcodeproj::Project.open(@project_file_path)
          @config = Core::ConfigManager.load_config
        end

        def setup_libraries
          puts "Setting up required libraries..."
          
          # Add all required packages
          add_all_packages
          
          # Save project
          @project.save
          
          puts "Library setup completed successfully!"
        end

        private
        
        def get_current_version
          # Check git branch first
          begin
            git_branch = `git rev-parse --abbrev-ref HEAD 2>/dev/null`.strip
            return git_branch unless git_branch.empty?
          rescue
            # Git command failed, continue with other methods
          end
          
          # Fallback to default
          "default"
        end
        
        def load_library_versions
          base_dir = File.expand_path('../../../..', File.dirname(__FILE__))
          versions_file = File.join(base_dir, 'config', 'library_versions.json')
          
          if File.exist?(versions_file)
            begin
              JSON.parse(File.read(versions_file))
            rescue JSON::ParserError => e
              puts "Warning: Failed to parse library_versions.json: #{e.message}"
              nil
            end
          else
            nil
          end
        end
        
        def get_library_config(library_name, current_version)
          versions_config = load_library_versions
          return nil unless versions_config
          
          version_mappings = versions_config['version_mappings'] || {}
          
          # Try exact version match first
          if version_mappings[current_version] && version_mappings[current_version][library_name]
            return version_mappings[current_version][library_name]
          end
          
          # Fallback to default
          if version_mappings['default'] && version_mappings['default'][library_name]
            return version_mappings['default'][library_name]
          end
          
          nil
        end

        def add_all_packages
          puts "Checking required packages..."
          
          # Get current version
          current_version = get_current_version
          puts "Using binding_builder version: #{current_version}"
          
          # Check existing packages
          existing_packages = @project.root_object.package_references.map(&:repository_url)
          
          # Determine packages to add
          packages_to_add = []
          
          # SwiftJsonUI
          if !existing_packages.any? { |url| url.include?("SwiftJsonUI") }
            swiftjsonui_config = get_library_config("SwiftJsonUI", current_version)
            
            if swiftjsonui_config
              package_info = {
                name: "SwiftJsonUI",
                url: swiftjsonui_config['git'] || "https://github.com/Tai-Kimura/SwiftJsonUI",
                requirement: {}
              }
              
              # Version requirement based on configuration
              if swiftjsonui_config['branch']
                package_info[:requirement][:branch] = swiftjsonui_config['branch']
              elsif swiftjsonui_config['from']
                package_info[:requirement][:minimum_version] = swiftjsonui_config['from']
                package_info[:requirement][:kind] = :up_to_next_major
              elsif swiftjsonui_config['exact']
                package_info[:requirement][:exact_version] = swiftjsonui_config['exact']
              else
                package_info[:requirement][:minimum_version] = "6.0.0"
                package_info[:requirement][:kind] = :up_to_next_major
              end
              
              packages_to_add << package_info
            else
              # Fallback if no config found
              packages_to_add << {
                name: "SwiftJsonUI",
                url: "https://github.com/Tai-Kimura/SwiftJsonUI",
                requirement: { minimum_version: "6.0.0", kind: :up_to_next_major }
              }
            end
          end
          
          # SimpleApiNetwork (only if use_network is true)
          use_network = Core::ConfigManager.get_use_network
          
          if use_network && !existing_packages.any? { |url| url.include?("SimpleApiNetwork") }
            packages_to_add << {
              name: "SimpleApiNetwork",
              url: "https://github.com/Tai-Kimura/SimpleApiNetwork",
              requirement: { minimum_version: "2.1.8", kind: :up_to_next_major }
            }
          end
          
          if packages_to_add.empty?
            puts "All required packages already exist in the project"
            return
          end
          
          puts "Adding packages: #{packages_to_add.map { |p| p[:name] }.join(', ')}"
          
          # Add packages using Xcodeproj API
          add_packages_with_xcodeproj(packages_to_add)
        end

        def add_packages_with_xcodeproj(packages)
          packages.each do |package_info|
            puts "Adding package: #{package_info[:name]}"
            
            # Create package reference
            package_ref = @project.new(Xcodeproj::Project::Object::XCRemoteSwiftPackageReference)
            package_ref.repositoryURL = package_info[:url]
            
            # Set requirement
            requirement = package_info[:requirement]
            if requirement[:branch]
              package_ref.requirement = {
                'branch' => requirement[:branch],
                'kind' => 'branch'
              }
            elsif requirement[:exact_version]
              package_ref.requirement = {
                'kind' => 'exactVersion',
                'version' => requirement[:exact_version]
              }
            elsif requirement[:minimum_version]
              package_ref.requirement = {
                'kind' => 'upToNextMajorVersion',
                'minimumVersion' => requirement[:minimum_version]
              }
            end
            
            # Add to root object
            @project.root_object.package_references ||= []
            @project.root_object.package_references << package_ref
            
            # Add product dependency to main target
            main_target = @project.targets.find { |t| t.product_type == 'com.apple.product-type.application' }
            if main_target
              # Create product dependency
              product_dependency = @project.new(Xcodeproj::Project::Object::XCSwiftPackageProductDependency)
              product_dependency.package = package_ref
              product_dependency.product_name = package_info[:name]
              
              # Add to target dependencies
              main_target.package_product_dependencies ||= []
              main_target.package_product_dependencies << product_dependency
              
              # Add to frameworks build phase
              frameworks_phase = main_target.frameworks_build_phase
              if frameworks_phase
                build_file = @project.new(Xcodeproj::Project::Object::PBXBuildFile)
                build_file.product_ref = product_dependency
                frameworks_phase.files << build_file
              end
            end
          end
          
          puts "Successfully added #{packages.length} packages"
        end
      end
    end
  end
end