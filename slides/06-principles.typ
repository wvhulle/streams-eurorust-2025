#import "../lib/constants.typ": *
#import "../lib/diagram-helpers.typ": *
#import "@preview/fletcher:0.5.8" as fletcher: diagram, edge, node

#let principles-slides(slide) = {
  slide[
    == General principles
  ]


  slide(title: "Rules of thumb")[
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
          2. More states

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
      stroke-width: stroke-width + colors.data,
      mark-scale: 80%,
      node-fill: colors.data,

      colored-node((1.5, 0), color: colors.data, name: <transform>)[Stream processing style],
      styled-edge(<transform>, <control-flow>, "-}>", label: [Traditional \ control flow]),
      styled-edge(<transform>, <standard>, "-}>", label: [Stream \ operators]),

      node(
        fill: colors.pin,
        stroke: accent(colors.pin) + stroke-width,
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
        fill: colors.neutral,
        stroke: accent(colors.neutral) + stroke-width,
        enclose: (<control-flow>, <unfold>, <async-stream>),
        name: <traditional>,
      ),

      colored-node(
        (2.5, 3.5),
        color: colors.error,
        name: <dark-magic>,
      )[Always requires `Box` \ to make `!Unpin` \ output `Unpin` ],
      styled-edge(<dark-magic>, <traditional>, "--"),
      colored-node((0, 1), color: colors.data, name: <standard>)[Standard? \ e.g. N-1, 1-1],

      styled-edge(<standard>, <rxjs>, "-}>", label: [No]),
      colored-node(
        (-0.5, 2),
        color: colors.operator,
        name: <futures-streamext>,
      )[`futures::` \ `StreamExt`],
      styled-edge(<standard>, <futures-streamext>, "-}>", label: [Yes]),
      colored-node(
        (0.6, 2),
        color: colors.operator,
        name: <rxjs>,
      )[RxJs-like \ e.g. 1-N],

      colored-node(
        (-0.5, 3),
        color: colors.operator,
        name: <futures-rx>,
      )[`futures-rx`],
      styled-edge(<rxjs>, <futures-rx>, "-}>", label: [Yes]),

      colored-node((0.6, 3), color: colors.data, name: <search-crates>)[Search \ crates.io],
      styled-edge(<rxjs>, <search-crates>, "-}>", label: [No]),

      colored-node(
        (0, 4),
        color: colors.operator,
        name: <build-trait>,
      )[Build your \ own trait],
      styled-edge(<search-crates>, <build-trait>, "-}>", label: [Does not exist]),
      colored-node(
        (1, 4),
        color: colors.operator,
        name: <import-trait>,
      )[Import \ extension trait],
      styled-edge(<search-crates>, <import-trait>, "-}>", label: [Exists]),
      colored-node((2.5, 1), color: colors.data, name: <control-flow>)[Declarative],
      styled-edge(<control-flow>, <unfold>, "-}>", label: [Yes]),
      styled-edge(<control-flow>, <async-stream>, "-}>", label: [No]),

      colored-node(
        (2, 2),
        color: colors.stream,
        name: <unfold>,
      )[`futures::` \ `stream::unfold`],

      colored-node(
        (3, 2),
        color: colors.stream,
        name: <async-stream>,
      )[`async-stream` \ with `yield`],
    )
  ]
}
