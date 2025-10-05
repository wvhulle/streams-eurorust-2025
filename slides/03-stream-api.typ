#import "../lib/constants.typ": *
#import "../lib/diagram-helpers.typ": *
#import "@preview/fletcher:0.5.8" as fletcher: diagram, edge, node
#import fletcher.shapes: pill

#let stream-api-slides(slide) = {
  slide[
    == Using the `Stream` API
  ]

  slide(title: [Pipelines with `futures::StreamExt`])[
    #set text(size: 7pt)
    All basic stream operators are in #link("https://docs.rs/futures/latest/futures/stream/trait.StreamExt.html")[`futures::StreamExt`]


    #styled-diagram(
      spacing: (2.0em, 1.5em),

      colored-node((0, 2), color: colors.stream, name: <op-iter>, shape: circle)[`iter(0..10)`],
      colored-node((1, 2), color: colors.operator, name: <op-map>)[`map(*2)`],
      colored-node((2, 2), color: colors.operator, name: <op-filter>)[`filter(>4)`],
      colored-node((3, 2), color: colors.operator, name: <op-enum>)[`enumerate`],
      colored-node((4, 2), color: colors.operator, name: <op-take>)[`take(3)`],
      colored-node((5, 2), color: colors.operator, name: <op-skip>)[`skip_while(<1)`],

      colored-node((0, 1), color: colors.data, name: <data-iter>, shape: circle)[0,1,2,3...],
      colored-node((1, 1), color: colors.data, name: <data-map>)[0,2,4,6...],
      colored-node((2, 1), color: colors.data, name: <data-filter>)[6,8,10...],
      colored-node((3, 1), color: colors.data, name: <data-enum>)[(0,6),(1,8)...],
      colored-node((4, 1), color: colors.data, name: <data-take>)[(0,6),(1,8),(2,10)],
      colored-node((5, 1), color: colors.data, name: <data-skip>)[(1,8),(2,10)],

      node((0, 0), [source], shape: circle, name: <desc-iter>, fill: none, stroke: none),
      node((1, 0), [multiply by 2], name: <desc-map>, fill: none, stroke: none),
      node((2, 0), [keep if > 4], name: <desc-filter>, fill: none, stroke: none),
      node((3, 0), [add index], name: <desc-enum>, fill: none, stroke: none),
      node((4, 0), [take first 3], name: <desc-take>, fill: none, stroke: none),
      node((5, 0), [skip while < 1], name: <desc-skip>, fill: none, stroke: none),

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
          #rect(fill: colors.stream, stroke: accent(colors.stream) + stroke-width, radius: node-radius)[
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
