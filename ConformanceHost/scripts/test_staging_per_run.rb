#!/usr/bin/env ruby
# frozen_string_literal: true

# Each run of the conformance tooling stages in a directory of its own.
#
# generate_codegen_host.rb ran `sjui build` in one fixed
# /tmp/jsonui-codegen-ios-staging and run_conformance.sh staged the runner's
# output in one fixed /tmp/jsonui-conformance-ios[-codegen], each emptied at
# the start of a run — so two runs at once emptied each other's. Measured for
# the codegen host on 956ffde (2026-09-26): 5 pairs, 4 of 10 runs failed and 3
# of the 6 that exited 0 wrote resource managers unlike a run alone's. Ticket
# conformance-host-codegen-staging-dir-collides-across-runs.
#
# No simulator and no Xcode: run_conformance.sh runs against stubs of
# `xcodebuild` and `xcrun` that write what the UITest runner writes.
#
# Run: ruby ConformanceHost/scripts/test_staging_per_run.rb

require 'fileutils'
require 'json'
require 'open3'
require 'tmpdir'
require_relative 'codegen_build_dir'

FAILURES = []

def check(label)
  ok = yield
  FAILURES << label unless ok
  puts "  #{ok ? 'ok  ' : 'FAIL'} #{label}"
end

SCRIPTS = __dir__

puts 'codegen build dir (generate_codegen_host.rb)'
Dir.mktmpdir('parent') do |parent|
  a, owned_a = CodegenBuildDir.for_run({}, parent: parent)
  b, owned_b = CodegenBuildDir.for_run({}, parent: parent)
  check('two runs get two directories, each owned') { a != b && owned_a && owned_b && File.directory?(a) && File.directory?(b) }
  check("each is named for the run's pid") { [a, b].all? { |d| CodegenBuildDir.run_pid(d) == Process.pid } }

  named = File.join(parent, 'named')
  FileUtils.mkdir_p(named)
  File.write(File.join(named, 'stale'), 'x')
  dir, owned = CodegenBuildDir.for_run({ 'CONFORMANCE_CODEGEN_BUILD_DIR' => named }, parent: parent)
  check('a directory the caller names is used, emptied, and not owned') { dir == named && !owned && Dir.empty?(named) }

  # A pid that is certainly gone: a child that has exited and been reaped.
  dead = Process.spawn('true')
  Process.wait(dead)
  left = File.join(parent, "#{CodegenBuildDir::FAMILY}-#{dead}-20260926-1-abc")
  live = File.join(parent, "#{CodegenBuildDir::FAMILY}-#{Process.pid}-20260926-1-def")
  old_fixed = File.join(parent, CodegenBuildDir::FAMILY)
  other = File.join(parent, "jsonui-codegen-android-staging-#{dead}-20260926-1-ghi")
  [left, live, old_fixed, other].each { |d| FileUtils.mkdir_p(d) }
  CodegenBuildDir.sweep(parent)
  check("the sweep takes a killed run's directory") { !File.exist?(left) }
  check("and leaves a live run's, the old fixed-name one and another family's") do
    [live, old_fixed, other, a, b].all? { |d| File.directory?(d) }
  end
end

