require 'listen'
require 'pathname'

module SwiftUIBuilder
  module Commands
    class Watch
      attr_reader :options, :config
      
      def initialize(options, config)
        @options = options
        @config = config
      end
      
      def execute
        input_dir = options[:input]
        output_dir = options[:output]
        
        unless Dir.exist?(input_dir)
          raise "Input directory not found: #{input_dir}"
        end
        
        puts "Watching for changes in: #{input_dir}"
        puts "Output directory: #{output_dir}"
        puts "Press Ctrl+C to stop"
        
        # Create listener
        listener = Listen.to(input_dir, only: /\.json$/) do |modified, added, removed|
          process_changes(modified + added, input_dir, output_dir)
          process_removals(removed, input_dir, output_dir)
        end
        
        # Start listening
        listener.start
        
        # Keep the process running
        begin
          sleep
        rescue Interrupt
          puts "\nStopping watch..."
          listener.stop
        end
      end
      
      private
      
      def process_changes(files, input_dir, output_dir)
        return if files.empty?
        
        generate_command = Generate.new(options.dup, config)
        
        files.each do |file|
          begin
            # Calculate relative path
            relative_path = Pathname.new(file).relative_path_from(Pathname.new(input_dir))
            
            # Create output path
            output_file = File.join(output_dir, relative_path.to_s.sub(/\.json$/, '.swift'))
            
            # Ensure output directory exists
            FileUtils.mkdir_p(File.dirname(output_file))
            
            # Set options for generate command
            generate_options = options.dup
            generate_options[:output] = output_file
            generate_options[:include_path] = File.dirname(file)
            
            # Generate the file
            generate_command = Generate.new(generate_options, config)
            generate_command.execute(file)
            
            puts "[#{Time.now.strftime('%H:%M:%S')}] Updated: #{relative_path}"
          rescue => e
            puts "[#{Time.now.strftime('%H:%M:%S')}] Error processing #{file}: #{e.message}"
          end
        end
      end
      
      def process_removals(files, input_dir, output_dir)
        return if files.empty?
        
        files.each do |file|
          begin
            # Calculate relative path
            relative_path = Pathname.new(file).relative_path_from(Pathname.new(input_dir))
            
            # Create output path
            output_file = File.join(output_dir, relative_path.to_s.sub(/\.json$/, '.swift'))
            
            # Remove the output file if it exists
            if File.exist?(output_file)
              File.delete(output_file)
              puts "[#{Time.now.strftime('%H:%M:%S')}] Removed: #{relative_path.to_s.sub(/\.json$/, '.swift')}"
            end
          rescue => e
            puts "[#{Time.now.strftime('%H:%M:%S')}] Error removing #{output_file}: #{e.message}"
          end
        end
      end
    end
  end
end