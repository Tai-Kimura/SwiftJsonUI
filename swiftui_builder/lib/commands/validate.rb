require 'json'
require 'set'

module SwiftUIBuilder
  module Commands
    class Validate
      attr_reader :options, :config
      
      # Valid component types
      VALID_TYPES = %w[
        View ScrollView HStack VStack ZStack Text Button Image Icon
        TextField TextView SelectBox Collection Table List Switch
        NavigationView TabView Spacer Divider ProgressView
        LazyVStack LazyHStack LazyVGrid LazyHGrid Form Section
        Toggle Slider Stepper Picker DatePicker Link Label
        NetworkImage IconLabel
      ].freeze
      
      # Required attributes for each type
      REQUIRED_ATTRIBUTES = {
        'Text' => ['text'],
        'Button' => ['text'],
        'Image' => ['name'],
        'Icon' => ['name'],
        'TextField' => [],
        'TextView' => [],
        'Collection' => ['items'],
        'Table' => ['items'],
        'List' => ['items']
      }.freeze
      
      # Valid attributes from Wiki
      VALID_ATTRIBUTES = %w[
        type id width height margin padding background cornerRadius
        shadow borderWidth borderColor opacity rotation scaleX scaleY
        translationX translationY text font fontSize fontColor fontWeight
        alignment textAlignment numberOfLines minimumScaleFactor
        hint hintColor hintFont hideOnFocused containerInset flexible
        minHeight maxHeight items binding data onClick onLongPress
        onAppear onDisappear onChange onSubmit onToggle onSelect
        action url placeholder contentMode aspectRatio child children
        spacing distribution axis showsIndicators clipsToBounds
        selectedIndex tabs title icon tintColor symbolRenderingMode
        variableValue
      ].freeze
      
      def initialize(options, config)
        @options = options
        @config = config
        @errors = []
        @warnings = []
      end
      
      def execute(file)
        unless File.exist?(file)
          raise "File not found: #{file}"
        end
        
        begin
          json_content = File.read(file)
          json_data = JSON.parse(json_content)
        rescue JSON::ParserError => e
          puts "Invalid JSON: #{e.message}"
          return false
        end
        
        # Validate the component structure
        validate_component(json_data, [])
        
        # Print results
        if @errors.empty? && @warnings.empty?
          puts "✓ Validation passed"
          return true
        end
        
        unless @errors.empty?
          puts "Errors:"
          @errors.each { |error| puts "  ✗ #{error}" }
        end
        
        unless @warnings.empty?
          puts "\nWarnings:"
          @warnings.each { |warning| puts "  ⚠ #{warning}" }
        end
        
        @errors.empty?
      end
      
      private
      
      def validate_component(component, path)
        return unless component.is_a?(Hash)
        
        current_path = path + [component['type'] || 'unknown']
        
        # Check type
        unless component['type']
          @errors << "#{path_string(current_path)}: Missing 'type' attribute"
          return
        end
        
        unless VALID_TYPES.include?(component['type'])
          if options[:strict]
            @errors << "#{path_string(current_path)}: Invalid type '#{component['type']}'"
          else
            @warnings << "#{path_string(current_path)}: Unknown type '#{component['type']}'"
          end
        end
        
        # Check required attributes
        if REQUIRED_ATTRIBUTES[component['type']]
          REQUIRED_ATTRIBUTES[component['type']].each do |attr|
            unless component[attr]
              @errors << "#{path_string(current_path)}: Missing required attribute '#{attr}'"
            end
          end
        end
        
        # Check for unknown attributes in strict mode
        if options[:strict]
          component.keys.each do |key|
            next if key == 'include' || key == 'variables'
            unless VALID_ATTRIBUTES.include?(key)
              @warnings << "#{path_string(current_path)}: Unknown attribute '#{key}'"
            end
          end
        end
        
        # Validate specific attribute values
        validate_dimensions(component, current_path)
        validate_colors(component, current_path)
        validate_numbers(component, current_path)
        
        # Validate children
        if component['child']
          if component['child'].is_a?(Array)
            component['child'].each_with_index do |child, index|
              validate_component(child, current_path + ["child[#{index}]"])
            end
          else
            validate_component(component['child'], current_path + ['child'])
          end
        end
        
        if component['children']
          if component['children'].is_a?(Array)
            component['children'].each_with_index do |child, index|
              validate_component(child, current_path + ["children[#{index}]"])
            end
          else
            @errors << "#{path_string(current_path)}: 'children' must be an array"
          end
        end
      end
      
      def validate_dimensions(component, path)
        %w[width height].each do |attr|
          next unless component[attr]
          value = component[attr]
          
          unless value.is_a?(Numeric) || %w[matchParent wrapContent].include?(value)
            @errors << "#{path_string(path)}: Invalid #{attr} value '#{value}'"
          end
        end
      end
      
      def validate_colors(component, path)
        color_attrs = %w[background fontColor borderColor hintColor tintColor]
        color_attrs.each do |attr|
          next unless component[attr]
          value = component[attr]
          
          unless value.match?(/^#[0-9A-Fa-f]{6}$|^#[0-9A-Fa-f]{8}$/)
            @warnings << "#{path_string(path)}: Invalid color format for #{attr}: '#{value}'"
          end
        end
      end
      
      def validate_numbers(component, path)
        number_attrs = %w[fontSize cornerRadius borderWidth opacity rotation
                         scaleX scaleY translationX translationY spacing
                         minHeight maxHeight minimumScaleFactor]
        
        number_attrs.each do |attr|
          next unless component[attr]
          value = component[attr]
          
          unless value.is_a?(Numeric)
            @errors << "#{path_string(path)}: #{attr} must be a number, got '#{value}'"
          end
        end
      end
      
      def path_string(path)
        path.join(' > ')
      end
    end
  end
end