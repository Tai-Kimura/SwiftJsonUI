# frozen_string_literal: true

require 'optparse'
require_relative '../../core/config_manager'
require_relative '../../core/project_finder'

module SjuiTools
  module CLI
    module Commands
      class Generate
        SUBCOMMANDS = {
          'view' => 'Generate a new view with JSON and binding',
          'partial' => 'Generate a partial view', 
          'collection' => 'Generate a collection view',
          'binding' => 'Generate binding file'
        }.freeze

        def run(args)
          subcommand = args.shift
          
          if subcommand.nil? || subcommand == 'help'
            show_help
            return
          end
          
          unless SUBCOMMANDS.key?(subcommand)
            puts "Unknown generate command: #{subcommand}"
            show_help
            exit 1
          end
          
          # Detect mode
          mode = Core::ConfigManager.detect_mode
          
          case subcommand
          when 'view'
            generate_view(args, mode)
          when 'partial'
            generate_partial(args, mode)
          when 'collection'
            generate_collection(args, mode)
          when 'binding'
            generate_binding(args, mode)
          end
        end

        private

        def generate_view(args, mode)
          options = parse_view_options(args)
          name = args.shift
          
          if name.nil? || name.empty?
            puts "Error: View name is required"
            puts "Usage: sjui generate view <name> [options]"
            exit 1
          end
          
          # Setup project paths
          unless Core::ProjectFinder.setup_paths
            puts "Error: Could not find project file (.xcodeproj or Package.swift)"
            exit 1
          end
          
          case mode
          when 'binding'
            require_relative '../../binding/xcode_project/generators/view_generator'
            generator = SjuiTools::Binding::Generators::ViewGenerator.new(name, options)
            generator.generate
          when 'swiftui'
            require_relative '../../swiftui/converter'
            puts "Generating SwiftUI view: #{name}"
            # TODO: Implement SwiftUI view generation
          else
            puts "Error: Unknown mode: #{mode}"
            exit 1
          end
        end

        def generate_partial(args, mode)
          name = args.shift
          
          if name.nil? || name.empty?
            puts "Error: Partial name is required"
            puts "Usage: sjui generate partial <name>"
            exit 1
          end
          
          case mode
          when 'binding'
            require_relative '../../binding/xcode_project/generators/partial_generator'
            project_file = Core::ProjectFinder.find_project_file
            generator = SjuiTools::Binding::Generators::PartialGenerator.new(project_file)
            generator.generate(name)
          when 'swiftui'
            puts "Generating SwiftUI partial: #{name}"
            # TODO: Implement SwiftUI partial generation
          end
        end

        def generate_collection(args, mode)
          name = args.shift
          
          if name.nil? || name.empty?
            puts "Error: Collection name is required"
            puts "Usage: sjui generate collection <folder/name>"
            exit 1
          end
          
          case mode
          when 'binding'
            require_relative '../../binding/xcode_project/generators/collection_generator'
            project_file = Core::ProjectFinder.find_project_file
            generator = SjuiTools::Binding::Generators::CollectionGenerator.new(project_file)
            generator.generate(name)
          else
            puts "Collection generation is only available in binding mode"
            exit 1
          end
        end

        def generate_binding(args, mode)
          name = args.shift
          
          if name.nil? || name.empty?
            puts "Error: Binding name is required"
            puts "Usage: sjui generate binding <name>"
            exit 1
          end
          
          if mode != 'binding'
            puts "Binding generation is only available in binding mode"
            exit 1
          end
          
          require_relative '../../binding/xcode_project/generators/binding_generator'
          generator = SjuiTools::Binding::Generators::BindingGenerator.new(name)
          generator.generate
        end

        def parse_view_options(args)
          options = {
            root: false,
            mode: nil
          }
          
          OptionParser.new do |opts|
            opts.on('--root', 'Generate root view controller') do
              options[:root] = true
            end
            
            opts.on('--mode MODE', 'Override mode (binding, swiftui, dynamic)') do |mode|
              options[:mode] = mode
            end
          end.parse!(args)
          
          options
        end

        def show_help
          puts "Usage: sjui generate SUBCOMMAND [options]"
          puts
          puts "Subcommands:"
          SUBCOMMANDS.each do |cmd, desc|
            puts "  #{cmd.ljust(12)} #{desc}"
          end
          puts
          puts "Examples:"
          puts "  sjui g view HomeView           # Generate a view"
          puts "  sjui g view RootView --root    # Generate root view"
          puts "  sjui g partial Header          # Generate a partial"
          puts "  sjui g collection Post/Cell    # Generate collection cell"
          puts "  sjui g binding CustomBinding   # Generate binding file"
        end
      end
    end
  end
end