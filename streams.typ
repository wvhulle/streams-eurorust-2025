#import "template.typ": *
#import "@preview/codly:1.3.0": *
#import "@preview/codly-languages:0.1.8": *

#show: codly-init.with()

#codly(
  languages: codly-languages,
  zebra-fill: rgb("#f5f5f5"),
  radius: 0.5em,
)

#show: conference-theme.with(
  config-info(
    title: [Transforming `Stream`s],
    subtitle: [Advanced stream processing in Rust],
    author: [Willem Vanhulle],
    date: datetime.today(),
    institution: [EuroRust 2025],
    logo: align(right + top, image("willem-vanhulle-logo.svg", width: 2em)),
  ),
)

#set heading(numbering: "1.")

#title-slide()

= Introduction

== Me

#slide[

  #pause
  #grid(
    columns: (1fr, 1fr),
    column-gutter: 2em,
    [
      Lives in Ghent, Belgium:
      - Studied mathematics, physics and computer science
      - Biotech automation (fermentation)
      - Distributed systems (trains)
    ],
    [#pause
      Latest projects (github.com/wvhulle):

      - #link("SysGhent.be"): social network for systems programmers in Ghent (Belgium)
      - Clone-stream: lazy stream cloning library for Rust
    ],
  )
  #meanwhile
  #warning(title: "Motivation")[

    Processing data from moving vehicles


    1. Vehicle generates multiple data streams
    2. All streams converge to control system
  ]]

== Kinds of streams

#slide[
  #fletcher-diagram(
    spacing: (1em, 2em),
    layer(
      (0, 2),
      <physical>,
      "Physical streams",
      "Electronic signals",
      ("GPIO interrupts", "UART frames", "Network packets"),
      color: colors.data,
    ),

    pause,

    layer(
      (0, 1),
      <leaf>,
      "Leaf streams",
      "OS/kernel constraints",
      ([`tokio::fs::File`], [`TcpListener`], [`UnixStream`], [`Interval`]),
      color: colors.stream,
    ),

    styled-edge(<physical>, <leaf>, "->", color: colors.operator, label: "OS abstraction"),

    node(
      (-1, 1),
      name: <runtime-note>,
      [Requires an `async` runtime \ #text(size: 0.7em)[(see 'leaf future' by _Carl Fredrik Samson_)]],
      stroke: none,
    ),
    styled-edge(<runtime-note>, <leaf>, "->", color: colors.neutral),

    pause,

    layer(
      (0, 0),
      <operators>,
      "Stream operators",
      "Pure software transformations",
      ([`map()`], [*`double()`*], [*`fork()`*], [*`latency()`*], [*`hysteresis()`*]),
      color: colors.operator,
    ),

    styled-edge(<leaf>, <operators>, "->", color: colors.stream, label: "Stream operators"),

    node((-1, 0), name: <presentation-note>, [In this presentation], stroke: none),
    styled-edge(<presentation-note>, <operators>, "->", color: colors.neutral),

    node(
      (1, 2),
      name: <legend-data>,
      fill: none,
      stroke: none,
    )[ #box(width: 1em, height: 1em, rect(fill: colors.data, stroke: accent(colors.data))) Data],

    node(
      (1, 1),
      name: <legend-streams>,
      fill: none,
      stroke: none,
    )[ #box(width: 1em, height: 1em, rect(fill: colors.stream, stroke: accent(colors.stream))) Streams],

    node(
      (1, 0),
      name: <legend-operators>,
      fill: none,
      stroke: none,
    )[ #box(width: 1em, height: 1em, rect(fill: colors.operator, stroke: accent(colors.operator))) Operators],
  )

  #pause

  #align(center)[_Hardware signals are abstracted by the OS_]



  #align(center)[_Software operators transform the streams_]

]

== `Stream`s in Rust are not new


#slide[

  #align(center)[
    #cetz-canvas(length: 2cm, {
      import draw: *

      let draw-timeline-entry(y, year, event, description, reference, ref-url, color) = {
        rect(
          (1, y - 0.3),
          (3, y + 0.3),
          fill: color,
          stroke: accent(color) + stroke-width,
          radius: node-radius,
        )
        content((2, y), text(size: 0.7em, weight: "bold", year), anchor: "center")

        content((3.5, y + 0.2), text(size: 0.8em, weight: "bold", event), anchor: "west")
        content((3.5, y - 0.03), text(size: 0.6em, description), anchor: "west")
        content(
          (3.5, y - 0.24),
          link(ref-url, text(size: 0.6em, style: "italic", fill: accent(colors.stream), reference)),
          anchor: "west",
        )

        line((0.8, y), (1, y), stroke: accent(colors.neutral) + stroke-width)
      }

      line((0.8, 0.3), (0.8, 5.7), stroke: accent(colors.neutral) + arrow-width * 2)


      draw-timeline-entry(
        0.5,
        "1960s",
        "Dataflow Programming",
        "Hardware-level stream processing",
        "Early dataflow architectures",
        "https://en.wikipedia.org/wiki/Dataflow_programming",
        colors.error.lighten(20%),
      )


      draw-timeline-entry(
        1.5,
        "1973",
        "Unix Pipes",
        "Douglas McIlroy creates `|` operator",
        "Bell Labs, Unix v3-v4",
        "https://www.cs.dartmouth.edu/~doug/reader.pdf",
        colors.data.lighten(40%),
      )


      draw-timeline-entry(
        2.5,
        "1978",
        "Communicating Sequential Processes",
        "Tony Hoare formalizes concurrent dataflow",
        "CACM 21(8):666-677",
        "https://dl.acm.org/doi/10.1145/359576.359585",
        colors.action.lighten(35%),
      )

      (pause,)

      draw-timeline-entry(
        3.5,
        "1997",
        "Functional Reactive Programming",
        "Conal Elliott & Paul Hudak (Haskell)",
        "ICFP '97, pp. 263-273",
        "https://dl.acm.org/doi/10.1145/258948.258973",
        colors.state.lighten(25%),
      )

      (pause,)

      draw-timeline-entry(
        4.5,
        "2009",
        "Microsoft Reactive Extensions",
        "ReactiveX brings streams to mainstream",
        "Erik Meijer, Microsoft",
        "https://reactivex.io/",
        colors.operator.lighten(30%),
      )

      (pause,)

      draw-timeline-entry(
        5.5,
        "2019",
        "async/await stabilized in Rust",
        "Stable async streams in std",
        "RFC 2394, Rust 1.39.0",
        "https://rust-lang.github.io/rfcs/2394-async_await.html",
        colors.stream.lighten(20%),
      )
    })
  ]
]
== Why does Rust need special treatment?


