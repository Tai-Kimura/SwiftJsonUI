# frozen_string_literal: true

require 'listen'

module SjuiTools
  module Core
    class FileWatcher
      attr_reader :listener

      def initialize(directories, extensions: ['json'], &block)
        @directories = Array(directories).select { |d| Dir.exist?(d) }
        @extensions = extensions
        @callback = block
        @listener = nil
      end

      def start
        return if @directories.empty?
        
        options = {
          only: file_patterns,
          wait_for_delay: 0.5,
          relative: true
        }
        
        @listener = Listen.to(*@directories, options) do |modified, added, removed|
          handle_changes(modified, added, removed)
        end
        
        @listener.start
        puts "Watching directories: #{@directories.join(', ')}"
        puts "For file types: #{@extensions.join(', ')}"
      end

      def stop
        @listener&.stop
      end

      private

      def file_patterns
        @extensions.map { |ext| /\.#{Regexp.escape(ext)}$/ }
      end

      def handle_changes(modified, added, removed)
        all_changes = (modified + added + removed).uniq
        
        all_changes.each do |file|
          next unless should_process?(file)
          
          change_type = if removed.include?(file)
            :removed
          elsif added.include?(file)
            :added
          else
            :modified
          end
          
          @callback.call(file, change_type) if @callback
        end
      end

      def should_process?(file)
        return false if file.start_with?('.')
        @extensions.any? { |ext| file.end_with?(".#{ext}") }
      end
    end
  end
end