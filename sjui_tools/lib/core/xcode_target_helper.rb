module SjuiTools
  module Core
    module XcodeTargetHelper
      # アプリターゲット（テスト以外）を取得するヘルパーメソッド
      def self.get_app_targets(project)
        # configからproject_nameを取得
        config = ConfigManager.load_config
        project_name = config['project_name'] || ''
        
        # project_nameを含むアプリターゲット（テスト以外）を取得
        app_targets = project.targets.select do |target|
          is_app_target = target.product_type == 'com.apple.product-type.application'
          includes_project_name = project_name.empty? || target.name.include?(project_name)
          is_not_test = !target.name.include?('Test') && !target.name.include?('UITest')
          
          is_app_target && includes_project_name && is_not_test
        end
        
        if app_targets.empty?
          puts "Warning: No matching app targets found"
        else
          puts "Found #{app_targets.count} app target(s): #{app_targets.map(&:name).join(', ')}"
        end
        
        app_targets
      end
    end
  end
end