#slide[


  Stream operators must wrap and own their input by value

  #styled-diagram(
    spacing: (4em, 2em),
    node-inset: 2pt,
    node-fill: colors.state,
    stroke-width: stroke-width + colors.state,
    node-shape: circle,
    {
      colored-node((0, 1.2), color: none, name: <gc-title>)[*GC Languages*]
      colored-node((0, 0.5), color: colors.state, name: <gc>, stroke-width: 1.5pt, shape: circle)[GC]
      colored-node((-0.5, -0.3), color: colors.stream, name: <gc-d1>)[•]
      colored-node((0, -0.5), color: colors.stream, name: <gc-d2>)[•]
      colored-node((0.5, -0.2), color: colors.stream, name: <gc-d3>)[•]
      colored-node(
        (0, -1.2),
        color: none,
        name: <gc-caption>,
      )[Data flows freely,\ GC handles cleanup]
      node(
        fill: colors.neutral,
        stroke: accent(colors.neutral) + stroke-width,
        shape: rect,
        inset: 0.7em,
        enclose: (<gc-title>, <gc>, <gc-d1>, <gc-d2>, <gc-d3>, <gc-caption>),
      )

      colored-node((1.5, 0.3), color: none)[*vs*]

      node(
        fill: colors.stream,
        stroke: accent(colors.stream) + stroke-width,
        shape: fletcher.shapes.rect,
        inset: 0.7em,
        enclose: (
          <rust-title>,
          <owner>,
          <owner-label>,
          <moved>,
          <moved-label>,
          <borrowed>,
          <borrow-label>,
          <rust-caption>,
        ),
      )

      colored-node((3, 1.2), color: none, name: <rust-title>)[*Rust*]
      colored-node((2.7, 0.2), color: colors.stream, name: <owner>, stroke-width: 1pt)[•]
      colored-node((2.7, 0.6), color: none, name: <owner-label>)[#text(size: 6pt)[Owner]]
      colored-node((3.5, 0.2), color: colors.stream, name: <moved>, stroke-width: 1pt)[•]
      colored-node((3.5, 0.6), color: none, name: <moved-label>)[#text(size: 6pt)[Moved]]
      colored-node((3.5, -0.5), color: colors.stream, name: <borrowed>, stroke-width: 1pt)[•]
      colored-node((3.5, -0.9), color: none, name: <borrow-label>)[#text(size: 6pt)[Borrow]]
      colored-node(
        (3, -1.5),
        color: none,
        name: <rust-caption>,
        shape: rect,
      )[Explicit ownership,\ tracked at compile time]

      styled-edge(<owner>, <moved>, color: colors.stream, stroke-width: 1.5pt)
      edge(<owner>, <borrowed>, "->", stroke: (paint: accent(colors.stream), thickness: 1.5pt, dash: "dashed"))

      node(fill: colors.action, stroke: accent(colors.action) + stroke-width, enclose: (
        <rust-title>,
        <owner>,
        <owner-label>,
        <moved>,
        <moved-label>,
        <borrowed>,
        <borrow-label>,
        <rust-caption>,
      ))
    },
  )
]

== Process TCP connections and collect long messages

#slide[
  #codly(
    highlights: (
      (line: 3, fill: red.lighten(80%)), // First match nesting
      (line: 5, fill: red.lighten(70%)), // Second match nesting
      (line: 6, fill: red.lighten(60%)), // Third level nesting
    ),
  )
  #grid(
    columns: (1fr, 0.4fr),
    column-gutter: 1em,
    [
      #set text(size: 0.6em)
      ```rust
      let mut results = Vec::new(); let mut count = 0;
      while let Some(connection) = tcp_stream.next().await {
          match connection {
              Ok(stream) if should_process(&stream) => {
                  match process_stream(stream).await {
                      Ok(msg) if msg.len() > 10 => {
                          results.push(msg);
                          count += 1;
                          if count >= 5 { break; }
                      }
                      Ok(_) => continue,
                      Err(_) => continue,
                  }
              }
              Ok(_) => continue,
              Err(_) => continue,
          }
      }
      ```],
    align(horizon)[
      *Problems:*
      - Deeply nested
      - Hard to read
      - Cannot test pieces independently
    ],
  )
  #codly-reset()
]

== `Stream` operators: declarative & composable

#slide[
  #set text(size: 0.9em)
  Same logic with stream operators:

  #codly(
    highlights: (
      (line: 2, fill: green.lighten(80%)), // filter_map
      (line: 3, fill: green.lighten(80%)), // filter
      (line: 4, fill: green.lighten(80%)), // then
      (line: 5, fill: green.lighten(80%)), // filter_map
      (line: 6, fill: green.lighten(80%)), // filter
      (line: 7, fill: blue.lighten(80%)), // take
      (line: 8, fill: blue.lighten(80%)), // collect
    ),
  )
  #grid(
    columns: (1fr, 0.4fr),
    column-gutter: 1em,
    ```rust
    let results: Vec<String> = tcp_stream
        .filter_map(|conn| ready(conn.ok()))
        .filter(|stream| ready(should_process(stream)))
        .then(|stream| process_stream(stream))
        .filter_map(|result| ready(result.ok()))
        .filter(|msg| ready(msg.len() > 10))
        .take(5)
        .collect()
        .await;
    ```,
    align(horizon)[
      *Benefits:*
      - Each operation is isolated
      - Testable
      - Reusable
    ],
  )
  #codly-reset()

  #quote(attribution: [Abelson & Sussman])[Programs must be written *for people to read*]
]

= Rust's `Stream` trait

== Moving from `Iterator` to `Stream`

#slide[
  #set text(size: 0.8em)
  #styled-diagram(
    spacing: (0.7em, 1em),

    title-node((0.5, 0), text(size: 0.7em)[✓ Always returns immediately]),
    title-node((3.5, 0), [⚠️ May be Pending]),
    title-node((6.5, 0), [✓ Hides polling complexity]),

    pause,

    title-node((0.5, 5), text(weight: "bold")[Iterator (sync)]),

    colored-node((0, 1), color: colors.action, name: <iter-call4>)[`next()`],
    styled-edge(<iter-call4>, <iter-result2>),
    colored-node((0, 2), color: colors.action, name: <iter-call3>)[`next()`],
    styled-edge(<iter-call3>, <iter-result3>),
    colored-node((0, 3), color: colors.action, name: <iter-call2>)[`next()`],
    styled-edge(<iter-call2>, <iter-result4>),
    colored-node((0, 4), color: colors.action, name: <iter-call1>)[`next()`],
    styled-edge(<iter-call1>, <iter-result1>),

    colored-node((1, 1), color: colors.data, name: <iter-result2>)[`Some(3)`],
    colored-node((1, 2), color: colors.data, name: <iter-result3>)[`Some(1)`],
    colored-node((1, 3), color: colors.data, name: <iter-result4>)[`None`],
    colored-node((1, 4), color: colors.data, name: <iter-result1>)[`Some(2)`],

    pause,

    title-node((3.5, 5), text(weight: "bold")[Stream (low-level)]),

    colored-node((3, 1), color: colors.action, name: <stream-call4>)[`poll_next()`],
    styled-edge(<stream-call4>, <stream-result4>),
    colored-node((3, 2), color: colors.action, name: <stream-call3>)[`poll_next()`],
    styled-edge(<stream-call3>, <stream-result3>),
    colored-node((3, 3), color: colors.action, name: <stream-call2>)[`poll_next()`],
    styled-edge(<stream-call2>, <stream-result2>),
    colored-node((3, 4), color: colors.action, name: <stream-call1>)[`poll_next()`],
    styled-edge(<stream-call1>, <stream-result1>),

    colored-node((4, 1), color: colors.data, name: <stream-result4>)[`Ready(Some(2))`],
    colored-node((4, 2), color: colors.state, name: <stream-result3>)[`Pending`],
    colored-node((4, 3), color: colors.data, name: <stream-result2>)[`Ready(Some(1))`],
    colored-node((4, 4), color: colors.state, name: <stream-result1>)[`Pending`],

    pause,

    node(
      stroke: stroke-width + accent(colors.stream),
      fill: colors.stream,

      inset: 1em,
      shape: rect,
      radius: 0.7em,
      enclose: (
        <stream-call1>,
        <stream-call2>,
        <stream-call3>,
        <stream-call4>,
        <stream-result1>,
        <stream-result2>,
        <stream-result3>,
        <stream-result4>,
        <async-call1>,
        <async-call2>,
        <async-call3>,
        <async-call4>,
        <async-result1>,
        <async-result2>,
        <async-result3>,
        <async-result4>,
      ),
    ),

    title-node((6.5, 5), text(weight: "bold")[Stream (high-level)]),

    colored-node((6, 1), color: colors.action, name: <async-call4>)[`next().await`],
    styled-edge(<async-call4>, <async-result2>),
    colored-node((6, 2), color: colors.action, name: <async-call3>)[`next().await`],
    styled-edge(<async-call3>, <async-result3>),
    colored-node((6, 3), color: colors.action, name: <async-call2>)[`next().await`],
    styled-edge(<async-call2>, <async-result4>),
    colored-node((6, 4), color: colors.action, name: <async-call1>)[`next().await`],
    styled-edge(<async-call1>, <async-result1>),

    colored-node((7, 1), color: colors.data, name: <async-result2>)[`Some(3)`],
    colored-node((7, 2), color: colors.data, name: <async-result3>)[`Some(1)`],
    colored-node((7, 3), color: colors.data, name: <async-result4>)[`None`],
    colored-node((7, 4), color: colors.data, name: <async-result1>)[`Some(2)`],
  )

  #v(1em)

  #legend((
    (color: colors.action, label: [Actions]),
    (color: colors.data, label: [Data values]),
    (color: colors.state, label: [State]),
    (color: colors.stream, label: [Stream]),
  ))
]

