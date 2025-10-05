#import "../lib/constants.typ": *
#import "../lib/diagram-helpers.typ": *
#import "@preview/fletcher:0.5.8" as fletcher: diagram, edge, node

#let principles-slides(slide) = {
  slide(title: "Steps for creating robust stream operators")[
    #{
      set text(size: 8pt)
      styled-diagram(
        spacing: (3em, 1em),

        workflow-step(
          (1, 3),
          "1",
          "Write tests",
          ("Order preservation", "All items received", [Use `Barrier`s, not `sleep()`]),
          colors.stream,
          <write-tests>,
        ),
        labeled-edge(<write-tests>, <analyze-states>, none),

        workflow-step(
          (3, 3),
          "2",
          "Analyze states",
          ("Minimal state set", "Add tracing / logging", [Avoid `Option`s in states]),
          colors.data,
          <analyze-states>,
        ),
        labeled-edge(<analyze-states>, <implement>, none, bend: -15deg),

        workflow-step(
          (2, 2),
          "3",
          "Define transitions",
          ([Start with 1,2 output `Stream`s], "Get wake-up order right", [Don't create  custom `Waker`s]),
          colors.state,
          <implement>,
        ),
        labeled-edge(<implement>, <run-tests>, none, bend: -15deg),

        workflow-step(
          (1, 1),
          "4",
          "Run tests",
          ("Trace tests", "Debug tests"),
          colors.ui,
          <run-tests>,
        ),
        labeled-edge(<run-tests>, <benchmarks>, label: "✓ pass"),
        labeled-edge(
          <run-tests>,
          <implement>,
          label: "✗ fail",
          stroke: colors.error.accent + stroke-width,
          bend: -30deg,
        ),

        labeled-edge(
          <run-tests>,
          <write-tests>,
          label: "✗ missing test",
          stroke: colors.error.accent + stroke-width,
          bend: -30deg,
        ),

        labeled-edge(
          <benchmarks>,
          <implement>,
          label: "✗ too slow",
          stroke: colors.error.accent + stroke-width,
          bend: 30deg,
          label-pos: 0.3,
        ),

        workflow-step(
          (3, 1),
          "5",
          "Performance",
          ("Add benchmarks (criterion)", "Add profiling", "Find hotspots"),
          colors.operator,
          <benchmarks>,
        ),
      )
    }
  ]

  slide[
    == General principles
  ]

  slide(title: "Principles")[
    #align(horizon)[
      #grid(
        columns: (1fr, 1fr),
        rows: auto,
        gutter: 2em,
        [
          *Don't overuse streams:*
          - Keep pipelines short
          - Only _physical async data flow_
        ],
        [
          *Separation of concerns:*
          - Modular functions
          - Descriptive names
          - Split long functions
        ],

        [
          *Meaningful objective targets:*
          - Simple, clear unit tests
          - Relevant benchmarks
        ],
        [
          *Simple state machines:*
          1. Fewer `Option`s
          2. Fewer states

        ],
      )

      #v(2em)

      "Perfection is achieved, not when there is nothing more to add, but when there is *nothing left to take away*." — _Antoine de Saint-Exupéry_
    ]
  ]

  slide(title: "How to get started")[
    #set text(size: 7pt)
    #v(-4.2em)
    #styled-diagram(
      stroke-width: stroke-width + colors.data.accent,
      mark-scale: 80%,
      node-fill: colors.data.base,

      node((1.5, 0), [Stream processing style], name: <transform>),
      edge(<transform>, <control-flow>, [Traditional \ control flow], "-}>"),
      edge(<transform>, <standard>, [Stream \ operators], "-}>"),

      node(
        fill: colors.pin.base,
        stroke: colors.pin.accent + stroke-width,
        enclose: (
          <standard>,
          <futures-streamext>,
          <futures-rx>,
          <standard>,
          <rxjs>,
          <search-crates>,
          <build-trait>,
          <import-trait>,
        ),
        name: <stream-operators>,
      ),

      node(
        fill: colors.neutral.base,
        stroke: colors.neutral.accent + stroke-width,
        enclose: (<control-flow>, <unfold>, <async-stream>),
        name: <traditional>,
      ),

      node(
        (2.5, 3.5),
        text(size: 1.5em)[Always requires `Box` \ to make `!Unpin` \ output `Unpin` ],
        name: <dark-magic>,
        fill: colors.error.base,
        stroke: colors.error.accent + stroke-width,
      ),
      edge(<dark-magic>, <traditional>, "--"),
      node((0, 1), [Standard? \ e.g. N-1, 1-1], name: <standard>),

      edge(<standard>, <rxjs>, [No], "-}>"),
      node(
        (-0.5, 2),
        [`futures::` \ `StreamExt`],
        name: <futures-streamext>,
        fill: colors.operator.base,
        stroke: colors.operator.accent + stroke-width,
      ),
      edge(<standard>, <futures-streamext>, [Yes], "-}>"),
      node(
        (0.6, 2),
        [RxJs-like \ e.g. 1-N],
        name: <rxjs>,
        fill: colors.operator.base,
        stroke: colors.operator.accent + stroke-width,
      ),

      node(
        (-0.5, 3),
        [`futures-rx`],
        name: <futures-rx>,
        fill: colors.operator.base,
        stroke: colors.operator.accent + stroke-width,
      ),
      edge(<rxjs>, <futures-rx>, [Yes], "-}>"),

      node((0.6, 3), [Search \ crates.io], name: <search-crates>),
      edge(<rxjs>, <search-crates>, [No], "-}>"),

      node(
        (0, 4),
        [Build your \ own trait],
        name: <build-trait>,
        fill: colors.operator.base,
        stroke: colors.operator.accent + stroke-width,
      ),
      edge(<search-crates>, <build-trait>, [Does not exist], "-}>"),
      node(
        (1, 4),
        [Import \ extension trait],
        name: <import-trait>,
        fill: colors.operator.base,
        stroke: colors.operator.accent + stroke-width,
      ),
      edge(<search-crates>, <import-trait>, [Exists], "-}>"),
      node((2.5, 1), [Declarative], name: <control-flow>),
      edge(<control-flow>, <unfold>, "-}>", [Yes]),
      edge(<control-flow>, <async-stream>, "-}>", [No]),

      node(
        (2, 2),
        [`futures::` \ `stream::unfold`],
        name: <unfold>,
        fill: colors.stream.base,
        stroke: colors.stream.accent + stroke-width,
      ),

      node(
        (3, 2),
        [`async-stream` \ with `yield`],
        name: <async-stream>,
        fill: colors.stream.base,
        stroke: colors.stream.accent + stroke-width,
      ),
    )
  ]
}