puts 'run staging (run_conformance.sh / collect_results.sh)'
Dir.mktmpdir('host') do |root|
  host = File.join(root, 'ConformanceHost')
  FileUtils.mkdir_p(File.join(host, 'ConformanceHost.xcodeproj'))
  FileUtils.mkdir_p(File.join(host, 'scripts'))
  %w[run_conformance.sh collect_results.sh].each { |f| FileUtils.cp(File.join(SCRIPTS, f), File.join(host, 'scripts', f)) }
  bin = File.join(root, 'bin')
  FileUtils.mkdir_p(bin)
  # What the UITest runner leaves in its staging dir, marked with the run.
  File.write(File.join(bin, 'xcodebuild'), <<~SH)
    #!/bin/bash
    s="$TEST_RUNNER_CONFORMANCE_STAGING_DIR"
    mkdir -p "$s/results" "$s/artifacts/ios"
    sleep "${STUB_SLEEP:-1}"
    printf '{"results":[{"id":"%s","status":"pass"}]}' "$RUN_MARK" > "$s/results/ios.results.json"
    printf '%s' "$RUN_MARK" > "$s/artifacts/ios/$RUN_MARK.png"
    exit "${STUB_EXIT:-0}"
  SH
  File.write(File.join(bin, 'xcrun'), "#!/bin/bash\nexit 0\n")
  FileUtils.chmod(0o755, [File.join(bin, 'xcodebuild'), File.join(bin, 'xcrun')])

  run = lambda do |mark, env = {}|
    out = File.join(root, "conf-#{mark}")
    FileUtils.mkdir_p(out)
    base = { 'PATH' => "#{bin}:#{ENV['PATH']}", 'CONFORMANCE_DIR' => out, 'SIMULATOR_UDID' => 'stub-udid', 'RUN_MARK' => mark }
    stdin, output, wait = Open3.popen2e(base.merge(env), 'bash', File.join(host, 'scripts', 'run_conformance.sh'))
    stdin.close
    [output, wait]
  end
  collected = ->(mark) { JSON.parse(File.read(File.join(root, "conf-#{mark}", 'results', 'ios.results.json')))['results'].map { |r| r['id'] } }

  before = Dir.glob('/tmp/jsonui-conformance-ios.*')
  started = %w[one two].map { |m| [m, *run.call(m)] }
  logs = started.map { |mark, output, wait| [mark, output.read, wait.value] }
  check('two runs at once both finish') { logs.all? { |_, _, st| st.success? } }
  check('each collects its own results and screenshot') do
    logs.all? do |mark, _, _|
      collected.call(mark) == [mark] && Dir.children(File.join(root, "conf-#{mark}", 'artifacts', 'ios')) == ["#{mark}.png"]
    end
  end
  staged = logs.map { |_, log, _| log[%r{full xcodebuild log: (\S+)/xcodebuild\.log}, 1] }
  check('in two directories of their own') { staged.compact.size == 2 && staged.uniq.size == 2 && staged.all? { |d| d.start_with?('/tmp/jsonui-conformance-ios.') } }
  check('removed when the run succeeds') { staged.compact.none? { |d| File.exist?(d) } }

  _, failed_log, failed = run.call('three', 'STUB_EXIT' => '1').then { |io, wait| [nil, io.read, wait.value] }
  kept = failed_log[/^\[conformance\] this run's staging is kept for the failure: (\S+)$/, 1]
  check('a failed run keeps its staging and says where') { !failed.success? && kept && File.file?(File.join(kept, 'xcodebuild.log')) }
  FileUtils.rm_rf(kept) if kept

  named = File.join(root, 'named-staging')
  _, named_log, named_status = run.call('four', 'CONFORMANCE_STAGING' => named).then { |io, wait| [nil, io.read, wait.value] }
  check('a staging the caller names is used and left in place') do
    named_status.success? && named_log.include?("#{named}/xcodebuild.log") && File.file?(File.join(named, 'results', 'ios.results.json'))
  end
  check('no run left a directory behind in /tmp') { (Dir.glob('/tmp/jsonui-conformance-ios.*') - before).empty? }

  env = { 'CONFORMANCE_DIR' => File.join(root, 'conf-five') }
  said, st = Open3.capture2e(env, 'bash', File.join(host, 'scripts', 'collect_results.sh'))
  check('collect_results.sh with no staging named refuses rather than reading a shared default') do
    !st.success? && said.include?('CONFORMANCE_STAGING is not set')
  end
end

puts
if FAILURES.empty?
  puts 'all passed'
else
  puts "#{FAILURES.size} failed:"
  FAILURES.each { |f| puts "  - #{f}" }
  exit 1
end