== The `Stream` trait: async iterator

#slide[
  Like `Future`, but yields *multiple items* over time when polled:

  #codly(
    highlights: (
      (line: 4, fill: yellow.lighten(80%)), // poll_next signature
      (line: 5, fill: yellow.lighten(80%)), // return type
    ),
  )
  ```rust
  trait Stream {
      type Item;

      fn poll_next(self: Pin<&mut Self>, cx: &mut Context<'_>)
          -> Poll<Option<Self::Item>>;
  }
  ```
  #codly-reset()

  The `Poll<Option<Item>>` return type:

  - `Poll::Pending` - not ready yet, try again later
  - `Poll::Ready(Some(item))` - here's the next item
  - `Poll::Ready(None)` - stream is exhausted (no more items *right now*)
]

== Possible inconsistency

#slide[
  ```rs
  trait Stream {
      type Item;

      fn poll_next(self: Pin<&mut Self>, cx: &mut Context)
          -> Poll<Option<Self::Item>>
    }
  ```

  #warning[
    What about Rust rule `self` needs to be `Deref<Target=Self>`?
  ]

  `Pin<&mut Self>` only implements `Deref<Target=Self>` for `Self: Unpin`.

  Problem? No, `Pin` is an exception in the compiler.
]




== The meaning of `Ready(None)`

#slide[
  #align(horizon + center)[
    #grid(
      columns: (1fr, 1fr),
      gutter: 3em,
      [
        #align(center)[*Regular Stream*]

        "No items *right now*"

        (_Stream might yield more later_)
      ],
      [
        #align(center)[*Fused Stream*]

        "No items *ever again*"

        (_Stream is permanently done_)
      ],
    )
  ]
]

== 'Fusing' `Stream`s and `Future`s

#slide[
  #align(center + horizon)[
    #let draw-arrow(multiple: false, fused: false, color) = {
      cetz-canvas(length: 1.8cm, {
        import draw: *
        let arrow-width = 2 * arrow-width
        if multiple {
          if fused {
            line((-0.8, 0), (0.6, 0), stroke: accent(color) + arrow-width)
            line((0.8, -0.3), (0.8, 0.3), stroke: accent(color) + (arrow-width))
          } else {
            line((-0.8, 0), (0.8, 0), stroke: accent(color) + arrow-width, mark: (end: "barbed"))
          }
          for i in range(if fused { 4 } else { 3 }) {
            let dash-x = -0.6 + i * 0.4
            line((dash-x, -0.15), (dash-x, 0.15), stroke: accent(color) + (arrow-width))
          }
        } else {
          line((-0.8, 0), (0.3, 0), stroke: accent(color) + arrow-width)
          line((0, -0.2), (0, 0.2), stroke: accent(color) + (arrow-width * 1.5))
          if fused {
            line((0.3, 0), (0.6, 0), stroke: accent(color) + arrow-width)
            line((0.8, -0.3), (0.8, 0.3), stroke: accent(color) + (arrow-width))
          } else {
            line((0.3, 0), (0.8, 0), stroke: accent(color) + arrow-width, mark: (end: "barbed"))
          }
        }
      })
    }

    #grid(
      columns: (auto, 1fr, 1fr, 2fr),
      rows: (auto, auto, auto, auto, auto),
      gutter: 2em,
      [], [*`Future`*], [*`Stream`*], [*Meaning*],
      [*Regular*],
      [#draw-arrow(multiple: false, fused: false, blue)],
      [#draw-arrow(multiple: true, fused: false, green)],
      [May continue],

      [*Fused*], [*`FusedFuture`*], [*`FusedStream`*], [`is_terminated()` method],

      [*Fused*],
      [#draw-arrow(multiple: false, fused: true, blue)],
      [#draw-arrow(multiple: true, fused: true, green)],
      [Done permanently],

      [*Fused value*], [`Pending`], [`Ready(None)`], [Final value],
    )
  ]
]

= Using `Stream`s

== Pipelines with `futures::StreamExt`

#slide[
  All basic stream operators are in #link("https://docs.rs/futures/latest/futures/stream/trait.StreamExt.html")[`futures::StreamExt`]

  #styled-diagram(
    spacing: (0.4em, 1.2em),

    // Source stream
    colored-node((0, 2), color: colors.stream, name: <op-iter>, shape: circle)[`iter(0..10)`],
    colored-node((0, 1), color: colors.data, name: <data-iter>, shape: circle)[0,1,2,3...],
    node((0, 0), [source], shape: circle, name: <desc-iter>, fill: none, stroke: none),
    edge(<op-iter>, <data-iter>, "-", stroke: (dash: "dashed")),
    edge(<data-iter>, <desc-iter>, "-", stroke: (dash: "dashed")),

    pause,

    // Map operator
    colored-node((1, 2), color: colors.operator, name: <op-map>)[`map(*2)`],
    colored-node((1, 1), color: colors.data, name: <data-map>)[0,2,4,6...],
    node((1, 0), [multiply by 2], name: <desc-map>, fill: none, stroke: none),
    edge(<op-iter>, <op-map>, "->"),
    edge(<op-map>, <data-map>, "-", stroke: (dash: "dashed")),
    edge(<data-map>, <desc-map>, "-", stroke: (dash: "dashed")),

    pause,

    // Filter operator
    colored-node((2, 2), color: colors.operator, name: <op-filter>)[`filter(>4)`],
    colored-node((2, 1), color: colors.data, name: <data-filter>)[6,8,10...],
    node((2, 0), [keep if > 4], name: <desc-filter>, fill: none, stroke: none),
    edge(<op-map>, <op-filter>, "->"),
    edge(<op-filter>, <data-filter>, "-", stroke: (dash: "dashed")),
    edge(<data-filter>, <desc-filter>, "-", stroke: (dash: "dashed")),

    pause,

    // Enumerate operator
    colored-node((3, 2), color: colors.operator, name: <op-enum>)[`enumerate`],
    colored-node((3, 1), color: colors.data, name: <data-enum>)[(0,6),(1,8)...],
    node((3, 0), [add index], name: <desc-enum>, fill: none, stroke: none),
    edge(<op-filter>, <op-enum>, "->"),
    edge(<op-enum>, <data-enum>, "-", stroke: (dash: "dashed")),
    edge(<data-enum>, <desc-enum>, "-", stroke: (dash: "dashed")),

    pause,

    // Take operator
    colored-node((4, 2), color: colors.operator, name: <op-take>)[`take(3)`],
    colored-node((4, 1), color: colors.data, name: <data-take>)[(0,6),(1,8),(2,10)],
    node((4, 0), [take first 3], name: <desc-take>, fill: none, stroke: none),
    edge(<op-enum>, <op-take>, "->"),
    edge(<op-take>, <data-take>, "-", stroke: (dash: "dashed")),
    edge(<data-take>, <desc-take>, "-", stroke: (dash: "dashed")),

    pause,

    // Skip operator
    colored-node((5, 2), color: colors.operator, name: <op-skip>)[`skip_while(<1)`],
    colored-node((5, 1), color: colors.data, name: <data-skip>)[(1,8),(2,10)],
    node((5, 0), [skip while index < 1], name: <desc-skip>, fill: none, stroke: none),
    edge(<op-take>, <op-skip>, "->"),
    edge(<op-skip>, <data-skip>, "-", stroke: (dash: "dashed")),
    edge(<data-skip>, <desc-skip>, "-", stroke: (dash: "dashed")),
  )


  #align(center)[
    #text(size: 0.7em)[
      ```rust
      stream::iter(0..10)
        .map(|x| x * 2)
        .filter(|&x| ready(x > 4))
        .enumerate()
        .take(3)
        .skip_while(|&(i, _)| i < 1)
      ```]
  ]
]

