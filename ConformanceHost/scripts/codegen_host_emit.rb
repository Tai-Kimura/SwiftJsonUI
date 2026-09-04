# frozen_string_literal: true

# Swift emitted per hosted fixture by generate_codegen_host.rb.
#
# Split out so it can be tested WITHOUT running the generator, which needs a
# conformance corpus, a staging directory and generated views. The thing that
# most needs testing here has exactly one fixture in the corpus that exercises
# it — `common/onAppear__callback_fire` is the only handler-declaring fixture
# that needs no driver, so every other one is unhostable on this face — and a
# green run of a single fixture cannot distinguish a general mechanism from
# code that happens to name that fixture's variables.
module CodegenHostEmit
  module_function

  # A Swift string literal.
  def swift_string_literal(str)
    escaped = str.to_s.gsub(0x5c.chr) { 0x5c.chr * 2 }
                 .gsub(0x22.chr) { 0x5c.chr + 0x22.chr }
    0x22.chr + escaped + 0x22.chr
  end

  # The per-fixture host wrapper.
  #
  # `handlers` is the fixture's `state.handlers` from the manifest, passed
  # through as DATA — nothing here reads a fixture id, a component name or a
  # variable name it was told about in advance, so a second handler fixture
  # needs no change to this code.
  #
  # With no handlers: `@State` is enough. Declared `state.vars` need nothing
  # either, because sjui bakes each one's defaultValue into the generated Data
  # property, so default-initialized Data is what the dynamic host renders.
  #
  # With handlers: a class, not `@State`. The closure has to mutate the same
  # Data the view renders, which needs reference identity. `$store.data` is
  # still a `Binding<Data>`, so the generated view's contract is unchanged.
  #
  # Only the `set` operation is emitted. `embed` handlers are refused at
  # staging time (generate_codegen_host.rb) rather than silently dropped: a
  # fixture whose handler never fires still renders and still asserts, and
  # reports its PRE-handler value — which is how this defect presented,
  # `Expected 'fired', Actual 'ready'`, with nothing in the staging summary
  # saying the handler had no wiring.
  def host_source(name, handlers)
    handlers = Array(handlers)
    return plain_host(name) if handlers.empty?

    assignments = handlers.map { |handler| handler_assignment(handler) }.join("\n")
    <<~SWIFT
      private final class #{name}Store: ObservableObject {
          @Published var data = #{name}Data()
          init() {
      #{assignments}
          }
      }

      private struct #{name}Host: View {
          @StateObject private var store = #{name}Store()
          var body: some View { #{name}GeneratedView(data: $store.data) }
      }
    SWIFT
  end

  def plain_host(name)
    <<~SWIFT
      private struct #{name}Host: View {
          @State private var data = #{name}Data()
          var body: some View { #{name}GeneratedView(data: $data) }
      }
    SWIFT
  end

  # One `set` handler: invoking the closure assigns the literal to the named
  # var and re-renders everything bound to it (INTERACTIVE_HOST_CONTRACT §2).
  def handler_assignment(handler)
    set = handler['set']
    raise ArgumentError, "handler #{handler['name'].inspect} has no `set` operation" unless set

    value = swift_string_literal(set['value'].to_s)
    "        data.#{handler['name']} = { [weak self] in " \
      "self?.data.#{set['var']} = #{value} }"
  end

  # True when the fixture's handlers can all be wired here.
  def wirable?(handlers)
    Array(handlers).all? { |h| h['set'] }
  end
end
