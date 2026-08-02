#!/usr/bin/env ruby
# frozen_string_literal: true

#
# generate_codegen_host.rb — build the CODEGEN side of the conformance host.
#
# The dynamic host renders fixture layouts through DynamicView at runtime;
# production apps ship sjui-GENERATED SwiftUI code. This script makes the
# generated pipeline hostable so `jui conformance parity` can prove
# dynamic ≡ codegen per fixture:
#
#   1. Stages every ios-applicable VISUAL fixture layout under
#      CodegenStaging/Layouts/ as fx_NNNN.json (stable synthetic names —
#      fixture ids collide as Swift type names, indices never do; the web
#      host established the pattern in conformance/hosts/web).
#   2. Runs `sjui build` (sjui_tools — the exact production SwiftUI codegen
#      path) over the staging dir: View/FxNNNN/FxNNNNGeneratedView.swift,
#      Data/FxNNNNData.swift, ResourceManager/{String,Color}Manager.swift.
#   3. Emits CodegenStaging/CodegenFixtureRegistry.swift — fixture id →
#      generated view — which scripts/generate_project.rb compiles into the
#      app INSTEAD of the default nil registry, plus codegen-map.json for
#      diagnostics.
#
# Environment:
#   CONFORMANCE_DIR   conformance directory (manifest.json, fixtures/) [required]
#   SJUI_TOOLS_PATH   sjui_tools checkout (default: $CONFORMANCE_DIR/../sjui_tools)
#
# Everything under CodegenStaging/ is a build artifact (@generated, gitignored).
#

require 'fileutils'
require 'json'

host_dir = File.expand_path('..', __dir__)
conformance_dir = ENV['CONFORMANCE_DIR'] or abort 'error: CONFORMANCE_DIR is not set'
sjui_tools = ENV['SJUI_TOOLS_PATH'] || File.expand_path('../sjui_tools', conformance_dir)
sjui_bin = File.join(sjui_tools, 'bin', 'sjui')
abort "error: sjui_tools not found: #{sjui_bin} (set SJUI_TOOLS_PATH)" unless File.file?(sjui_bin)

manifest_path = File.join(conformance_dir, 'manifest.json')
abort "error: manifest not found: #{manifest_path}" unless File.file?(manifest_path)
manifest = JSON.parse(File.read(manifest_path))

# The sjui build runs in a NEUTRAL tmp dir: ProjectFinder walks parents for
# an .xcodeproj before honoring a cwd Package.swift, so any staging inside
# ConformanceHost/ would resolve the source root to the host itself
# (observed: "No JSON files found in .../ConformanceHost/Layouts"). Build
# where no ancestor carries a project file, then copy the outputs in-tree.
build_dir = ENV['CONFORMANCE_CODEGEN_BUILD_DIR'] || '/tmp/jsonui-codegen-ios-staging'
staging = File.join(host_dir, 'CodegenStaging')
FileUtils.rm_rf(build_dir)
FileUtils.rm_rf(staging)
layouts_dir = File.join(build_dir, 'Layouts')
FileUtils.mkdir_p(layouts_dir)
FileUtils.mkdir_p(staging)

# ---------------------------------------------------------------- selection
# Parity is a visual question: codegen screenshot vs the dynamic baseline.
# - class visual only (interactive drives dynamic bindings; assertable has
#   no screenshot; controls ARE class visual and carry baseline hashes).
# - Embed companions resolve screens through the dynamic loader — hosting
#   them in codegen needs the generated-screen resolution story from the
#   navigation layer. Skipped with a recorded reason; the parity ledger
#   carries them as 'missing' entries with this justification.
entries = []
skipped = []
manifest.fetch('fixtures', []).each do |fixture|
  next unless (fixture['platforms'] || []).include?('ios')
  unless fixture['class'] == 'visual'
    next # not part of the visual parity surface at all
  end
  mode = fixture['mode']
  mode_values =
    case mode
    when String then [mode]
    when Hash then mode.values.flatten
    else []
    end
  if !mode_values.empty? && !mode_values.include?('swiftui')
    skipped << { 'id' => fixture['id'], 'reason' => "mode #{mode_values.join(',')} not hosted" }
    next
  end
  # Companions split by directory: __screens/ layouts are Embed screens the
  # generated code cannot resolve by name (dynamic-loader navigation story) —
  # still skipped. __cells/ layouts are Collection cell views: staging them
  # under their bare name is all codegen needs — sjui build generates
  # ConformanceCellView from conformance_cell.json and the collection code
  # references exactly that struct.
  screen_companions = (fixture['companions'] || []).reject { |c| c.include?('__cells/') }
  if screen_companions.any?
    skipped << { 'id' => fixture['id'], 'reason' => 'embed-companion resolution not hosted in codegen yet' }
    next
  end
  entries << fixture
end

entries.each_with_index do |fixture, i|
  FileUtils.cp(
    File.join(conformance_dir, fixture['layout']),
    File.join(layouts_dir, format('fx_%04d.json', i + 1))
  )
end

cell_companions = entries
  .flat_map { |f| f['companions'] || [] }
  .select { |c| c.include?('__cells/') }
  .uniq
  .sort
cell_companions.each do |companion|
  src = File.join(conformance_dir, companion)
  abort "error: cell companion layout missing: #{companion}" unless File.file?(src)
  bare = File.basename(companion).sub(/\.layout\.json\z/, '') + '.json'
  FileUtils.cp(src, File.join(layouts_dir, bare))