== The handy #link("https://doc.rust-lang.org/std/future/fn.ready.html")[`std::future::ready`] function

#slide[
  The `futures::StreamExt::filter` expects an *async closure* (or closure returning `Future`):

  #text(size: 0.8em)[
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

          - `ready(value)` is `Unpin`
        ]
      ],
    )
  ]

  #info(title: [The `ready` trick])[`ready` keeps pipelines `Unpin`*: *_easier to work with_]
]

== Flatten a *finite collection* of `Stream`s

#slide[
  A finite collection of `Stream`s = `IntoIterator<Item: Stream>`

  ```rust
  let streams = vec![
      stream::iter(1..=3),
      stream::iter(4..=6),
      stream::iter(7..=9),
  ];

  let merged = stream::select_all(streams);
  ```

  1. Creates a `FuturesUnordered` of the streams
  2. Polls all streams concurrently
  3. Yields items as they arrive
]

== Flattening an infinite stream

#slide[
  *Beware!*: `flatten()` on a stream of infinite streams will never complete!

  ```rs
  let infinite_streams = stream::unfold(0, |id| async move {
      Some((stream::iter(id..), id + 1))
  });
  let flat = infinite_streams.flatten();
  ```

  Instead, *buffer streams* concurrently with `flatten_unordered()`.

  ```rust
  let requests = stream::unfold(0, |id| async move {
      Some((fetch_stream(format!("/api/data/{}", id)), id + 1))
  });
  let flat = requests.flatten_unordered(Some(10));
  ```
]

== More `Stream` features to explore

#slide[
  Many more advanced topics await:

  - *Boolean operations*: `any`, `all`
  - *Async operations*: `then`
  - *`Sink`s*: The write-side counterpart to `Stream`s

  #{
    let endpoint(pos, color, name, content) = node(
      pos,
      content,
      fill: color,
      stroke: accent(color) + stroke-width,
      name: name,
    )
    let data-item(pos, name, content) = node(
      pos,
      content,
      fill: colors.data,
      stroke: accent(colors.data) + stroke-width,
      shape: fletcher.shapes.circle,
      name: name,
    )
    let label(pos, content) = node(pos, content, fill: none, stroke: none)

    styled-diagram(
      spacing: (6em, 2em),
      {
        endpoint((0, 1), colors.stream, <stream>)[Stream]
        data-item((1, 1), <data-a>)['a']
        data-item((1.5, 1), <data-b>)['b']
        data-item((2, 1), <data-c>)['c']
        endpoint((3, 1), colors.action, <sink>)[Sink]

        edge(<stream>, <data-a>, "-")
        edge(<data-a>, <data-b>, "-")
        edge(<data-b>, <data-c>, "-")
        edge(<data-c>, <sink>, "->", label: [`.forward()`])

        label((0, 1.7))[Read side]
        label((3, 1.7))[Write side]
      },
    )
  }
]

= Example 1: $1 -> 1$ Operator

== Doubling stream operator

#slide[
  #align(center + horizon)[
    Very simple `Stream` operator that *doubles every item* in an input stream:

    #styled-diagram(
      spacing: (4em, 1em),

      stream-node((0, 0), <in>)[Input\ Stream],
      colored-node(
        (1, 0),
        color: colors.operator,
        name: <double>,
        shape: fletcher.shapes.pill,
      )[`Double`],
      stream-node((2, 0), <out>)[Output\ Stream],

      styled-edge(<in>, <double>, label: [1, 2, 3, ...], "->", color: colors.data),
      styled-edge(<double>, <out>, label: [2, 4, 6, ...], "->", color: colors.data),
    )

    Input stream *needs to yield integers*.
  ]
]


#slide[
  *Step 1:* Define a struct that wraps the input stream

  #codly(
    highlights: (
      (line: 2, fill: blue.lighten(85%)), // in_stream field
    ),
  )
  ```rust
  struct Double<InSt> {
      in_stream: InSt,
    }
  ```
  #codly-reset()

  - Generic over stream type (works with any backend)
  - Stores input stream by value
]


#slide[
  *Step 2:* Implement `Stream` trait with bounds

  #codly(
    highlights: (
      (line: 3, fill: yellow.lighten(85%)), // where clause
      (line: 7, fill: green.lighten(85%)), // poll_next signature
    ),
  )
  ```rs
  impl<InSt> Stream for Double<InSt>
  where
      InSt: Stream<Item = i32>
  {
      type Item = i32;

      fn poll_next(self: Pin<&mut Self>, cx: &mut Context<'_>)
          -> Poll<Option<Self::Item>> {
          // ... implementation goes here
      }
    }
  ```
  #codly-reset()
]

== Naive implementation of `poll_next`

#slide[
  Focus on the implementation of the `poll_next` method

  (Remember that `Self = Double<InSt>` with field `in_stream: InSt`):

  ```rust
  fn poll_next(self: Pin<&mut Self>, cx: &mut Context<'_>)
      -> Poll<Option<Self::Item>> {
            // Cannot access self.in_stream!
            Pin::new(&mut self.in_stream) // Not possible!
                .poll_next(cx)
                .map(|x| x * 2)
    }
  ```

  `Pin<&mut Self>` *blocks access to `self.in_stream`* (when `Self: !Unpin`)!
]


