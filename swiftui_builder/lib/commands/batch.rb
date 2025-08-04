require 'pathname'
require 'fileutils'

module SwiftUIBuilder
  module Commands
    class Batch
      attr_reader :options, :config
      
      def initialize(options, config)
        @options = options
        @config = config
      end
      
      def execute
        input_dir = options[:input]
        output_dir = options[:output]
        pattern = options[:pattern] || '**/*.json'
        
        unless Dir.exist?(input_dir)
          raise "Input directory not found: #{input_dir}"
        end
        
        # Create output directory if it doesn't exist
        FileUtils.mkdir_p(output_dir)
        
        # Find all JSON files matching pattern
        files = Dir.glob(File.join(input_dir, pattern))
        
        if files.empty?
          puts "No files found matching pattern: #{pattern}"
          return
        end
        
        puts "Found #{files.length} files to process"
        
        # Process each file
        generate_command = Generate.new(options.dup, config)
        success_count = 0
        error_count = 0
        
        files.each do |file|
          begin
            # Calculate relative path from input directory
            relative_path = Pathname.new(file).relative_path_from(Pathname.new(input_dir))
            
            # Create output path maintaining directory structure
            output_file = File.join(output_dir, relative_path.to_s.sub(/\.json$/, '.swift'))
            
            # Ensure output directory exists
            FileUtils.mkdir_p(File.dirname(output_file))
            
            # Set output option for generate command
            generate_options = options.dup
            generate_options[:output] = output_file
            generate_options[:include_path] = File.dirname(file)
            
            # Generate the file
            generate_command = Generate.new(generate_options, config)
            generate_command.execute(file)
            
            success_count += 1
          rescue => e
            puts "Error processing #{file}: #{e.message}"
            error_count += 1
          end
        end
        
        puts "\nBatch generation complete:"
        puts "  Success: #{success_count}"
        puts "  Errors: #{error_count}"
      end
    end
  end
end