end
puts "[codegen-host] staged #{entries.size} visual fixture layout(s) + #{cell_companions.size} cell companion(s), skipped #{skipped.size}"

# ---------------------------------------------------------------- sjui build
File.write(File.join(build_dir, 'sjui.config.json'), JSON.pretty_generate(
  'mode' => 'swiftui',
  'project_name' => 'ConformanceCodegen',
  'source_directory' => '',
  'layouts_directory' => 'Layouts',
  'styles_directory' => 'Styles',
  'resources_directory' => 'Resources',
  'resource_manager_directory' => 'ResourceManager',
  # The generated views resolve text through StringManager →
  # NSLocalizedString; without a bundled .strings table every label
  # renders its KEY (measured: 338/499 parity mismatches, all
  # "fx_0013_sample"-style). The extractor only writes tables that
  # already exist, so seed one and bundle it into the host app.
  'string_files' => ['Resources/Localizable.strings'],
  'swiftui' => { 'output_directory' => 'Generated' }
) + "\n")
FileUtils.mkdir_p(File.join(build_dir, 'Resources'))
File.write(File.join(build_dir, 'Resources', 'Localizable.strings'), "")
# sjui build refuses to run without a project file; the staging dir is not a
# real app, so a marker package satisfies the lookup.
File.write(File.join(build_dir, 'Package.swift'), <<~SWIFT)
  // swift-tools-version:5.9
  // marker so sjui build accepts this staging dir as a project root
  import PackageDescription
  let package = Package(name: "ConformanceCodegenStaging")
SWIFT

puts "[codegen-host] running sjui build (#{sjui_tools})"
build_log = File.join(host_dir, 'codegen-build.log')
ok = system({ 'PWD' => build_dir }, RbConfig.ruby, sjui_bin, 'build',
            chdir: build_dir, out: build_log, err: %i[child out])
unless ok
  abort "error: sjui build failed — see #{build_log}"
end

# Copy build outputs into the (gitignored) in-tree staging so the generated
# xcodeproj references stable repo-relative paths.
%w[View Data ResourceManager].each do |dir|
  src = File.join(build_dir, dir)
  FileUtils.cp_r(src, File.join(staging, dir)) if File.directory?(src)
end
strings_table = File.join(build_dir, 'Resources', 'Localizable.strings')
if File.file?(strings_table)
  FileUtils.mkdir_p(File.join(staging, 'Resources'))
  FileUtils.cp(strings_table, File.join(staging, 'Resources', 'Localizable.strings'))
end

# ---------------------------------------------------------------- registry
generated = 0
lines = []
lines << '// @generated by scripts/generate_codegen_host.rb — DO NOT EDIT'
lines << '// Fixture id → sjui-generated SwiftUI view (production codegen pipeline).'
lines << '// Compiled in place of CodegenFixtureRegistryDefault.swift by generate_project.rb.'
lines << ''
lines << 'import SwiftUI'
lines << 'import SwiftJsonUI'
lines << ''
hosts = []
cases = []
entries.each_with_index do |fixture, i|
  name = format('Fx%04d', i + 1)
  view_file = File.join(staging, 'View', name, "#{name}GeneratedView.swift")
  has_view = File.file?(view_file)
  fixture['_codegen'] = { 'component' => name, 'generated' => has_view }
  next unless has_view

  generated += 1
  # @State keeps the Binding<Data> contract satisfied without a ViewModel:
  # visual fixtures carry no data section, so default-initialized Data is
  # exactly what the dynamic host renders too.
  hosts << <<~SWIFT
    private struct #{name}Host: View {
        @State private var data = #{name}Data()
        var body: some View { #{name}GeneratedView(data: $data) }
    }
  SWIFT
  cases << "        case #{fixture['id'].inspect}: return AnyView(#{name}Host())"
end

lines << 'enum CodegenFixtureRegistry {'
lines << '    // Same launch contract real consumers wire: named colors resolve'
lines << '    // through SwiftJsonUIConfiguration → the generated ColorManager.'
lines << '    static func activate() {'
lines << '        SwiftJsonUIConfiguration.shared.colorProvider = { key in'
lines << '            guard let key = key as? String else { return nil }'
lines << '            return ColorManager.swiftui.color(for: key)'
lines << '        }'
lines << '    }'
lines << ''
lines << '    static func view(for fixtureId: String) -> AnyView? {'
lines << '        switch fixtureId {'
lines.concat(cases)
lines << '        default: return nil'
lines << '        }'
lines << '    }'
lines << '}'
lines << ''
lines.concat(hosts)
File.write(File.join(staging, 'CodegenFixtureRegistry.swift'), lines.join("\n"))

map = {
  'generated' => generated,
  'staged' => entries.size,
  'skipped' => skipped,
  'fixtures' => entries.map { |f| [f['id'], f['_codegen']] }.to_h
}
File.write(File.join(staging, 'codegen-map.json'), JSON.pretty_generate(map) + "\n")

missing = entries.reject { |f| f.dig('_codegen', 'generated') }
puts "[codegen-host] #{generated}/#{entries.size} generated views; registry written"
unless missing.empty?
  puts "[codegen-host] fixtures WITHOUT a generated view (parity will report them as missing):"
  missing.each { |f| puts "  - #{f['id']}" }
end
puts "[codegen-host] next: ruby scripts/generate_project.rb && HOST_MODE=codegen scripts/run_conformance.sh"