#slide[


  #warning[We have `Pin<&mut Double>`.

    How can we obtain `Pin<&mut InSt>` to call `poll_next()`?]

  #align(center + horizon)[

    #cetz-canvas(length: 2.2cm, {
      import draw: *

      hexagon(draw, (1, 2), 3, color: colors.pin)[`Pin<&mut Double>`]
      styled-circle(draw, (1, 2), colors.operator, radius: 0.8)[`&mut Double`]

      styled-circle(draw, (1, 2), colors.stream, radius: 0.4)[`InSt`]

      styled-line(draw, (2.7, 2), (3.5, 2), colors.pin, mark: (end: "barbed"))
      styled-content(draw, (3, 2.4), colors.pin)[?]

      styled-circle(draw, (4, 2), colors.stream, radius: 0.4)[`InSt`]

      styled-line(draw, (4.5, 2), (5.3, 2), colors.pin, mark: (end: "barbed"))
      styled-content(draw, (5, 2.4), colors.pin, [?])

      hexagon(draw, (6.5, 2), 2, color: colors.pin)[`Pin<&mut InSt>`]
      styled-circle(draw, (6.5, 2), colors.stream, radius: 0.4)[`InSt`]

      styled-line(draw, (7.7, 2), (8.5, 2), colors.action, mark: (end: "barbed"))
      styled-content(draw, (8, 2.4), colors.action, anchor: "north-west")[`Stream::poll_next()`]
    })


    #legend((
      (color: colors.pin, label: [Pin types]),
      (color: colors.operator, label: [Operators]),
      (color: colors.stream, label: [Streams]),
      (color: colors.action, label: [Actions]),
    ))
  ]
]



#slide[
  #set text(size: 0.8em)
  Can we use `Pin::get_mut()` to unwrap and re-wrap?

  ```rs
  impl<InSt> Stream for Double<InSt> where InSt: Stream<Item = i32> {

    type Item = InSt::Item;

    fn poll_next(self: Pin<&mut Self>, cx: &mut Context<'_>)
        -> Poll<Option<Self::Item>> {
      let this = self.get_mut();  // Error!
      let pinned_in = Pin::new(&mut this.in_stream);
      pinned_in.poll_next(cx).map(|p| p.map(|x| x * 2))
    }
    }
  ```

  *Problem:* `Pin::get_mut()` requires `Double<InSt>: Unpin`

  But _*`Double<InSt>` is `!Unpin`* when `InSt: !Unpin`_!
]

== Why does `Pin::get_mut()` require `Unpin`?

#slide[
  `Pin<P>` makes a promise: *the pointee will never move again*.

  #align(center)[
    #styled-diagram(
      spacing: (2em, 1.5em),

      colored-node((0, 0), color: colors.pin, name: <pin>)[`Pin<&mut T>`],

      colored-node((1, 1), color: colors.action, name: <getmut>)[`.get_mut()`],

      colored-node((2, 2), color: colors.data, name: <mut>)[`&mut T`],

      colored-node((3, 3), color: colors.error, name: <swap>)[`mem::swap()`],

      colored-node((4, 4), color: colors.error, name: <moved>)[Value moved!],

      styled-edge(<pin>, <getmut>, "-", color: colors.pin, label: [_unpinning_ `T`]),
      styled-edge(<getmut>, <mut>, "->", color: colors.pin, label: [gives]),
      styled-edge(<mut>, <swap>, "->", color: colors.error, label: "allows"),
      styled-edge(<swap>, <moved>, "->", color: colors.error, label: [breaks `Pin` \ contract promise]),
    )
  ]

  #warning(title: [Solution])[Only allow `get_mut()` when `T: Unpin` (moving is safe).]
]

== `Unpin` types can be safely unpinned

#slide[
  #show "🐦": it => text(size: 3em)[#it]


  #cetz-canvas(length: 2.8cm, {
    import draw: *
    let bird-color = colors.data.darken(100%)
    styled-content(draw, (1, 2.5), bird-color)[🐦]
    styled-content(draw, (1, 2.0), bird-color)[`Unpin` Bird]
    styled-content(draw, (1, 1.6), bird-color)[Safe to move]

    (pause,)

    hexagon(
      draw,
      (8.5, 2.3),
      2.5,
      color: colors.pin,
    )[`Pin<&mut Bird>`]

    (pause,)

    styled-line(draw, (1.8, 2.7), (7.2, 2.7), colors.pin, mark: (end: "barbed"))
    styled-content(draw, (4.5, 3.0), colors.pin)[`Pin::new()`]

    (pause,)

    hexagon(
      draw,
      (8.5, 2.3),
      2.5,
      color: colors.pin,
    )[`Pin<&mut Bird>`]
    styled-content(draw, (8.5, 2.8), bird-color)[🐦]
    styled-content(draw, (8.5, 2.2), bird-color)[`Unpin` Bird]
    styled-content(draw, (8.5, 1.6), bird-color)[Moving won't\ break anything]
    (pause,)
    styled-line(draw, (7.2, 1.7), (1.8, 1.7), colors.pin, mark: (end: "barbed"))
    styled-content(draw, (4.5, 2.0), colors.pin)[`Pin::get_mut()`]


    (pause,)
    styled-content(draw, (4.5, 2.4), colors.pin)[Always safe if `Bird: Unpin`]
  })

  If `T: Unpin`, then `Pin::get_mut()` is safe because moving `T` doesn't cause UB.
]


#slide[
  *Examples of `Unpin` types:*

  - `i32`, `String`, `Vec<T>` - all primitive and standard types
  - `Box<T>` - pointers are safe to move
  - `&T`, `&mut T` - references are safe to move

    *Why safe?*

    These types don't have self-referential pointers. Moving them in memory doesn't invalidate any internal references.

    #info[Almost all types are `Unpin` by default!]
]

== `!Unpin` types cannot be unpinned


#slide[
  #show "🐅": it => text(size: 3em)[#it]

  #cetz-canvas(length: 2.8cm, {
    import draw: *
    let tiger-color = colors.neutral.darken(100%)
    styled-content(draw, (1, 2.8), tiger-color)[🐅]
    styled-content(draw, (1, 2.0), tiger-color)[`!Unpin` Tiger]
    styled-content(draw, (1, 1.6), tiger-color)[Dangerous to move]

    styled-line(draw, (2.5, 2.8), (6.5, 1.8), colors.error)
    styled-line(draw, (2.5, 1.8), (6.5, 2.8), colors.error)

    styled-content(draw, (4.5, 1.5), colors.error)[Would break \ pin promise!]
    styled-content(draw, (4.5, 2.5), colors.pin)[`Pin::get_mut()` \ gives `&mut T`]

    hexagon(
      draw,
      (8.5, 2.3),
      2.5,
      color: colors.pin,
    )[`Pin<&mut Tiger>`]
    styled-content(draw, (8.5, 2.8), tiger-color)[🐅]
    styled-content(draw, (8.5, 2.2), tiger-color)[`!Unpin` Tiger]
    styled-content(draw, (8.5, 1.6), tiger-color)[Moving would\ cause UB]
  })
]


#slide[
  *Examples of `!Unpin` types:*

  - `PhantomPinned` - explicitly opts out of `Unpin`
  - Most `Future` types (self-ref. state machines)
  - Types with self-referential pointers
  - `Double<InSt>` where `InSt: !Unpin`

    *Why unsafe?*

    These types may contain pointers to their own fields. Moving them in memory would invalidate those internal pointers, causing use-after-free.

    #info[`!Unpin` is rare and usually intentional for async/self-referential types.]
]

== Following compiler hints

