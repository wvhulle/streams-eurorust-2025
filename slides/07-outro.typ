#import "../lib/constants.typ": *
#import "../lib/diagram-helpers.typ": *
#import "../lib/blocks.typ": conclusion
#import "@preview/fletcher:0.5.8" as fletcher: diagram, edge, node
#import "@preview/cetz:0.4.2": canvas, draw

#let outro-slides(slide) = {
  slide[
    #text(size: 2em)[Any questions?]

    - Afraid to ask? Contact me: #link("mailto:willemvanhulle@protonmail.com") \
    - These slides: #link("https://github.com/wvhulle/streams-eurorust-2025")[github.com/wvhulle/streams-eurorust-2025]


    #set align(bottom)

    #rect(fill: colors.operator, stroke: accent(colors.operator) + stroke-width, radius: node-radius)[
      *Want to learn more in-depth?*

      Join my 7-week course _*"Creating Safe Systems in Rust"*_

      - Location: Ghent (Belgium)
      - Date: starting 4th of November 2025.

      Register at #link("https://pretix.eu/devlab/rust-course/")[pretix.eu/devlab/rust-course/]
    ]



  ]

  slide[
    == Bonus slides
  ]

  slide(
    title: [Simplified state machine of  #link("https://github.com/wvhulle/clone-stream/blob/main/src/states.rs")[`clone-stream`]],
  )[
    #set text(size: 8pt)
    Enforcing simplicity, *correctness and performance*:

    #{
      styled-diagram(
        node-inset: 1em,
        spacing: (4em, 1.5em),

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
          bend: 40deg,
          label-pos: 0.5,
        ),

        state-node((1, 0), "Sleeping", "Waiting with stored waker", colors.action, <pending>),
        styled-edge(<pending>, <polling-base-stream>, label: "woken", bend: -15deg, label-pos: 0.7, label-sep: 1em),
        styled-edge(<pending>, <processing-queue>, label: "fresh buffer", bend: 15deg, label-pos: 0.7),
      )
    }
    #v(-1em)
    #conclusion[Each clone maintains its own #link("https://github.com/wvhulle/clone-stream/blob/main/src/states.rs")[state]]
  ]

  slide(title: [`Stream`s in Rust are not new])[
    #align(center)[
      #canvas(length: 1cm, {
        import draw: *

        let draw-timeline-entry(y, year, event, description, reference, ref-url, color) = {
          rect(
            (1, y - 0.3),
            (3, y + 0.3),
            fill: color,
            stroke: accent(color) + stroke-width,
            radius: node-radius,
          )
          content((2, y), text(size: 8pt, weight: "bold", year), anchor: "center")

          content((3.5, y + 0.2), text(size: 9pt, weight: "bold", event), anchor: "west")
          content((3.5, y - 0.03), text(size: 7pt, description), anchor: "west")
          content(
            (3.5, y - 0.24),
            link(ref-url, text(size: 6pt, style: "italic", fill: accent(colors.stream), reference)),
            anchor: "west",
          )

          line((0.8, y), (1, y), stroke: accent(colors.neutral) + stroke-width)
        }

        draw-timeline-entry(
          5.5,
          "2019",
          "async/await stabilized in Rust",
          "Stable async streams in std",
          "RFC 2394, Rust 1.39.0",
          "https://rust-lang.github.io/rfcs/2394-async_await.html",
          colors.stream.lighten(20%),
        )
        draw-timeline-entry(
          4.5,
          "2009",
          "Microsoft Reactive Extensions",
          "ReactiveX brings streams to mainstream",
          "Erik Meijer, Microsoft",
          "https://reactivex.io/",
          colors.operator.lighten(30%),
        )
        draw-timeline-entry(
          3.5,
          "1997",
          "Functional Reactive Programming",
          "Conal Elliott & Paul Hudak (Haskell)",
          "ICFP '97, pp. 263-273",
          "https://dl.acm.org/doi/10.1145/258948.258973",
          colors.state.lighten(25%),
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
          0.5,
          "1960s",
          "Dataflow Programming",
          "Hardware-level stream processing",
          "Early dataflow architectures",
          "https://en.wikipedia.org/wiki/Dataflow_programming",
          colors.error.lighten(20%),
        )

        line((0.8, 0.3), (0.8, 5.7), stroke: accent(colors.neutral) + arrow-width * 2)
      })
    ]
  ]

  slide(title: [The meaning of `Ready(None)`])[
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

  slide(title: ['Fusing' `Stream`s and `Future`s])[


    #align(center + horizon)[
      #let draw-arrow(multiple: false, fused: false, color) = {
        canvas(length: 0.8cm, {
          import draw: *

          if multiple {
            if fused {
              line((-0.8, 0), (0.6, 0), stroke: accent(color) + arrow-width)
              line((0.8, -0.3), (0.8, 0.3), stroke: accent(color) + (arrow-width * 2))
            } else {
              line((-0.8, 0), (0.8, 0), stroke: accent(color) + arrow-width, mark: (end: "barbed"))
            }
            for i in range(if fused { 4 } else { 3 }) {
              let dash-x = -0.6 + i * 0.4
              line((dash-x, -0.15), (dash-x, 0.15), stroke: accent(color) + (arrow-width * 1.5))
            }
          } else {
            line((-0.8, 0), (0.3, 0), stroke: accent(color) + arrow-width)
            line((0, -0.2), (0, 0.2), stroke: accent(color) + (arrow-width * 1.5))
            if fused {
              line((0.3, 0), (0.6, 0), stroke: accent(color) + arrow-width)
              line((0.8, -0.3), (0.8, 0.3), stroke: accent(color) + (arrow-width * 2))
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

  slide(title: [Flatten a *finite collection* of `Stream`s])[
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

  slide(title: "Flattening an infinite stream")[
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

  slide(title: [More `Stream` features to explore])[
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
    }
  ]

  slide(title: [The `Stream` trait: a lazy query interface])[
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


  slide(title: [Moving from `Iterator` to `Stream`])[
    #{
      set text(size: 7pt)
      styled-diagram(
        spacing: (1.2em, 0.8em),

        title-node((0.5, 5), text(size: 11pt, weight: "bold")[Iterator (sync)]),

        colored-node((0, 4), color: colors.action, name: <iter-call1>)[`next()`],
        styled-edge(<iter-call1>, <iter-result1>),
        colored-node((0, 3), color: colors.action, name: <iter-call2>)[`next()`],
        styled-edge(<iter-call2>, <iter-result4>),
        colored-node((0, 2), color: colors.action, name: <iter-call3>)[`next()`],
        styled-edge(<iter-call3>, <iter-result3>),
        colored-node((0, 1), color: colors.action, name: <iter-call4>)[`next()`],
        styled-edge(<iter-call4>, <iter-result2>),

        colored-node((1, 4), color: colors.data, name: <iter-result1>)[`Some(2)`],
        colored-node((1, 1), color: colors.data, name: <iter-result2>)[`Some(3)`],
        colored-node((1, 2), color: colors.data, name: <iter-result3>)[`Some(1)`],
        colored-node((1, 3), color: colors.data, name: <iter-result4>)[`None`],

        title-node((3.5, 5), text(size: 10pt, weight: "bold")[Stream (low-level)]),

        colored-node((3, 4), color: colors.action, name: <stream-call1>)[`poll_next()`],
        styled-edge(<stream-call1>, <stream-result1>),
        colored-node((3, 3), color: colors.action, name: <stream-call2>)[`poll_next()`],
        styled-edge(<stream-call2>, <stream-result2>),
        colored-node((3, 2), color: colors.action, name: <stream-call3>)[`poll_next()`],
        styled-edge(<stream-call3>, <stream-result3>),
        colored-node((3, 1), color: colors.action, name: <stream-call4>)[`poll_next()`],
        styled-edge(<stream-call4>, <stream-result4>),

        colored-node((4, 4), color: colors.state, name: <stream-result1>)[`Pending`],
        colored-node((4, 3), color: colors.data, name: <stream-result2>)[`Ready(Some(1))`],
        colored-node((4, 2), color: colors.state, name: <stream-result3>)[`Pending`],
        colored-node((4, 1), color: colors.data, name: <stream-result4>)[`Ready(Some(2))`],

        node(
          stroke: stroke-width + accent(colors.stream),
          fill: colors.stream,

          inset: 1em,
          shape: rect,
          radius: 8pt,
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

        title-node((6.5, 5), text(size: 10pt, weight: "bold")[Stream (high-level)]),

        colored-node((6, 4), color: colors.action, name: <async-call1>)[`next().await`],
        styled-edge(<async-call1>, <async-result1>),
        colored-node((6, 3), color: colors.action, name: <async-call2>)[`next().await`],
        styled-edge(<async-call2>, <async-result4>),
        colored-node((6, 2), color: colors.action, name: <async-call3>)[`next().await`],
        styled-edge(<async-call3>, <async-result3>),
        colored-node((6, 1), color: colors.action, name: <async-call4>)[`next().await`],
        styled-edge(<async-call4>, <async-result2>),

        colored-node((7, 4), color: colors.data, name: <async-result1>)[`Some(2)`],
        colored-node((7, 1), color: colors.data, name: <async-result2>)[`Some(3)`],
        colored-node((7, 2), color: colors.data, name: <async-result3>)[`Some(1)`],
        colored-node((7, 3), color: colors.data, name: <async-result4>)[`None`],

        title-node((0.5, 0), text(size: 8pt)[✓ Always returns immediately]),
        title-node((3.5, 0), text(size: 8pt)[⚠️ May be Pending]),
        title-node((6.5, 0), text(size: 8pt)[✓ Hides polling complexity]),
      )

      v(1em)

      legend((
        (color: colors.action, label: [Actions]),
        (color: colors.data, label: [Data values]),
        (color: colors.state, label: [State]),
        (color: colors.stream, label: [Stream]),
      ))
    }
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


  slide(title: [Approach 3: Projection with `pin-project`])[
    #set text(size: 8pt)
    Projects like Tokio use the `pin-project` crate:

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
            // pin-project generates a safe projection method `project()`
            self.project().in_stream.poll_next(cx)
                .map(|r| r.map(|x| x * 2))
        }
    }
    ```

    Uses a lot of macros underneath (a bit out-of-scope).
  ]


  slide(title: [The _'real'_ stream drivers])[
    #align(center + horizon)[
      #canvas(length: 1cm, {
        import draw: *

        rect(
          (0.5, 0.5),
          (7.5, 2),
          fill: colors.operator,
          stroke: accent(colors.operator) + stroke-width,
          radius: node-radius,
        )
        content((4, 1.6), text(size: 9pt, weight: "bold", "Leaf Streams (Real Drivers)"), anchor: "center")
        content((4, 1.1), text(size: 7pt, "TCP, Files, Timers, Hardware, Channels"), anchor: "center")

        line((4, 2.2), (4, 2.8), stroke: accent(colors.operator) + arrow-width, mark: (end: "barbed"))
        content((5.2, 2.5), text(size: 7pt, "Data pushed up"), anchor: "center")

        rect((1, 3), (7, 4), fill: colors.stream, stroke: accent(colors.stream) + stroke-width, radius: node-radius)
        content((4, 3.7), text(size: 9pt, weight: "bold", "Stream Trait Interface"), anchor: "center")
        content((4, 3.3), text(size: 7pt, "Lazy: .poll_next() only responds when called"), anchor: "center")
      })
    ]

    `Stream` trait just provides a *uniform way to query* - it doesn't create or drive data flow.
  ]

  slide(title: "Possible inconsistency")[
    ```rs
    trait Stream {
        type Item;

        fn poll_next(self: Pin<&mut Self>, cx: &mut Context)
            -> Poll<Option<Self::Item>>
    }
    ```

    #rect(inset: 5mm, fill: colors.error, stroke: accent(colors.error) + stroke-width, radius: node-radius)[
      What about Rust rule `self` needs to be `Deref<Target=Self>`?
    ]

    `Pin<&mut Self>` only implements `Deref<Target=Self>` for `Self: Unpin`.

    Problem? No, `Pin` is an exception in the compiler.
  ]

  slide(title: "Why does Rust need special treatment?")[
    #set text(size: 7pt)

    - Stream operators must wrap and own their input by value
    - Combining `Future` (waker cleanup, coordination) and `Iterator` (ordering, backpressure) complexity
    - Sharing mutable state safely across async boundaries requires careful design

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
        )[#text(size: 7pt)[Data flows freely,\ GC handles cleanup]]
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
        )[#text(size: 7pt)[Explicit ownership,\ tracked at compile time]]

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

    #v(0.5em)

    Reactive patterns from GC languages require rethinking in Rust's ownership model
  ]

  slide(title: "The end")[
  ]
}
