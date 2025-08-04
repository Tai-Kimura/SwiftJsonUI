# frozen_string_literal: true

module SjuiTools
  module SwiftUI
    class ActionManager
      def initialize
        @actions = {}
        @action_counter = 0
      end
      
      # Register an action and return its handler name
      def register_action(action_name, component_type = nil)
        return nil if action_name.nil? || action_name.empty?
        
        # Create a unique handler name if needed
        handler_name = sanitize_action_name(action_name)
        
        # Store action info
        @actions[handler_name] = {
          original_name: action_name,
          component_type: component_type,
          handler_name: handler_name
        }
        
        handler_name
      end
      
      # Generate action handler functions
      def generate_action_handlers
        return [] if @actions.empty?
        
        handlers = []
        
        @actions.each do |handler_name, info|
          handlers << generate_handler(info)
        end
        
        handlers
      end
      
      # Get all registered actions
      def actions
        @actions
      end
      
      private
      
      def sanitize_action_name(action_name)
        # Remove special characters and convert to camelCase
        sanitized = action_name.gsub(/[^a-zA-Z0-9_]/, '')
        
        # Ensure it starts with a letter
        unless sanitized.match?(/^[a-zA-Z]/)
          sanitized = "action#{sanitized}"
        end
        
        # Make unique if needed
        base_name = sanitized
        counter = 1
        while @actions.key?(sanitized)
          sanitized = "#{base_name}#{counter}"
          counter += 1
        end
        
        sanitized
      end
      
      def generate_handler(info)
        handler_lines = []
        
        handler_lines << "func #{info[:handler_name]}() {"
        handler_lines << "    // Action: #{info[:original_name]}"
        handler_lines << "    // Component type: #{info[:component_type]}" if info[:component_type]
        handler_lines << "    print(\"Action triggered: #{info[:original_name]}\")"
        handler_lines << "    "
        handler_lines << "    // TODO: Implement your action logic here"
        handler_lines << "    // Example implementations:"
        
        case info[:component_type]
        when 'button'
          handler_lines << "    // - Navigate to another view"
          handler_lines << "    // - Update state variables"
          handler_lines << "    // - Call API endpoints"
          handler_lines << "    // - Show alerts or sheets"
        when 'textfield'
          handler_lines << "    // - Validate input"
          handler_lines << "    // - Update model data"
          handler_lines << "    // - Trigger search or filter"
        when 'slider'
          handler_lines << "    // - Update related UI elements"
          handler_lines << "    // - Save preference values"
          handler_lines << "    // - Trigger calculations"
        when 'image'
          handler_lines << "    // - Show fullscreen image"
          handler_lines << "    // - Navigate to detail view"
          handler_lines << "    // - Trigger image picker"
        when 'radio'
          handler_lines << "    // - Update selection state"
          handler_lines << "    // - Filter or sort data"
          handler_lines << "    // - Update user preferences"
        end
        
        handler_lines << "}"
        handler_lines << ""
        
        handler_lines
      end
    end
  end
end