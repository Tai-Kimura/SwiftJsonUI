#!/usr/bin/env ruby

require "fileutils"
require "pathname"
require "json"
require 'xcodeproj'
require_relative '../project_finder'
require_relative '../config_manager'
require_relative '../xcode_target_helper'

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
          # Check .sjui-version file in project root first
          project_dir = File.dirname(File.dirname(@project_file_path))
          sjui_version_file = File.join(project_dir, '.sjui-version')
          
          if File.exist?(sjui_version_file)
            version = File.read(sjui_version_file).strip
            puts "Using version from .sjui-version: #{version}" unless version.empty?
            return version unless version.empty?
          end
          
          # Check VERSION file (created by installer)
          # __FILE__ is .../sjui_tools/lib/core/setup/library_setup.rb
          # We need to go up to sjui_tools directory
          base_dir = File.expand_path('../../../..', __FILE__)  # Goes up to sjui_tools
          version_file = File.join(base_dir, 'VERSION')
          
          puts "Checking VERSION file at: #{version_file}"
          if File.exist?(version_file)
            version = File.read(version_file).strip
            puts "Using version from VERSION file: #{version}" unless version.empty?
            return version unless version.empty?
          else
            puts "VERSION file not found at: #{version_file}"
          end
          
          # Check git branch as fallback
          begin
            git_branch = `git rev-parse --abbrev-ref HEAD 2>/dev/null`.strip
            unless git_branch.empty?
              puts "Using version from git branch: #{git_branch}"
              return git_branch
            end
          rescue
            # Git command failed, continue with other methods
          end
          
          # Fallback to 7.0.0-beta
          puts "Using fallback version: 7.0.0-beta"
          "7.0.0-beta"
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
          puts "Using sjui_tools version: #{current_version}"
          
          # Check existing packages
          existing_packages = @project.root_object.package_references.map(&:repository_url)
          
          # Determine packages to add
          packages_to_add = []
          
          # SwiftJsonUI - always check/update even if exists
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
              # For alpha versions, also get the latest commit
              if current_version.include?('alpha')
                begin
                  latest_commit = `git ls-remote https://github.com/Tai-Kimura/SwiftJsonUI refs/heads/#{swiftjsonui_config['branch']} 2>/dev/null`.strip.split("\t").first
                  if latest_commit && !latest_commit.empty?
                    package_info[:requirement][:revision] = latest_commit
                    package_info[:requirement].delete(:branch)
                    puts "Using latest commit for alpha version: #{latest_commit}"
                  end
                rescue
                  # If git command fails, fall back to branch
                end
              end
            elsif swiftjsonui_config['from']
              package_info[:requirement][:minimum_version] = swiftjsonui_config['from']
              package_info[:requirement][:kind] = :up_to_next_major
            elsif swiftjsonui_config['exact']
              package_info[:requirement][:exact_version] = swiftjsonui_config['exact']
            else
              # Default to 7.0.0-beta branch
              package_info[:requirement][:branch] = "7.0.0-beta"
            end
              
            packages_to_add << package_info
          else
            # Fallback if no config found
            puts "No config found for SwiftJsonUI, using default"
            packages_to_add << {
              name: "SwiftJsonUI",
              url: "https://github.com/Tai-Kimura/SwiftJsonUI",
              requirement: { branch: "7.0.0-beta" }
            }
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
          # Ensure workspace directory structure exists
          ensure_workspace_structure
          
          packages.each do |package_info|
            # Check if package already exists and update it
            existing_package = @project.root_object.package_references.find { |p| 
              p.repository_url&.include?(package_info[:name])
            }
            
            if existing_package
              puts "Updating existing package: #{package_info[:name]}"
              # Update the requirement
              requirement = package_info[:requirement]
              if requirement[:branch]
                existing_package.requirement = {
                  'branch' => requirement[:branch],
                  'kind' => 'branch'
                }
                puts "  Updated to branch: #{requirement[:branch]}"
              elsif requirement[:exact_version]
                existing_package.requirement = {
                  'kind' => 'exactVersion',
                  'version' => requirement[:exact_version]
                }
              elsif requirement[:from_version]
                existing_package.requirement = {
                  'kind' => 'upToNextMajorVersion',
                  'minimumVersion' => requirement[:from_version]
                }
              end
              next  # Skip to next package
            end
            
            puts "Adding new package: #{package_info[:name]}"
            
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
            
            # Add product dependency to all app targets
            app_targets = XcodeTargetHelper.get_app_targets(@project)
            app_targets.each do |target|
              # Create product dependency
              product_dependency = @project.new(Xcodeproj::Project::Object::XCSwiftPackageProductDependency)
              product_dependency.package = package_ref
              product_dependency.product_name = package_info[:name]
              
              # Add to target dependencies
              target.package_product_dependencies ||= []
              target.package_product_dependencies << product_dependency
              
              # Add to frameworks build phase
              frameworks_phase = target.frameworks_build_phase
              if frameworks_phase
                build_file = @project.new(Xcodeproj::Project::Object::PBXBuildFile)
                build_file.product_ref = product_dependency
                frameworks_phase.files << build_file
              end
            end
          end
          
          # Save the project after adding packages
          puts "Saving project..."
          @project.save
          puts "Project saved."
          
          puts "Successfully added #{packages.length} packages"
        end
        
        def ensure_workspace_structure
          # Get workspace path
          project_dir = File.dirname(@project.path)
          project_name = File.basename(@project.path, '.xcodeproj')
          workspace_path = File.join(project_dir, "#{project_name}.xcworkspace")
          
          puts "Debug: Ensuring workspace structure at: #{workspace_path}"
          puts "Debug: Project path: #{@project.path}"
          puts "Debug: Project dir: #{project_dir}"
          puts "Debug: Project name: #{project_name}"
          
          # Create workspace directory if it doesn't exist
          unless Dir.exist?(workspace_path)
            FileUtils.mkdir_p(workspace_path)
            puts "Created workspace directory: #{workspace_path}"
          else
            puts "Debug: Workspace already exists: #{workspace_path}"
          end
          
          # Create workspace directory structure
          shared_data_path = File.join(workspace_path, 'xcshareddata')
          swiftpm_path = File.join(shared_data_path, 'swiftpm')
          
          puts "Debug: Shared data path: #{shared_data_path}"
          puts "Debug: SwiftPM path: #{swiftpm_path}"
          
          # Check if directories exist before creating
          unless Dir.exist?(shared_data_path)
            FileUtils.mkdir_p(shared_data_path)
            puts "Created shared data directory: #{shared_data_path}"
          else
            puts "Debug: Shared data directory already exists"
          end
          
          unless Dir.exist?(swiftpm_path)
            FileUtils.mkdir_p(swiftpm_path)
            puts "Created SPM directory: #{swiftpm_path}"
          else
            puts "Debug: SPM directory already exists"
          end
          
          # List contents of workspace directory
          puts "Debug: Workspace contents:"
          Dir.glob("#{workspace_path}/**/*").each do |file|
            puts "  - #{file}"
          end
          
          # Verify the directory was created with proper permissions
          if Dir.exist?(swiftpm_path)
            puts "Verified: SPM directory exists at #{swiftpm_path}"
            # Check if directory is writable
            if File.writable?(swiftpm_path)
              puts "Debug: SPM directory is writable"
            else
              puts "ERROR: SPM directory is not writable!"
            end
          else
            puts "ERROR: Failed to create SPM directory at #{swiftpm_path}"
          end
          
          # Create empty Package.resolved if it doesn't exist
          package_resolved_path = File.join(swiftpm_path, 'Package.resolved')
          unless File.exist?(package_resolved_path)
            initial_resolved = {
              "object" => {
                "pins" => []
              },
              "version" => 1
            }
            File.write(package_resolved_path, JSON.pretty_generate(initial_resolved))
            puts "Created Package.resolved file"
          end
          
          # Create workspace contents.xcworkspacedata if it doesn't exist
          workspace_data_path = File.join(workspace_path, 'contents.xcworkspacedata')
          unless File.exist?(workspace_data_path)
            workspace_xml = <<~XML
              <?xml version="1.0" encoding="UTF-8"?>
              <Workspace
                 version = "1.0">
                 <FileRef
                    location = "self:">
                 </FileRef>
              </Workspace>
            XML
            File.write(workspace_data_path, workspace_xml)
            puts "Created workspace contents file"
          end
        end
      end
    end
  end
end