#slide[
  The compiler error suggests adding `InSt: Unpin`:

  #text(size: 0.7em)[
    ```rs
    impl<InSt> Stream for Double<InSt> where InSt: Stream<Item = i32> + Unpin {
      type Item = InSt::Item;

      fn poll_next(self: Pin<&mut Self>, cx: &mut Context<'_>) ->  Poll<Option<Self::Item>> {
        // `this` = a conventional name for `get_mut` output
        let mut this = self.get_mut();
        let pinned_in = Pin::new(&mut this.in_stream);
        pinned_in
          .poll_next(cx)
          .map(|p| p.map(|x| x * 2))
      }
    }
    ```
  ]
  #pause
  #warning[This is a common, misleading compiler hint and *not the right solution*!]

]




#slide[
  Instead of mindlessly following the compiler suggestion:


  #info[#align(
    left,
  )[Accept that `!Unpin` things are a fact of life and ask your users to pin stream operators (or futures and other raw `!Unpin` types):

    - On the stack with the `pin!` macro
    - On the heap with `Box::new()`
  ]]

  #pause

  Instead of forcing customers of our API to know what `Unpin` means, I decided to "fix" the problem upstream and pin on the heap.

  #pause

  #warning[Pinning the original stream on the heap is not a *real* / idiomatic Rust solution! (-0-30% runtime performance)]

]

== Turning `!Unpin` into `Unpin` with boxing

#slide[
  #align(center)[
    #set text(size: 0.8em)
    #cetz-canvas(length: 2.2cm, {
      import draw: *
      content((2.5, 5.5), text(weight: "bold")[Stack], anchor: "center")

      styled-rect(draw, (1, 3), (4, 5), colors.neutral, radius: node-radius)[]
      styled-rect(draw, (1.9, 3.5), (3, 4.5), colors.data)[pointer `0X1234` \ (memory address)]
      content((2.5, 3.3), [`Unpin` = Safe to move], anchor: "center")


      content((5.25, 4.3), [`Box::new(in_stream)` \ dereferences to], anchor: "center")


      styled-triangle(draw, (6.0, 3), (10, 3), (8, 5), colors.neutral)[]

      content((8, 5.3), text(weight: "bold", [Heap]), anchor: "center")


      styled-circle(draw, (8., 3.7), colors.stream, radius: 0.5)[`[0X1234]`: `InSt`]

      content((11.5, 5.0), text(size: 2em, "🐅"), anchor: "center")
      content((11.5, 4.0), text(weight: "bold", [`!Unpin` Tiger]), anchor: "center")
      arc(
        (10.5, 5.2),
        start: 60deg,
        stop: 160deg,
        radius: 1.5,
        mark: (end: "barbed"),
        stroke: accent(colors.error) + arrow-width,
      )

      styled-line(draw, (3.1, 4), (7.3, 3.7), colors.neutral, mark: (end: "barbed"))
    })
  ]

  #grid(
    columns: (1fr, 1fr),
    column-gutter: 1em,
    [

      *Nice to have*:

      1. `Box::new(tiger)` produces just a pointer on the stack
        - Moving pointers is always safe
        - Therefore: *`Box<Tiger>: Unpin`*

      2. Box dereferences to its contents
        - *`Box<X>: Deref<Target = X>`*

    ],

    [
      *Problem:* Need `Pin<&mut InSt>`, but `Box<InSt>` requires `InSt: Unpin` to create it

      #info(
        title: [Solution],
      )[Use `Pin<Box<InSt>>` to project from `Pin<&mut Double>` to `Pin<&mut InSt>` via `Pin::as_mut()`]
    ],
  )
]


#slide[
  #set text(size: 0.8em)
  Change the struct definition to store `Pin<Box<InSt>>`:

  ```rust
  struct Double<InSt> { in_stream: Pin<Box<InSt>>, }
  ```

  *Why this works:*
  - `Box<InSt>` is always `Unpin` (pointers are safe to move)
  - `Pin<Box<InSt>>` can hold `!Unpin` streams safely on the heap


  #pause
  *Projection in `poll_next`:*


  ```rs
  fn poll_next(self: Pin<&mut Self>, cx: &mut Context<'_>)
      -> Poll<Option<Self::Item>> {
      let this = self.get_mut();  // Safe: Double is Unpin now
      this.in_stream.as_mut()      // Project to Pin<&mut InSt>
          .poll_next(cx)
          .map(|opt| opt.map(|x| x * 2))
    }
  ```

  This works *without requiring `InSt: Unpin`*!
]


#slide[
  From `Pin<&mut Double>` to `Pin<&mut InSt>` in a few *safe steps*:
  #text(size: 0.7em)[




    #align(center + horizon)[
      #cetz-canvas(length: 2.2cm, {
        import draw: *

        // Step 0: Starting point - Pin<&mut Double>
        let center1 = (1, 4)
        hexagon(
          draw,
          center1,
          3.5,
          color: colors.pin,
        )[`Pin<&mut Double>`]
        styled-circle(draw, center1, colors.operator, radius: 1.2)[`&mut Double`]

        hexagon(
          draw,
          center1,
          2,
          color: colors.pin,
        )[`Pin<Box<Inst>>`]

        styled-rect(
          draw,
          (center1.at(0) - 0.4, center1.at(1) - 0.4),
          (center1.at(0) + 0.4, center1.at(1) + 0.4),
          colors.neutral,
        )[`Box<InSt>`]
        styled-circle(draw, center1, colors.stream, radius: 0.25)[]

        content((3, 5.3), text(size: 3em, "🐅"), anchor: "center")
        arc(
          (2.5, 5.3),
          start: 80deg,
          stop: 178deg,
          radius: 1.2,
          mark: (end: "barbed"),
          stroke: accent(colors.error) + arrow-width,
        )

        (pause,)

        // Arrow 1: .get_mut()
        styled-line(draw, (2.9, 4), (3.3, 4), colors.pin, mark: (end: "barbed"))
        styled-content(
          draw,
          (3.1, 4.5),
          colors.pin,
        )[`.get_mut()`]
        styled-content(draw, (3.1, 3.2), colors.neutral)[Safe \ because \ `Double:` \ `Unpin`]

        // Step 1: After .get_mut() - &mut Double
        let center2 = (4.5, 4)
        styled-circle(draw, center2, colors.operator, radius: 1.2)[`&mut Double`]
        hexagon(
          draw,
          center2,
          2,
          color: colors.pin,
        )[`Pin<Box<Inst>>`]

        draw.content((center2.at(0), center2.at(1) - 1.4))[_`&mut Self` \ mutable ref to operator_]

        styled-rect(
          draw,
          (center2.at(0) - 0.4, center2.at(1) - 0.4),
          (center2.at(0) + 0.4, center2.at(1) + 0.4),
          colors.neutral,
        )[`Box<InSt>`]
        styled-circle(draw, center2, colors.stream, radius: 0.25)[]

        (pause,)

        // Arrow 2: .in_stream (field access)
        styled-line(draw, (5.8, 4), (6.3, 4), colors.neutral, mark: (end: "barbed"))
        styled-content(draw, (5.9, 4.5), colors.neutral)[`.in_stream`]
        styled-content(draw, (6.1, 3.5), colors.neutral)[simple \ field \ access]

        // Step 2: After .in_stream - Pin<Box<InSt>>
        let center3 = (7.5, 4)
        hexagon(
          draw,
          center3,
          2,
          color: colors.pin,
        )[`Pin<Box<Inst>>`]

        styled-rect(
          draw,
          (center3.at(0) - 0.4, center3.at(1) - 0.4),
          (center3.at(0) + 0.4, center3.at(1) + 0.4),
          colors.neutral,
        )[`Box<InSt>`]
        styled-circle(draw, center3, colors.stream, radius: 0.25)[]

        draw.content((center3.at(0), center3.at(1) - 1.4))[_pinned and boxed \ inner input stream field_]

        (pause,)

        // Arrow 3: .as_mut() (pin projection)
        styled-line(draw, (8.7, 4), (9.3, 4), colors.pin, mark: (end: "barbed"))
        styled-content(draw, (9.0, 4.5), colors.pin)[`.as_mut()`]
        styled-content(draw, (9.0, 3.4), colors.neutral)[always safe \ because `Pin` \ contract]

        // Step 3: After .as_mut() - Pin<&mut InSt>
        let center4 = (10.5, 4)
        hexagon(draw, center4, 2, color: colors.pin)[`Pin<&mut InSt>`]

        styled-circle(draw, center4, colors.stream, radius: 0.25)[`InSt`]

        draw.content((center4.at(0), center4.at(1) - 1.4))[_pinned unboxed inner \ input stream_]

        (pause,)

        // Arrow 4: .poll_next()
        styled-line(draw, (11.7, 4), (12.4, 4), colors.action, mark: (end: "barbed"))
        styled-content(
          draw,
          (12.2, 4.5),
          colors.stream,
        )[`.poll_next()`]
      })
    ]
  ]
]


