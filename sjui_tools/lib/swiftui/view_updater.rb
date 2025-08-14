# frozen_string_literal: true

module SjuiTools
  module SwiftUI
    class ViewUpdater
      def update_generated_body(swift_file_path, new_body_code)
        unless File.exist?(swift_file_path)
          puts "Error: Swift file not found: #{swift_file_path}"
          return false
        end
        
        # Extract actual struct names from the existing file
        existing_content = File.read(swift_file_path)
        
        # Extract the actual struct name
        struct_match = existing_content.match(/struct\s+(\w+GeneratedView)\s*:\s*View/)
        unless struct_match
          puts "Error: Could not find struct definition in #{swift_file_path}"
          return false
        end
        
        generated_view_name = struct_match[1]
        view_name = generated_view_name.sub(/GeneratedView$/, '')
        
        # Extract the actual ViewModel type from @EnvironmentObject declaration
        viewmodel_match = existing_content.match(/@EnvironmentObject\s+var\s+viewModel:\s+(\w+ViewModel)/)
        viewmodel_name = viewmodel_match ? viewmodel_match[1] : "#{view_name}ViewModel"
        
        # Convert view name to snake_case for JSON file name
        # Standard snake_case conversion
        json_name = view_name.gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2')
                             .gsub(/([a-z\d])([A-Z])/, '\1_\2')
                             .downcase
        
        # GeneratedViewファイルの内容を完全に作り直す
        content = <<~SWIFT
        import SwiftUI
        import SwiftJsonUI
        import Combine

        struct #{generated_view_name}: View {
            @EnvironmentObject var viewModel: #{viewmodel_name}
            @StateObject private var dynamicViewModel = DynamicViewModel(jsonName: "#{json_name}")
            
            var body: some View {
                if ViewSwitcher.isDynamicMode {
                    DynamicView(jsonName: "#{json_name}", viewId: "#{json_name}_view", data: viewModel.data.toDictionary())
                        .environmentObject(dynamicViewModel)
                } else {
                    // Generated SwiftUI code from #{json_name}.json
                    // This will be updated when you run 'sjui build'
                    // >>> GENERATED_CODE_START
        #{indent_body_code(new_body_code, "            ")}
                    // >>> GENERATED_CODE_END
                }
            }
        }
        SWIFT
        
        # ファイルに書き込む
        File.write(swift_file_path, content)
        return true
      end
      
      def convert_json_to_view(json_file_path)
        # Simple conversion for now - this should be enhanced with actual JSON parsing
        json_content = File.read(json_file_path)
        json = JSON.parse(json_content)
        
        # Generate SwiftUI code based on JSON structure
        generate_swiftui_code(json)
      end
      
      private
      
      def indent_body_code(code, indent)
        lines = code.split("\n")
        lines.map { |line| line.empty? ? line : "#{indent}#{line}" }.join("\n")
      end
      
      def generate_swiftui_code(json, indent_level = 0)
        indent = "    " * indent_level
        code = []
        
        view_type = json['type'] || 'View'
        
        case view_type
        when 'View'
          orientation = json['orientation'] || 'vertical'
          container = orientation == 'horizontal' ? 'HStack' : 'VStack'
          
          code << "#{container} {"
          
          # Process children
          if json['child']
            json['child'].each do |child|
              next if child['data'] # Skip data declarations
              child_code = generate_swiftui_code(child, indent_level + 1)
              code << child_code unless child_code.empty?
            end
          end
          
          code << "}"
          
          # Add modifiers
          modifiers = []
          modifiers << ".padding()" if json['padding']
          modifiers << ".background(Color(hex: \"#{json['background']}\"))" if json['background']
          
          if modifiers.any?
            code[0] = code[0] + "\n" + modifiers.map { |m| "#{indent}#{m}" }.join("\n")
          end
          
        when 'Label'
          text = json['text'] || ""
          # Handle data binding
          if text.start_with?('@{') && text.end_with?('}')
            binding = text[2...-1]
            code << "Text(viewModel.#{binding})"
          else
            code << "Text(\"#{text}\")"
          end
          
          # Add modifiers
          modifiers = []
          modifiers << ".font(.system(size: #{json['fontSize']}))" if json['fontSize']
          modifiers << ".foregroundColor(Color(hex: \"#{json['fontColor']}\"))" if json['fontColor']
          modifiers << ".padding(.top, #{json['topMargin']})" if json['topMargin']
          
          code[0] = code[0] + modifiers.map { |m| "\n#{indent}    #{m}" }.join("")
          
        when 'Button'
          text = json['text'] || "Button"
          action = json['onClick'] || "onTap"
          
          code << "Button(action: viewModel.#{action}) {"
          code << "    Text(\"#{text}\")"
          code << "}"
          
          # Add modifiers
          if json['topMargin']
            code[-1] = code[-1] + "\n#{indent}    .padding(.top, #{json['topMargin']})"
          end
        end
        
        code.map { |line| "#{indent}#{line}" }.join("\n")
      end
    end
  end
end