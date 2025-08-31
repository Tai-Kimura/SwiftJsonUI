# frozen_string_literal: true

module SjuiTools
  module SwiftUI
    module Helpers
      module StringManagerHelper
        def get_text_with_string_manager(text_content)
          # Remove quotes if present
          text_without_quotes = text_content.gsub(/^\"|\"|^'|'$/, '')
          
          # Check if it's a binding (starts with @{)
          return text_content if text_without_quotes.match?(/^@\{.*\}$/)
          
          # Check if it's snake_case
          if text_without_quotes.match?(/^[a-z]+(_[a-z0-9]+)*$/)
            # Use .localized() extension for snake_case strings
            return "\"#{text_without_quotes}\".localized()"
          end
          
          # Return original text content for non-snake_case strings
          text_content
        end
        
      end
    end
  end
end