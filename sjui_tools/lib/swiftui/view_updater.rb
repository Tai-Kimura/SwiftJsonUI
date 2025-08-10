# frozen_string_literal: true

module SjuiTools
  module SwiftUI
    class ViewUpdater
      def update_generated_body(swift_file_path, new_body_code)
        unless File.exist?(swift_file_path)
          puts "Error: Swift file not found: #{swift_file_path}"
          return false
        end
        
        # GeneratedViewファイルを完全に再生成する
        view_name = File.basename(File.dirname(swift_file_path))
        json_name = view_name.gsub(/([A-Z])/, '_\1').downcase.gsub(/^_/, '')
        
        # GeneratedViewファイルの内容を完全に作り直す
        content = <<~SWIFT
        import SwiftUI
        import SwiftJsonUI
        import Combine

        struct #{view_name}GeneratedView: View {
            @EnvironmentObject var viewModel: #{view_name}ViewModel
            @StateObject private var dynamicViewModel = DynamicViewModel(jsonName: "#{json_name}")
            
            var body: some View {
                if ViewSwitcher.isDynamicMode {
                    DynamicView(jsonName: "#{json_name}", viewId: "#{json_name}_view")
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