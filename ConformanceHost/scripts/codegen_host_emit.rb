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
  # For a fixture only the `set` operation is emitted (a probe's manifest can
  # also `count`, `watch` and take `writes`: linked_host). `embed` handlers are refused at
  # staging time (generate_codegen_host.rb) rather than silently dropped: a
  # fixture whose handler never fires still renders and still asserts, and
  # reports its PRE-handler value — which is how this defect presented,
  # `Expected 'fired', Actual 'ready'`, with nothing in the staging summary
  # saying the handler had no wiring.
  # `after_first_draw` (the manifest state's `afterFirstDraw`, jsonui-cli
  # INTERACTIVE_HOST_CONTRACT.md) is the one change the host makes itself
  # after the first draw: a `set` the layout does not name, so it is a method
  # of the store rather than a closure in the Data (which has no member of
  # that name). App/AfterFirstDraw.swift fires and stamps it, on the fixture
  # id the UITest reads the stamp for.
  #
  # `watch` and `writes` (a probe's manifest only, see probe_manifest) and a
  # `count` handler make a LINKED host: the store counts through the
  # ProbeHostLink the probe puts in the environment (App/ProbeHostLink.swift),
  # and takes the values the probe writes into the named Data vars.
  def host_source(name, handlers, after_first_draw: nil, fixture_id: nil, watch: [], writes: [])
    handlers = Array(handlers)
    watch = Array(watch)
    writes = Array(writes)
    if linked?(handlers, watch, writes)
      raise ArgumentError, 'a linked (probe) host takes no afterFirstDraw' if after_first_draw

      return linked_host(name, handlers, watch, writes)
    end
    return plain_host(name) if handlers.empty? && after_first_draw.nil?

    assignments = handlers.map { |handler| handler_assignment(handler) }.join("\n")
    fire = ''
    view = "#{name}GeneratedView(data: $store.data)"
    if after_first_draw
      raise ArgumentError, 'an afterFirstDraw host needs its fixture id' if fixture_id.nil?

      set = after_first_draw['set'] or raise ArgumentError, 'afterFirstDraw has no `set` operation'
      value = swift_string_literal(set['value'].to_s)
      fire = "\n    func fireAfterFirstDraw() { data.#{set['var']} = #{value} }"
      view = "#{view}\n            .conformanceAfterFirstDraw(#{swift_string_literal(fixture_id)}, declared: true, " \
             "applied: store.data.#{set['var']} == #{value}, fire: store.fireAfterFirstDraw)"
    end
    <<~SWIFT
      private final class #{name}Store: ObservableObject {
          @Published var data = #{name}Data()
          init() {
      #{assignments}
          }#{fire}
      }

      private struct #{name}Host: View {
          @StateObject private var store = #{name}Store()
          var body: some View {
              #{view}
          }
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

    # An integer is an Int literal (a probe's scrollTo index, say), true / false a
    # Bool literal; anything else the string it has always been. `autoId` (a probe's): a key as
    # autoChangeTrackingId enriches it — CellIdGenerator.autoId of the cell's
    # dictionary (string values), whose hash is launch-scoped, so it can be
    # known only in the process that draws the cells.
    value =
      if (auto = set['autoId'])
        from = auto['from'].map { |k, v| "#{swift_string_literal(k)}: #{swift_string_literal(v)}" }
        "CellIdGenerator.autoId(from: [#{from.empty? ? ':' : from.join(', ')}], " \
          "primaryKey: #{swift_string_literal(auto['primaryKey'])}, fallbackIndex: #{Integer(auto['fallbackIndex'])})"
      elsif set['value'].is_a?(Integer) || set['value'] == true || set['value'] == false
        # an Int, or a Bool (a probe turning a bound `enabled` off)
        set['value'].to_s
      else
        swift_string_literal(set['value'].to_s)
      end
    # The payload is ignored (INTERACTIVE_HOST_CONTRACT §2), but the closure
    # still has to take as many parameters as the handler's declared type:
    # `{ in }` cannot be stored in a `((String) -> Void)?`.
    params = Array.new(Integer(handler['arity'] || 0), '_').join(', ')
    "        data.#{handler['name']} = { [weak self] #{params.empty? ? '' : "#{params} "}in " \
      "self?.data.#{set['var']} = #{value} }"
  end

  # How many parameters a declared handler class takes: `() -> Void` 0,
  # `(String) -> Void` 1, `(String, Any) -> Void` 2 (top-level commas only).
  # A declared optional, `(() -> Void)?` (how probe layouts spell it), is the
  # closure it wraps: read as written, its `(` `()` `->` gave 1.
  def handler_arity(klass)
    wrapped = klass.to_s[/\A\s*\((.*)\)\?\s*\z/m, 1]
    return handler_arity(wrapped) if wrapped

    inner = klass.to_s[/\A\s*\((.*)\)\s*->/m, 1]
    return 0 if inner.nil? || inner.strip.empty?

    depth = 0
    inner.each_char.count do |c|
      depth += 1 if '([<'.include?(c)
      depth -= 1 if ')]>'.include?(c)
      c == ',' && depth.zero?
    end + 1
  end

  # `handlers` with each one's arity, read from the layout's `data` section
  # (the manifest's `state.handlers` does not carry the declared type).
  def with_arity(handlers, layout_data)
    classes = Array(layout_data).to_h { |d| [d['name'], d['class']] }
    Array(handlers).map { |h| h.merge('arity' => handler_arity(classes[h['name']])) }
  end

  # True when the fixture's handlers can all be wired here. A fixture's, not
  # a probe's: `count` needs the ProbeHostLink only a probe puts in the
  # environment, so a fixture that declared one would count into nothing.
  def wirable?(handlers)
    Array(handlers).all? { |h| h['set'] }
  end

  # ------------------------------------------------------------ probe links
  #
  # A probe that measures what its controls DID (a handler called, a Switch
  # switched) needs more from the host than `set`: the generated view's Data
  # is private to the host's store, so a probe could neither read a change
  # nor drive a binding of the layout (A11yActivationProbeView's bound stop,
  # `userInteractionEnabled: "@{gateOpen}"`). Until this existed that probe
  # drew a hand copy of `sjui build`'s output instead of the output, and the
  # copy kept the old shape when sjui's changed (jsonui-cli ticket
  # sjui-a11y-activation-probe-codegen-rows-are-hand-copies).
  #
  # Three operations, all named by the probe's manifest
  # (ProbeLayouts/handlers/<probe>.json):
  #   {"name": h, "count": c}  handler h tells the link "c happened once"
  #   watch [{"var": v, "count": c}]
  #                            every change of Data var v (old != new) is one
  #                            "c" — what a Switch, a Segment or a Radio
  #                            moved; v must be Equatable
  #   writes [v, ...]          vars the probe may write (link.write([v: x]));
  #                            a value of the wrong type stops the app
  #                            (ProbeHostLink.assign), it is never dropped
  def linked?(handlers, watch, writes)
    !watch.empty? || !writes.empty? || Array(handlers).any? { |h| h['count'] }
  end

  # A probe's handlers file: the manifest's `state.handlers` array as before,
  # or an object {"handlers": [...], "watch": [...], "writes": [...]}. An
  # unknown key is refused — a misspelt "watches" would otherwise wire
  # nothing, and a count that never moves reads as a stop that held.
  PROBE_KEYS = %w[handlers watch writes].freeze
  def probe_manifest(parsed)
    return { 'handlers' => parsed, 'watch' => [], 'writes' => [] } if parsed.is_a?(Array)
    raise ArgumentError, "a probe manifest is an array or an object, not #{parsed.class}" unless parsed.is_a?(Hash)

    unknown = parsed.keys - PROBE_KEYS
    raise ArgumentError, "unknown probe manifest key(s): #{unknown.join(', ')} (known: #{PROBE_KEYS.join(', ')})" unless unknown.empty?

    PROBE_KEYS.to_h { |k| [k, Array(parsed[k])] }
  end

  def count_assignment(handler)
    params = Array.new(Integer(handler['arity'] || 0), '_').join(', ')
    "        data.#{handler['name']} = { [weak self] #{params.empty? ? '' : "#{params} "}in " \
      "self?.link?.count(#{swift_string_literal(handler['count'])}) }"
  end

  def linked_host(name, handlers, watch, writes)
    assignments = handlers.map do |handler|
      handler['count'] ? count_assignment(handler) : handler_assignment(handler)
    end
    watch.each do |w|
      raise ArgumentError, "a watch needs `var` and `count`: #{w.inspect}" unless w['var'] && w['count']
    end
    changes = watch.map do |w|
      "            if data.#{w['var']} != oldValue.#{w['var']} { link?.count(#{swift_string_literal(w['count'])}) }"
    end
    did_set = changes.empty? ? '' : " {\n        didSet {\n#{changes.join("\n")}\n        }\n    }"
    takes = writes.map do |var|
      "        if let value = values[#{swift_string_literal(var)}] { " \
        "ProbeHostLink.assign(value, to: &next.#{var}, #{swift_string_literal(var)}) }"
    end
    <<~SWIFT
      private final class #{name}Store: ObservableObject {
          @Published var data = #{name}Data()#{did_set}
          weak var link: ProbeHostLink?
          init() {
      #{assignments.join("\n")}
          }
          func attach(_ link: ProbeHostLink?) {
              self.link = link
              if let link { write(link.values) }
          }
          func write(_ values: [String: Any]) {
              var next = data
      #{takes.join("\n")}
              data = next
          }
      }

      private struct #{name}Host: View {
          @StateObject private var store = #{name}Store()
          @Environment(\\.probeHostLink) private var link
          var body: some View {
              #{name}GeneratedView(data: $store.data)
                  .onAppear { store.attach(link) }
                  .onReceive(link?.writes ?? ProbeHostLink.noWrites) { store.write($0) }
          }
      }
    SWIFT
  end
end