#slide[
  #text(size: 0.8em)[
    We can call `Pin::get_mut()` to get `&mut Double<InSt>` safely from `Pin<&mut Double<InSt>>`

    ```rust
    impl<InSt> Stream for Double<InSt>
    where InSt: Stream<Item = i32>
    {
        fn poll_next(self: Pin<&mut Self>, cx: &mut Context<'_>)
            -> Poll<Option<Self::Item>>
        {
            // We can project because `Self: Unpin`
            let this: &mut Double<InSt> = self.get_mut();
            this.in_stream.as_mut()
                .poll_next(cx)
                .map(|r| r.map(|x| x * 2))
          }
      }
    ```
  ]
]

== Review of approaches to `!Unpin` fields

#slide[
  #grid(
    columns: (1fr, 1fr),
    rows: auto,
    gutter: 2em,

    [
      *Approach 1: Use `Box<_>`*
      ```rust
      struct Double<InSt> {
        in_stream: Pin<Box<InSt>>
      }

      impl<InSt> Stream for Double<InSt>
        where InSt: Stream
      ```
      ✓ Works with any `InSt`, also `!Unpin`
    ],
    [
      #pause
      *Approach 2: Require `Unpin`*
      ```rust
      struct Double<InSt> {
        in_stream: InSt
      }

      impl<InSt> Stream for Double<InSt>
        where InSt: Stream + Unpin
      ```
      ✗ Imposes `Unpin` constraint on users
    ],
  )

  #v(1em)
  * Approach 3*: Use `pin-project` crate
]

#slide[
  #set text(size: 0.7em)

  *Approach 3*: Projection with `pin-project`

  Do not impose `Unpin` constraint on input stream *and* avoid heap allocation with `Box`:

  ```rust
  #[pin_project]
  struct Double<InSt> {
      #[pin]
      in_stream: InSt,
  }
  impl<InSt: Stream> Stream for Double<InSt> {
      fn poll_next(self: Pin<&mut Self>, cx: &mut Context<'_>)
          -> Poll<Option<Self::Item>>
      {
          //
          self.project().in_stream.poll_next(cx)
              .map(|r| r.map(|x| x * 2))
      }
    }
  ```
  #v(-4em)
  #info[`pin-project` generates a safe projection method `project()`.

    You don't have juggle with `Unpin` (*but your users have to!*)]
]

== Distributing your operator

#slide[
  Define a constructor and turn it into a method of an *extension trait*:

  ```rust
  trait DoubleStream: Stream {
      fn double(self) -> Double<Self>
      where Self: Sized + Stream<Item = i32>,
      { Double::new(self) }
  }
    // A blanket implementation should be provided by you!
    impl<S> DoubleStream for S where S: Stream<Item = i32> {}
  ```
  #pause
  Now, users *don't need to know how* `Double` is implemented, just

  1. import your extension trait: `DoubleStream`
  2. call `.double()` on any compatible stream
]

== The _'real'_ stream drivers

#slide[
  #align(center + horizon)[
    #cetz-canvas(length: 1.5cm, {
      import draw: *

      rect(
        (0.5, 0.5),
        (7.5, 2),
        fill: colors.operator,
        stroke: accent(colors.operator) + stroke-width,
        radius: node-radius,
      )
      content((4, 1.6), text(size: 0.8em, weight: "bold", "Leaf Streams (Real Drivers)"), anchor: "center")
      content((4, 1.1), text(size: 0.6em, "TCP, Files, Timers, Hardware, Channels"), anchor: "center")

      line((4, 2.2), (4, 2.8), stroke: accent(colors.operator) + arrow-width, mark: (end: "barbed"))
      content((5.2, 2.5), text(size: 0.6em, "Data pushed up"), anchor: "center")

      rect((1, 3), (7, 4), fill: colors.stream, stroke: accent(colors.stream) + stroke-width, radius: node-radius)
      content((4, 3.7), text(size: 0.8em, weight: "bold", "Stream Trait Interface"), anchor: "center")
      content((4, 3.3), text(size: 0.6em, "Lazy: .poll_next() only responds when called"), anchor: "center")
    })
  ]

  `Stream` trait just provides a *uniform way to query* - it doesn't create or drive data flow.
]


#slide[
  *The `Stream` trait is NOT the stream itself* - it's just a lazy frontend to query data.

  #v(1em)

  #grid(
    columns: (1fr, 1fr),
    column-gutter: 2em,
    [
      *What `Stream` trait does:*
      - Provides uniform `.poll_next()` interface
      - Lazy: only responds when asked
      - Doesn't drive or produce data itself
      - Just queries whatever backend exists
    ],
    [
      *What actually drives streams:*
      - TCP connections receiving packets
      - File I/O completing reads
      - Timers firing
      - Hardware signals
      - Channel senders pushing data
    ],
  )
]

= Example 2: $1 -> N$  Operator

== Complexity $1-> N$ operators

#slide[
  Challenges for `Stream` operators are combined from:

  #grid(
    columns: (1fr, 1fr),
    column-gutter: 2em,
    [
      *Inherent `Future` challenges:*
      - Clean up orphaned wakers
      - Cleanup when tasks abort
      - Task coordination complexity
    ],
    [
      #pause
      *Inherent `Iterator` challenges:*
      - Ordering guarantees across consumers
      - Backpressure with slow consumers
      - Sharing mutable state safely
      - Avoiding duplicate items
    ],
  )

  #align(center)[
    #text(size: 0.7em)[



      #cetz-canvas(length: 2cm, {
        import draw: *

        let clone-positions = ((0.5, 1), (2, 0.5), (4, 0.2), (6, 1.2), (7.5, 0.8))
        for (i, pos) in clone-positions.enumerate() {
          let (x, y) = pos
          let color = if i < 2 { colors.pin } else { colors.state }
          styled-circle(draw, (x, y), color, radius: 0.2)[#i]
        }

        content((4, 1), "Thousands of clones...", anchor: "center")
      })
    ]

    All in different states
  ]
]

== Sharing latency between tasks

#slide[
  Latency may need to processed by different async tasks:

  ```rust
  let tcp_stream = TcpStream::connect("127.0.0.1:8080").await?;
  let latency = tcp_stream.latency(); // Stream<Item = Duration>

  spawn(async move { display_ui(latency).await; });
  spawn(async move { engage_breaks(latency).await; }); // Error!
  ```

  #error[`latency` is moved into the first task,   so the second task can't access it.]

  #warning[We need a way to clone the latency stream!]
]


