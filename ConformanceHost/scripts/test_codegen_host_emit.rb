#!/usr/bin/env ruby
# frozen_string_literal: true

# Tests for the host wrapper emitted per fixture.
#
# WHY THIS FILE EXISTS, rather than trusting the conformance run:
#
# Exactly ONE fixture in the corpus can exercise handler injection on the
# codegen face. `state.handlers` is declared by 15 fixtures, and 14 of them
# need a driver action (tap 8 / longPress 1 / swipe 1 / input 2 /
# selectOption 2), which this face cannot perform — so
# `common/onAppear__callback_fire` is the only one that can ever run here.
#
# A green run of that one fixture is therefore n=1, and it cannot tell apart:
#   (a) a general mechanism driven by the manifest, and
#   (b) code that happens to name `conformanceFire` / `conformanceResult`.
# Both produce the same green. The examples below are what separates them,
# and they are the reason a second handler fixture will not need new host code.
#
# Run: ruby ConformanceHost/scripts/test_codegen_host_emit.rb

require 'json'
require_relative 'codegen_host_emit'

E = CodegenHostEmit
FAILURES = []

def check(label)
  ok = yield
  FAILURES << label unless ok
  puts "  #{ok ? 'ok  ' : 'FAIL'} #{label}"
end

puts 'codegen host emit'

# --- no handlers: the shape 991 of the 992 hosted fixtures get ---------------
plain = E.host_source('Fx0007', [])
check('no handlers -> @State wrapper') { plain.include?('@State private var data = Fx0007Data()') }
check('no handlers -> no store class') { !plain.include?('ObservableObject') }
check('no handlers -> binding contract unchanged') do
  plain.include?('Fx0007GeneratedView(data: $data)')
end

# --- one handler: the shape the failing fixture needed -----------------------
one = E.host_source('Fx0152', [{ 'name' => 'conformanceFire',
                                 'set' => { 'var' => 'conformanceResult', 'value' => 'fired' } }])
check('one handler -> store owns the data') { one.include?('@Published var data = Fx0152Data()') }
check('one handler -> closure assigned into the Data slot') do
  one.include?('data.conformanceFire = { [weak self] in self?.data.conformanceResult = "fired" }')
end
check('one handler -> view still receives a Binding<Data>') do
  one.include?('Fx0152GeneratedView(data: $store.data)')
end

# --- TWO handlers: the case no fixture in the corpus can reach ---------------
# The n=1 hole. If the wiring were fixture-specific, this is where it shows.
two = E.host_source('Fx9001', [
                      { 'name' => 'alpha', 'set' => { 'var' => 'first',  'value' => 'a' } },
                      { 'name' => 'beta',  'set' => { 'var' => 'second', 'value' => 'b' } }
                    ])
