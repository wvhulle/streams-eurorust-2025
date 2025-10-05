#import "../lib/constants.typ": *
#import "../lib/diagram-helpers.typ": *
#import "@preview/fletcher:0.5.8" as fletcher: diagram, edge, node
#import fletcher.shapes: pill

#let stream-api-slides(slide) = {
  slide[
    == Using the `Stream` API
  ]

  slide(title: "Pipelines with `futures::StreamExt`")[
    #set text(size: 7pt)
    All basic stream operators are in #link("https://docs.rs/futures/latest/futures/stream/trait.StreamExt.html")[`futures::StreamExt`]


    #styled-diagram(
      spacing: (2.0em, 1.5em),

      node(
        (0, 2),
        [`iter(0..10)`],
        fill: colors.stream.base,
        stroke: colors.stream.accent + stroke-width,
        shape: circle,
        name: <op-iter>,
      ),
      node(
        (1, 2),
        [`map(*2)`],
        fill: colors.operator.base,
        stroke: colors.operator.accent + stroke-width,
        shape: rect,
        name: <op-map>,
      ),
      node(
        (2, 2),
        [`filter(>4)`],
        fill: colors.operator.base,
        stroke: colors.operator.accent + stroke-width,
        shape: rect,
        name: <op-filter>,
      ),
      node(
        (3, 2),
        [`enumerate`],
        fill: colors.operator.base,
        stroke: colors.operator.accent + stroke-width,
        shape: rect,
        name: <op-enum>,
      ),
      node(
        (4, 2),
        [`take(3)`],
        fill: colors.operator.base,
        stroke: colors.operator.accent + stroke-width,
        shape: rect,
        name: <op-take>,
      ),
      node(
        (5, 2),
        [`skip_while(<1)`],
        fill: colors.operator.base,
        stroke: colors.operator.accent + stroke-width,
        name: <op-skip>,
      ),

      node(
        (0, 1),
        [0,1,2,3...],
        fill: colors.data.base,
        stroke: colors.data.accent + stroke-width,
        shape: circle,
        name: <data-iter>,
      ),
      node(
        (1, 1),
        [0,2,4,6...],
        fill: colors.data.base,
        stroke: colors.data.accent + stroke-width,
        shape: rect,
        name: <data-map>,
      ),
      node(
        (2, 1),
        [6,8,10...],
        fill: colors.data.base,
        stroke: colors.data.accent + stroke-width,
        shape: rect,
        name: <data-filter>,
      ),
      node(
        (3, 1),
        [(0,6),(1,8)...],
        fill: colors.data.base,
        stroke: colors.data.accent + stroke-width,
        shape: rect,
        name: <data-enum>,
      ),
      node(
        (4, 1),
        [(0,6),(1,8),(2,10)],
        fill: colors.data.base,
        stroke: colors.data.accent + stroke-width,
        shape: rect,
        name: <data-take>,
      ),
      node(
        (5, 1),
        [(1,8),(2,10)],
        fill: colors.data.base,
        stroke: colors.data.accent + stroke-width,
        name: <data-skip>,
      ),

      node((0, 0), [source], shape: circle, name: <desc-iter>),
      node((1, 0), [multiply by 2], shape: rect, name: <desc-map>),
      node((2, 0), [keep if > 4], shape: rect, name: <desc-filter>),
      node((3, 0), [add index], shape: rect, name: <desc-enum>),
      node((4, 0), [take first 3], shape: rect, name: <desc-take>),
      node((5, 0), [skip while < 1], name: <desc-skip>),

      edge(<op-iter>, <op-map>, "->"),
      edge(<op-map>, <op-filter>, "->"),
      edge(<op-filter>, <op-enum>, "->"),
      edge(<op-enum>, <op-take>, "->"),
      edge(<op-take>, <op-skip>, "->"),

      edge(<op-iter>, <data-iter>, "-", stroke: (dash: "dashed")),
      edge(<op-map>, <data-map>, "-", stroke: (dash: "dashed")),
      edge(<op-filter>, <data-filter>, "-", stroke: (dash: "dashed")),
      edge(<op-enum>, <data-enum>, "-", stroke: (dash: "dashed")),
      edge(<op-take>, <data-take>, "-", stroke: (dash: "dashed")),
      edge(<op-skip>, <data-skip>, "-", stroke: (dash: "dashed")),

      edge(<data-iter>, <desc-iter>, "-", stroke: (dash: "dashed")),
      edge(<data-map>, <desc-map>, "-", stroke: (dash: "dashed")),
      edge(<data-filter>, <desc-filter>, "-", stroke: (dash: "dashed")),
      edge(<data-enum>, <desc-enum>, "-", stroke: (dash: "dashed")),
      edge(<data-take>, <desc-take>, "-", stroke: (dash: "dashed")),
      edge(<data-skip>, <desc-skip>, "-", stroke: (dash: "dashed")),
    )

    #align(center)[
      #text(size: 9pt)[
        ```rust
        stream::iter(0..10)
          .map(|x| x * 2)
          .filter(|&x| ready(x > 4))
          .enumerate().take(3).skip_while(|&(i, _)| i < 1)
        ```]
    ]
  ]

  slide(title: [The handy #link("https://doc.rust-lang.org/std/future/fn.ready.html")[`std::future::ready`] function])[
    The `futures::StreamExt::filter` expects an *async closure* (or closure returning `Future`):
    #text(size: 9pt)[
      #grid(
        columns: (1fr, 1fr),
        gutter: 1em,
        [
          *Option 1*: Async block (not `Unpin`!)
          ```rust
          stream.filter(|&x| async move {
            x % 2 == 0
          })
          ```

          *Option 2*: Async closure (not `Unpin`!)
          ```rs
          stream.filter(async |&x| x % 2 == 0)
          ```
        ],
        [
          #rect(fill: colors.stream.base, stroke: colors.stream.accent + stroke-width, radius: node-radius)[
            *Option 3* (recommended): Wrap sync output with `std::future::ready()`
            ```rust
            stream.filter(|&x| ready(x % 2 == 0))
            ```

            - `ready(value)` creates a `Future` that immediately resolves to `value`.

            - `ready(value)` is `Unpin` and *keeps pipelines `Unpin`*: *_easier to work with_*, see later.
          ]
        ],
      )]
  ]
}
