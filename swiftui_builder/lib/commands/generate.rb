require 'json'
require 'pathname'

module SwiftUIBuilder
  module Commands
    class Generate
      attr_reader :options, :config
      
      def initialize(options, config)
        @options = options
        @config = config
      end
      
      def execute(file)
        unless File.exist?(file)
          raise "File not found: #{file}"
        end
        
        # Load the converter
        converter_path = File.expand_path('../../../json_to_swiftui_converter.rb', __FILE__)
        require converter_path
        
        # Read the JSON file
        json_content = File.read(file)
        json_data = JSON.parse(json_content)
        
        # Get include path
        include_path = options[:include_path] || config['include_path'] || File.dirname(file)
        
        # Create converter instance
        converter = JsonToSwiftUIConverter.new
        
        # Process includes
        if json_data['include']
          json_data = converter.process_includes(json_data, include_path)
        end
        
        # Generate SwiftUI code based on type
        case options[:type]
        when 'component'
          swift_code = generate_component(json_data, converter)
        when 'dynamic'
          swift_code = generate_dynamic(json_data, converter)
        else
          swift_code = generate_view(json_data, converter)
        end
        
        # Determine output path
        output_path = options[:output] || "#{file.sub(/\.json$/, '')}.swift"
        
        # Write output
        File.write(output_path, swift_code)
        puts "Generated: #{output_path}"
      end
      
      private
      
      def generate_view(json_data, converter)
        view_name = json_data['name'] || 'GeneratedView'
        
        <<~SWIFT
        import SwiftUI
        import SwiftJsonUI
        
        struct #{view_name}: View {
            var body: some View {
        #{converter.convert_component(json_data, 2)}
            }
        }
        
        struct #{view_name}_Previews: PreviewProvider {
            static var previews: some View {
                #{view_name}()
            }
        }
        SWIFT
      end
      
      def generate_component(json_data, converter)
        component_name = json_data['name'] || 'GeneratedComponent'
        
        <<~SWIFT
        import SwiftUI
        
        struct #{component_name}: View {
            // Add properties as needed
            
            var body: some View {
        #{converter.convert_component(json_data, 2)}
            }
        }
        SWIFT
      end
      
      def generate_dynamic(json_data, converter)
        view_name = json_data['name'] || 'DynamicGeneratedView'
        json_string = JSON.pretty_generate(json_data).gsub('"', '\\"').gsub("\n", '\n')
        
        <<~SWIFT
        import SwiftUI
        import SwiftJsonUI
        
        struct #{view_name}: View {
            let jsonString = \"\"\"
        #{JSON.pretty_generate(json_data)}
            \"\"\"
            
            var body: some View {
                if let data = jsonString.data(using: .utf8),
                   let component = try? JSONDecoder().decode(DynamicComponent.self, from: data) {
                    DynamicView(component: component)
                } else {
                    Text("Failed to load component")
                }
            }
        }
        
        struct #{view_name}_Previews: PreviewProvider {
            static var previews: some View {
                #{view_name}()
            }
        }
        SWIFT
      end
    end
  end
end