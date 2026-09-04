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
  %w[conformanceFire conformanceResult onAppear Fx0152].none? { |n| body.include?(n) }
end

# --- values are escaped, not interpolated -----------------------------------
quoted = E.host_source('Fx9003', [{ 'name' => 'h',
                                    'set' => { 'var' => 'v', 'value' => 'a"b\\c' } }])
check('a quote in the value is escaped') { quoted.include?('"a\\"b\\\\c"') }

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
if FAILURES.empty?
  puts "all #{__FILE__.split('/').last} checks passed"
  exit 0
else
  puts "FAILED: #{FAILURES.join(', ')}"
  exit 1
end
