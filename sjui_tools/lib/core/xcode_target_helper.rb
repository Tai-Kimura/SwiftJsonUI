module SjuiTools
  module Core
    module XcodeTargetHelper
      # アプリターゲット（テスト以外）を取得するヘルパーメソッド
      def self.get_app_targets(project)
        # configからproject_nameを取得
        config = ConfigManager.load_config
        project_name = config['project_name'] || ''
        
        puts "Debug: Looking for app targets..."
        puts "Debug: Project name from config: '#{project_name}'"
        puts "Debug: Total targets in project: #{project.targets.count}"
        
        # すべてのターゲットをログ出力
        project.targets.each do |target|
          puts "Debug: Target '#{target.name}' - Type: #{target.product_type}"
        end
        
        # project_nameを含むアプリターゲット（テスト以外）を取得
        app_targets = project.targets.select do |target|
          is_app_target = target.product_type == 'com.apple.product-type.application'
          includes_project_name = project_name.empty? || target.name.include?(project_name)
          # Check if it's a test target by looking at the product type, not just the name
          is_test_target = target.product_type.include?('test')
          
          puts "Debug: Target '#{target.name}' - is_app: #{is_app_target}, includes_name: #{includes_project_name}, is_test: #{is_test_target}"
          
          is_app_target && includes_project_name && !is_test_target
        end
        
        if app_targets.empty?
          puts "Warning: No matching app targets found"
          puts "  - Looking for targets containing: '#{project_name}'"
          puts "  - With product type: 'com.apple.product-type.application'"
          puts "  - Excluding targets with test product types"
        else
          puts "Found #{app_targets.count} app target(s): #{app_targets.map(&:name).join(', ')}"
        end
        
        app_targets
      end
    end
  end
end