check('two handlers -> two closures') do
  two.scan(/data\.\w+ = \{ \[weak self\]/).length == 2
end
check('two handlers -> each targets its own var') do
  two.include?('data.alpha = { [weak self] in self?.data.first = "a" }') &&
    two.include?('data.beta = { [weak self] in self?.data.second = "b" }')
end

# --- names come from the manifest, not from this file -----------------------
novel = E.host_source('Fx9002', [{ 'name' => 'somethingNobodyHasDeclared',
                                   'set' => { 'var' => 'aVarNameNotInTheCorpus',
                                              'value' => 'x' } }])
check('unfamiliar names wire the same way') do
  novel.include?('data.somethingNobodyHasDeclared = { [weak self] in ' \
                 'self?.data.aVarNameNotInTheCorpus = "x" }')
end
check('no fixture id or corpus name is hardcoded') do
  source = File.read(File.join(__dir__, 'codegen_host_emit.rb'))
  body = source.split("\n").reject { |l| l.strip.start_with?('#') }.join("\n")
  # The fixture is `common/onAppear__callback_fire`: its id's segment, not
  # SwiftUI's `.onAppear`, which the linked probe host calls.
  %w[conformanceFire conformanceResult onAppear__ Fx0152].none? { |n| body.include?(n) }
end

# --- values are escaped, not interpolated -----------------------------------
quoted = E.host_source('Fx9003', [{ 'name' => 'h',
                                    'set' => { 'var' => 'v', 'value' => 'a"b\\c' } }])
check('a quote in the value is escaped') { quoted.include?('"a\\"b\\\\c"') }

# --- an integer value is an Int literal, a numeric string still a string ------
numbers = E.host_source('Fx9005', [{ 'name' => 'h', 'set' => { 'var' => 'n', 'value' => 13 } },
                                   { 'name' => 'g', 'set' => { 'var' => 's', 'value' => '13' } }])
check('an integer value is an Int literal') { numbers.include?('self?.data.n = 13 }') }
check('a numeric string is still a string') { numbers.include?('self?.data.s = "13" }') }

# --- an unwirable handler is refused, not emitted empty ---------------------
check('embed handlers are not wirable') do
  !E.wirable?([{ 'name' => 'go', 'embed' => { 'id' => 'e', 'action' => 'push' } }])
end
check('set handlers are wirable') do
  E.wirable?([{ 'name' => 'h', 'set' => { 'var' => 'v', 'value' => 'x' } }])
end
check('emitting an unwirable handler raises rather than emitting a no-op') do
  begin
    E.host_source('Fx9004', [{ 'name' => 'go', 'embed' => { 'id' => 'e' } }])
    false
  rescue ArgumentError
    true
  end
end

puts
# --- autoId: a key as autoChangeTrackingId enriches it (a probe's) -----------
auto = E.host_source('ProbeAuto', [{ 'name' => 'onGo', 'set' => { 'var' => 'target',
  'autoId' => { 'from' => { 'title' => 'a3', 'key' => 'k3' }, 'primaryKey' => 'key', 'fallbackIndex' => 3 } } }])
check('autoId -> CellIdGenerator.autoId of the dictionary, in the process') do
  auto.include?('self?.data.target = CellIdGenerator.autoId(from: ["title": "a3", "key": "k3"], primaryKey: "key", fallbackIndex: 3) }')
end
check('autoId -> no literal') { !auto.include?('self?.data.target = "') }

puts
# --- afterFirstDraw: the change the host makes after the first draw ----------
# (jsonui-cli INTERACTIVE_HOST_CONTRACT.md "afterFirstDraw"). A store method,
# not a Data closure: the layout does not name it, so the Data has no member.
afd = { 'name' => 'conformanceAfterFirstDraw', 'set' => { 'var' => 'scrollTarget', 'value' => 'Gamma' } }
first = E.host_source('Fx0700', [], after_first_draw: afd, fixture_id: 'Collection/scrollAnchor__top')
check('afterFirstDraw alone -> a store, not the plain host') { first.include?('Fx0700Store: ObservableObject') }
check('afterFirstDraw -> a store method that sets the literal') do
  first.include?('func fireAfterFirstDraw() { data.scrollTarget = "Gamma" }')
end
check('afterFirstDraw -> no Data member named after it') { !first.include?('data.conformanceAfterFirstDraw') }
check('afterFirstDraw -> the modifier, on the fixture id, applied when the value carries it') do
  first.include?('.conformanceAfterFirstDraw("Collection/scrollAnchor__top", declared: true, ' \
                 'applied: store.data.scrollTarget == "Gamma", fire: store.fireAfterFirstDraw)')
end
both = E.host_source('Fx0701', [{ 'name' => 'h', 'set' => { 'var' => 'v', 'value' => 'x' } }],
                     after_first_draw: afd, fixture_id: 'f')
check('afterFirstDraw beside a handler -> both') do
  both.include?('data.h = { [weak self] in self?.data.v = "x" }') && both.include?('func fireAfterFirstDraw()')
end
check('no afterFirstDraw -> no modifier') { !E.host_source('Fx0702', [{ 'name' => 'h', 'set' => { 'var' => 'v', 'value' => 'x' } }]).include?('conformanceAfterFirstDraw') }
check('afterFirstDraw without a fixture id raises') do
  begin
    E.host_source('Fx0703', [], after_first_draw: afd)
    false
  rescue ArgumentError
    true
  end
end
check('no trailing whitespace') { first.lines.none? { |l| l.chomp.end_with?(' ') } }

puts
# --- a probe's link: count / watch / writes (App/ProbeHostLink.swift) ---------
# A11yActivationProbeView measured a paste of sjui's output because a probe
# could not reach a generated view's data; these are what replaced the paste.
linked = E.host_source('ProbeA', [{ 'name' => 'onTap', 'count' => 'cgTap' },
                                  { 'name' => 'onSet', 'set' => { 'var' => 'v', 'value' => 'x' } }],
                       watch: [{ 'var' => 'sw', 'count' => 'cgSw' }, { 'var' => 'sel', 'count' => 'cgSel' }],
                       writes: %w[gateOpen rows])
check('count -> the handler counts through the link, by the name the manifest gives') do
  linked.include?('data.onTap = { [weak self] in self?.link?.count("cgTap") }')
end
check('count beside set -> set still wired') { linked.include?('data.onSet = { [weak self] in self?.data.v = "x" }') }
check('watch -> one change check per var, old against new') do
  linked.include?('if data.sw != oldValue.sw { link?.count("cgSw") }') &&
    linked.include?('if data.sel != oldValue.sel { link?.count("cgSel") }')
end
check('watch -> on the published data (a Binding write reaches it)') do
  linked =~ /@Published var data = ProbeAData\(\) \{\n\s+didSet \{/
end
check('writes -> each named var taken from the written values, typed by assign') do
  linked.include?('if let value = values["gateOpen"] { ProbeHostLink.assign(value, to: &next.gateOpen, "gateOpen") }') &&
    linked.include?('if let value = values["rows"] { ProbeHostLink.assign(value, to: &next.rows, "rows") }')
end
check('writes -> one data assignment per write') { linked.scan('data = next').length == 1 }
check('linked -> reads the link from the environment and attaches on appear') do
  linked.include?('@Environment(\\.probeHostLink) private var link') &&
    linked.include?('.onAppear { store.attach(link) }') &&
    linked.include?('.onReceive(link?.writes ?? ProbeHostLink.noWrites) { store.write($0) }')
end
check('linked -> the view still receives a Binding<Data>') { linked.include?('ProbeAGeneratedView(data: $store.data)') }
check('linked -> no trailing whitespace') { linked.lines.none? { |l| l.chomp.end_with?(' ') } }
check('a count handler alone makes a linked host') do
  E.host_source('ProbeB', [{ 'name' => 'h', 'count' => 'c' }]).include?('ProbeHostLink')
end
check('writes alone make a linked host') { E.host_source('ProbeC', [], writes: ['g']).include?('ProbeHostLink') }
check('set handlers alone are not linked (existing probes keep their host)') do
  !E.host_source('ProbeD', [{ 'name' => 'h', 'set' => { 'var' => 'v', 'value' => 'x' } }]).include?('ProbeHostLink')
end
check('a count handler takes its declared arity') do
  E.host_source('ProbeE', [{ 'name' => 'h', 'count' => 'c', 'arity' => 1 }])
   .include?('data.h = { [weak self] _ in self?.link?.count("c") }')
end
check('a count name is escaped') do
  E.host_source('ProbeF', [{ 'name' => 'h', 'count' => 'a"b' }]).include?('count("a\\"b")')
end
check('a count handler is not wirable for a fixture (no link there)') { !E.wirable?([{ 'name' => 'h', 'count' => 'c' }]) }
check('a watch without a count raises') do
  begin
    E.host_source('ProbeG', [], watch: [{ 'var' => 'v' }])
    false
  rescue ArgumentError
    true
  end
end
check('a linked host refuses afterFirstDraw') do
  begin
    E.host_source('ProbeH', [{ 'name' => 'h', 'count' => 'c' }], after_first_draw: afd, fixture_id: 'f')
    false
  rescue ArgumentError
    true
  end
end

puts
# --- arity: the declared closure type, optional or not ------------------------
check('() -> Void is 0') { E.handler_arity('() -> Void').zero? }
check('(String) -> Void is 1') { E.handler_arity('(String) -> Void') == 1 }
check('(String, Any) -> Void is 2') { E.handler_arity('(String, Any) -> Void') == 2 }
check('(() -> Void)? is 0, as () -> Void (probe layouts declare it so)') { E.handler_arity('(() -> Void)?').zero? }
check('((String) -> Void)? is 1') { E.handler_arity('((String) -> Void)?') == 1 }
check('an undeclared handler is 0') { E.handler_arity(nil).zero? }

puts
# --- the probe manifest: array (as before) or object ------------------------
arr = E.probe_manifest([{ 'name' => 'h', 'set' => { 'var' => 'v', 'value' => 'x' } }])
check('an array manifest is the handlers, nothing else') do
  arr['handlers'].size == 1 && arr['watch'].empty? && arr['writes'].empty?
end
obj = E.probe_manifest({ 'handlers' => [{ 'name' => 'h', 'count' => 'c' }], 'watch' => [{ 'var' => 'v', 'count' => 'c' }],
                         'writes' => ['g'] })
check('an object manifest carries all three') { obj['handlers'].size == 1 && obj['watch'].size == 1 && obj['writes'] == ['g'] }
check('a missing key is empty') { E.probe_manifest({ 'writes' => ['g'] })['handlers'] == [] }
check('an unknown key is refused (a misspelt "watches" would wire nothing)') do
  begin
    E.probe_manifest({ 'watches' => [] })
    false
  rescue ArgumentError
    true
  end
end
check('the a11y activation manifest parses and names only known operations') do
  m = E.probe_manifest(JSON.parse(File.read(File.join(__dir__, '..', 'ProbeLayouts', 'handlers', 'probe_a11y_activation.json'))))
  m['handlers'].all? { |h| h['count'] } && !m['watch'].empty? && m['writes'].include?('gateOpen')
end

if FAILURES.empty?
  puts "all #{__FILE__.split('/').last} checks passed"
  exit 0
else
  puts "FAILED: #{FAILURES.join(', ')}"
  exit 1
end
