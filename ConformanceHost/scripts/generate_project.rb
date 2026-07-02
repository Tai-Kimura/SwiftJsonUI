#!/usr/bin/env ruby
# frozen_string_literal: true

#
# generate_project.rb — (re)generate ConformanceHost.xcodeproj.
#
# The project is fully generated (and gitignored) because the UITest target
# compiles vendored driver sources that only exist after
# scripts/sync_fixtures.sh has run. Run order:
#
#   1. scripts/sync_fixtures.sh        (needs CONFORMANCE_DIR, JSONUI_TEST_RUNNER_PATH)
#   2. scripts/generate_project.rb
#   3. xcodebuild test (see scripts/run_conformance.sh)
#
# Requires the 'xcodeproj' gem (ships with CocoaPods).
#

require 'xcodeproj'

host_dir = File.expand_path('..', __dir__)
project_path = File.join(host_dir, 'ConformanceHost.xcodeproj')

app_sources = Dir[File.join(host_dir, 'App', '**', '*.swift')].sort
uitest_sources = Dir[File.join(host_dir, 'UITests', '**', '*.swift')].sort

if uitest_sources.none? { |f| f.include?('Vendor/JsonUITestRunner') }
  abort 'error: UITests/Vendor/JsonUITestRunner is empty — run scripts/sync_fixtures.sh first'
end
unless File.directory?(File.join(host_dir, 'Resources', 'fixtures'))
  abort 'error: Resources/fixtures missing — run scripts/sync_fixtures.sh first'
end

DEPLOYMENT_TARGET = '17.0'

project = Xcodeproj::Project.new(project_path)

# ---------------------------------------------------------------- app target
app_target = project.new_target(:application, 'ConformanceHost', :ios, DEPLOYMENT_TARGET)
app_group = project.main_group.new_group('App', 'App')
app_sources.each do |file|
  ref = app_group.new_reference(file)
  app_target.add_file_references([ref])
end
assets_ref = app_group.new_reference(File.join(host_dir, 'App', 'Assets.xcassets'))
app_target.add_resources([assets_ref])

# fixtures folder reference (blue folder → preserves subdirectories in bundle)
resources_group = project.main_group.new_group('Resources', 'Resources')
fixtures_ref = resources_group.new_reference(File.join(host_dir, 'Resources', 'fixtures'))
manifest_ref = resources_group.new_reference(File.join(host_dir, 'Resources', 'manifest.json'))
# the app also needs the manifest: ConformanceStateProvider reads each
# interactive fixture's `state` declaration from it (INTERACTIVE_HOST_CONTRACT.md)
app_target.add_resources([fixtures_ref, manifest_ref])

# SwiftJsonUI local package (repo root, one level up from ConformanceHost/)
package_ref = project.new(Xcodeproj::Project::Object::XCLocalSwiftPackageReference)
package_ref.relative_path = '..'
project.root_object.package_references << package_ref
product_dep = project.new(Xcodeproj::Project::Object::XCSwiftPackageProductDependency)
product_dep.product_name = 'SwiftJsonUI'
app_target.package_product_dependencies << product_dep

# ------------------------------------------------------------- uitest target
uitest_target = project.new_target(:ui_test_bundle, 'ConformanceHostUITests', :ios, DEPLOYMENT_TARGET)
uitest_group = project.main_group.new_group('UITests', 'UITests')
uitest_sources.each do |file|
  ref = uitest_group.new_reference(file)
  uitest_target.add_file_references([ref])
end
# UITest bundle carries the manifest and the fixtures (test JSONs)
uitest_target.add_resources([fixtures_ref, manifest_ref])
uitest_target.add_dependency(app_target)

# ------------------------------------------------------------ build settings
project.targets.each do |target|
  target.build_configurations.each do |config|
    config.build_settings['SWIFT_VERSION'] = '5.0'
    config.build_settings['GENERATE_INFOPLIST_FILE'] = 'YES'
    config.build_settings['CODE_SIGN_STYLE'] = 'Automatic'
    config.build_settings['CODE_SIGNING_REQUIRED'] = 'NO'
    config.build_settings['TARGETED_DEVICE_FAMILY'] = '1'
    config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = DEPLOYMENT_TARGET
    config.build_settings['CURRENT_PROJECT_VERSION'] = '1'
    config.build_settings['MARKETING_VERSION'] = '1.0'
  end
end

app_target.build_configurations.each do |config|
  config.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = 'com.swiftjsonui.ConformanceHost'
  config.build_settings['INFOPLIST_KEY_UILaunchScreen_Generation'] = 'YES'
  config.build_settings['INFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents'] = 'YES'
end

uitest_target.build_configurations.each do |config|
  config.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = 'com.swiftjsonui.ConformanceHostUITests'
  config.build_settings['TEST_TARGET_NAME'] = 'ConformanceHost'
end

project.save

# ------------------------------------------------------------- shared scheme
scheme = Xcodeproj::XCScheme.new
scheme.add_build_target(app_target)
scheme.set_launch_target(app_target)
scheme.add_test_target(uitest_target)
scheme.save_as(project_path, 'ConformanceHost', true)

puts "generated #{project_path}"
puts "  app sources:    #{app_sources.size}"
puts "  uitest sources: #{uitest_sources.size}"