#slide[
  *Solution*: Create a _*stream operator*_ `fork()` makes the input stream `Clone`.

  ```rust
  let ui_latency = tcp_stream.latency().fork();

  let breaks_latency_clone = ui_latency.clone();
  // Warning: `Clone` needs to be implemented!

    spawn(async move { display_ui(ui_latency).await; });
    spawn(async move { engage_breaks(breaks_latency_clone).await; });
  ```

  *Requirement*: `Stream<Item: Clone>`, so we can clone the items (`Duration` is `Clone`)
]

== Handling sleeping and waking

#slide(composer: (3fr, 1fr))[

  #styled-diagram(
    spacing: (2em, 1.5em),
    styled-edge(
      <poll-alice>,
      <poll-input-stream>,
      label: [1. `poll_next()`],
      color: colors.action,
      bend: 50deg,
      label-pos: 79%,
    ),
    colored-node(
      (1, 0),
      color: colors.stream,
      name: <poll-input-stream>,
    )[`InputStream`],
    styled-edge(
      <poll-input-stream>,
      <poll-alice>,
      label: [2. `Pending`],
      color: colors.data,
      bend: -85deg,
      label-pos: 90%,
    ),
    colored-node(
      (0, 3),
      color: colors.stream,
      name: <poll-alice>,
      shape: fletcher.shapes.circle,
    )[Alice\ 💤 Sleeping],

    pause,
    colored-node(
      (2, 3),
      color: colors.stream,
      name: <poll-bob>,
      shape: fletcher.shapes.circle,
    )[Bob\ 🔍 Polling],
    styled-edge(<poll-input-stream>, <poll-data>, label: [4. `Ready`], color: colors.data),
    styled-edge(
      <poll-bob>,
      <poll-input-stream>,
      label: [3. `poll_next()`],
      color: colors.action,
      stroke-width: arrow-width,
      bend: -50deg,
      label-pos: 70%,
    ),
    colored-node(
      (1, 1.5),
      color: colors.data,
      name: <poll-data>,
    )[data 'x'],
    pause,


    styled-edge(
      <poll-bob>,
      <poll-alice>,
      label: [5. `wake()` Alice],
      color: colors.action,
      stroke-width: arrow-width,
      bend: 40deg,
    ),


    styled-edge(
      <poll-alice>,
      <poll-data>,
      label: [6. `poll_next()`],
      color: colors.action,
      bend: -40deg,
      label-pos: 30%,
    ),


    styled-edge(
      <poll-data>,
      <poll-alice>,
      label: [7. `clone()`],
      color: colors.neutral,
      bend: -40deg,
      label-pos: 30%,
    ),
    styled-edge(
      <poll-data>,
      <poll-bob>,
      label: [8. original],
      color: colors.data,
      bend: 40deg,
      label-pos: 30%,
    ),
  )
][
  #set align(bottom)
  #legend(vertical: true, (
    (color: colors.stream, label: [Streams]),
    (color: colors.action, label: [Actions]),
    (color: colors.data, label: [Data]),
    (color: colors.neutral, label: [Basic]),
  ))
]


== Simplified state machine of  #link("https://github.com/wvhulle/clone-stream/blob/main/src/states.rs")[`clone-stream`]

#slide[
  Enforcing simplicity, *correctness and performance*:

  #warning[Each clone maintains its own #link("https://github.com/wvhulle/clone-stream/blob/main/src/states.rs")[state]]

  #{
    styled-diagram(
      node-inset: 0.5em,
      spacing: (4em, 0.5em),

      state-node(
        (0, 1),
        "PollingInputStream",
        "Actively polling input stream",
        colors.state,
        <polling-base-stream>,
      ),
      styled-edge(
        <polling-base-stream>,
        <processing-queue>,
        label: [input stream ready,\ queue item],
        label-pos: 0.5,
        label-anchor: "north",
        label-sep: 0em,
      ),
      styled-edge(
        <polling-base-stream>,
        <pending>,
        label: "input stream pending",
        bend: -15deg,
        label-pos: 0.7,
        label-sep: 0.5em,
        label-anchor: "west",
      ),

      state-node(
        (2, 1),
        "ReadingBuffer",
        "Reading from shared buffer",
        colors.data,
        <processing-queue>,
      ),
      styled-edge(
        <processing-queue>,
        <polling-base-stream>,
        label: [buffer empty,\ poll base],
        bend: 10deg,
        label-pos: 0.5,
      ),

      state-node((1, 0), "Sleeping", "Waiting with stored waker", colors.action, <pending>),
      styled-edge(<pending>, <polling-base-stream>, label: "woken", bend: -15deg, label-pos: 0.7, label-sep: 1em),
      styled-edge(<pending>, <processing-queue>, label: "fresh buffer", bend: 15deg, label-pos: 0.7),
    )
  }



  #pause
  #info(title: [Speed])[8 - 12 micro seconds per item per clone. (Using `pin-project` slowed down.)]
]


= Conclusion

== Quickstart

#slide[
  #styled-diagram(
    spacing: (2em, 1.2em),
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
    )[ReactiveX-like \ e.g. 1-N],

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

== Advanced operator construction



#slide[
  #set align(horizon)
  #styled-diagram(
    spacing: (3em, 1em),

    workflow-step(
      (1, 3),
      "1",
      "Write tests",
      ("Order preservation", "All items received", [Use `Barrier`s, not `sleep()`]),
      colors.stream,
      <write-tests>,
    ),
    styled-edge(<write-tests>, <analyze-states>),

    workflow-step(
      (3, 3),
      "2",
      "Analyze states",
      ("Minimal state set", "Add tracing / logging", [Avoid `Option`s in states]),
      colors.data,
      <analyze-states>,
    ),
    styled-edge(<analyze-states>, <implement>, bend: -15deg),

    workflow-step(
      (2, 2),
      "3",
      "Define transitions",
      ([Start with 1,2 output `Stream`s], "Get wake-up order right", [Don't create  custom `Waker`s]),
      colors.state,
      <implement>,
    ),
    styled-edge(<implement>, <run-tests>, bend: -15deg),

    workflow-step(
      (1, 1),
      "4",
      "Run tests",
      ("Trace tests", "Debug tests"),
      colors.action,
      <run-tests>,
    ),
    styled-edge(<run-tests>, <benchmarks>, label: "✓ pass"),
    styled-edge(
      <run-tests>,
      <implement>,
      label: "✗ fail",
      color: colors.error,
      bend: -30deg,
    ),

    styled-edge(
      <run-tests>,
      <write-tests>,
      label: "✗ missing test",
      color: colors.error,
      bend: -30deg,
    ),

    styled-edge(
      <benchmarks>,
      <implement>,
      label: "✗ too slow",
      color: colors.error,
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
]


== Questions

#slide[


  Thank you for your attention!

  - Contact me: #link("mailto:willemvanhulle@protonmail.com") \
  - These slides: #link("https://github.com/wvhulle/streams-eurorust-2025")[github.com/wvhulle/streams-eurorust-2025]



  #warning(title: [Learn more?])[
    #set align(left)

    Join my 7-week course _*"Creating Safe Systems in Rust"*_

    - Location: Ghent (Belgium)
    - Date: starting 4th of November 2025.

    Register at #link("https://pretix.eu/devlab/rust-course/")[pretix.eu/devlab/rust-course/]
  ]

]




