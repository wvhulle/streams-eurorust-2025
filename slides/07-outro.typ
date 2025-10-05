#import "../lib/constants.typ": *
#import "../lib/diagram-helpers.typ": *
#import "@preview/fletcher:0.5.8" as fletcher: diagram, edge, node
#import "@preview/cetz:0.4.2": canvas, draw

#let outro-slides(slide) = {
  slide[
    #text(size: 1em)[Any questions?]

    #text(size: 2em)[Thank you!]

    #rect(fill: colors.operator.base, stroke: colors.operator.accent + stroke-width, radius: node-radius)[
      *Want to learn more in-depth?*

      Join my 7-week course _*"Creating Safe Systems in Rust"*_

      - Location: Ghent (Belgium)
      - Date: starting November 2025.

      Register at #link("https://willemvanhulle.tech")[willemvanhulle.tech] (link at bottom of page)
    ]


    - Contact me: #link("mailto:willemvanhulle@protonmail.com") \
    - These slides: #link("https://github.com/wvhulle/streams-eurorust-2025")[github.com/wvhulle/streams-eurorust-2025]
  ]

  slide[
    == Bonus slides
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
            stroke: color.darken(stroke-darken) + stroke-width,
            radius: node-radius,
          )
          content((2, y), text(size: 8pt, weight: "bold", year), anchor: "center")

          content((3.5, y + 0.2), text(size: 9pt, weight: "bold", event), anchor: "west")
          content((3.5, y - 0.03), text(size: 7pt, description), anchor: "west")
          content(
            (3.5, y - 0.24),
            link(ref-url, text(size: 6pt, style: "italic", fill: colors.stream.accent, reference)),
            anchor: "west",
          )

          line((0.8, y), (1, y), stroke: colors.neutral.accent + stroke-width)
        }

        draw-timeline-entry(
          5.5,
          "2019",
          "async/await stabilized in Rust",
          "Stable async streams in std",
          "RFC 2394, Rust 1.39.0",
          "https://rust-lang.github.io/rfcs/2394-async_await.html",
          colors.stream.base.lighten(20%),
        )
        draw-timeline-entry(
          4.5,
          "2009",
          "Microsoft Reactive Extensions",
          "ReactiveX brings streams to mainstream",
          "Erik Meijer, Microsoft",
          "https://reactivex.io/",
          colors.operator.base.lighten(30%),
        )
        draw-timeline-entry(
          3.5,
          "1997",
          "Functional Reactive Programming",
          "Conal Elliott & Paul Hudak (Haskell)",
          "ICFP '97, pp. 263-273",
          "https://dl.acm.org/doi/10.1145/258948.258973",
          colors.state.base.lighten(25%),
        )
        draw-timeline-entry(
          2.5,
          "1978",
          "Communicating Sequential Processes",
          "Tony Hoare formalizes concurrent dataflow",
          "CACM 21(8):666-677",
          "https://dl.acm.org/doi/10.1145/359576.359585",
          colors.ui.base.lighten(35%),
        )
        draw-timeline-entry(
          1.5,
          "1973",
          "Unix Pipes",
          "Douglas McIlroy creates `|` operator",
          "Bell Labs, Unix v3-v4",
          "https://www.cs.dartmouth.edu/~doug/reader.pdf",
          colors.data.base.lighten(40%),
        )
        draw-timeline-entry(
          0.5,
          "1960s",
          "Dataflow Programming",
          "Hardware-level stream processing",
          "Early dataflow architectures",
          "https://en.wikipedia.org/wiki/Dataflow_programming",
          colors.error.base.lighten(20%),
        )

        line((0.8, 0.3), (0.8, 5.7), stroke: colors.neutral.accent + arrow-width)
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

  slide(title: "'Fusing' streams and futures")[


    #align(center + horizon)[
      #let draw-arrow(multiple: false, fused: false, color) = {
        canvas(length: 0.8cm, {
          import draw: *

          if multiple {
            if fused {
              line((-0.8, 0), (0.6, 0), stroke: color + arrow-width)
              line((0.8, -0.3), (0.8, 0.3), stroke: color + (arrow-width * 2))
            } else {
              line((-0.8, 0), (0.8, 0), stroke: color + arrow-width, mark: (end: "barbed"))
            }
            for i in range(if fused { 4 } else { 3 }) {
              let dash-x = -0.6 + i * 0.4
              line((dash-x, -0.15), (dash-x, 0.15), stroke: color + (arrow-width * 1.5))
            }
          } else {
            line((-0.8, 0), (0.3, 0), stroke: color + arrow-width)
            line((0, -0.2), (0, 0.2), stroke: color + (arrow-width * 1.5))
            if fused {
              line((0.3, 0), (0.6, 0), stroke: color + arrow-width)
              line((0.8, -0.3), (0.8, 0.3), stroke: color + (arrow-width * 2))
            } else {
              line((0.3, 0), (0.8, 0), stroke: color + arrow-width, mark: (end: "barbed"))
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

  slide(title: "Flatten a *finite collection* of `Stream`s")[
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

  slide(title: "More `Stream` features to explore")[
    Many more advanced topics await:

    - *Boolean operations*: `any`, `all`
    - *Async operations*: `then`
    - *`Sink`s*: The write-side counterpart to `Stream`s

    #{
      let endpoint(pos, text, color, name) = node(
        pos,
        [#text],
        fill: color.base,
        stroke: color.accent + stroke-width,
        name: name,
      )
      let data-item(pos, char, name) = node(
        pos,
        [#char],
        fill: colors.data.base,
        stroke: colors.data.accent + stroke-width,
        shape: fletcher.shapes.circle,
        name: name,
      )
      let label(pos, text) = node(pos, [#text], fill: none, stroke: none)

      styled-diagram(
        spacing: (6em, 2em),
        {
          endpoint((0, 1), "Stream", colors.stream, <stream>)
          data-item((1, 1), "'a'", <data-a>)
          data-item((1.5, 1), "'b'", <data-b>)
          data-item((2, 1), "'c'", <data-c>)
          endpoint((3, 1), "Sink", colors.ui, <sink>)

          edge(<stream>, <data-a>, "-")
          edge(<data-a>, <data-b>, "-")
          edge(<data-b>, <data-c>, "-")
          edge(<data-c>, <sink>, "->", label: [`.forward()`])

          label((0, 1.7), "Read side")
          label((3, 1.7), "Write side")
        },
      )
    }
  ]

  slide(title: "The `Stream` trait: a lazy query interface")[
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

  slide(title: "The _'real'_ stream drivers")[
    #align(center + horizon)[
      #canvas(length: 1cm, {
        import draw: *

        rect(
          (0.5, 0.5),
          (7.5, 2),
          fill: colors.operator.base,
          stroke: colors.operator.accent + stroke-width,
          radius: node-radius,
        )
        content((4, 1.6), text(size: 9pt, weight: "bold", "Leaf Streams (Real Drivers)"), anchor: "center")
        content((4, 1.1), text(size: 7pt, "TCP, Files, Timers, Hardware, Channels"), anchor: "center")

        line((4, 2.2), (4, 2.8), stroke: colors.operator.accent + arrow-width, mark: (end: "barbed"))
        content((5.2, 2.5), text(size: 7pt, "Data pushed up"), anchor: "center")

        rect((1, 3), (7, 4), fill: colors.stream.base, stroke: colors.stream.accent + stroke-width, radius: node-radius)
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

    #rect(inset: 5mm, fill: colors.error.base, stroke: colors.error.accent + stroke-width, radius: node-radius)[
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
      node-fill: colors.state.base,
      stroke-width: stroke-width + colors.state.accent,
      node-shape: circle,
      {
        node((0, 1.2), [*GC Languages*], name: <gc-title>, fill: none, stroke: none)
        node((0, 0.5), [GC], fill: colors.state.base, stroke: colors.state.accent + 1.5pt, shape: circle, name: <gc>)
        node((-0.5, -0.3), [•], fill: colors.stream.accent, stroke: none, name: <gc-d1>)
        node((0, -0.5), [•], fill: colors.stream.accent, stroke: none, name: <gc-d2>)
        node((0.5, -0.2), [•], fill: colors.stream.accent, stroke: none, name: <gc-d3>)
        node(
          (0, -1.2),
          text(size: 7pt)[Data flows freely,\ GC handles cleanup],
          name: <gc-caption>,
          stroke: none,
          fill: none,
        )
        node(
          fill: colors.neutral.base,
          stroke: colors.neutral.accent + stroke-width,
          shape: rect,
          inset: 0.7em,
          enclose: (<gc-title>, <gc>, <gc-d1>, <gc-d2>, <gc-d3>, <gc-caption>),
        )

        node((1.5, 0.3), [*vs*], stroke: none, fill: none)

        node(
          fill: colors.stream.base,
          stroke: colors.stream.accent + stroke-width,
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

        node((3, 1.2), [*Rust*], stroke: none, fill: none, name: <rust-title>)
        node((2.7, 0.2), [•], fill: colors.stream.accent, stroke: colors.stream.accent + 1pt, name: <owner>)
        node((2.7, 0.6), text(size: 6pt)[Owner], stroke: none, name: <owner-label>, fill: none)
        node((3.5, 0.2), [•], fill: colors.stream.accent, stroke: colors.stream.accent + 1pt, name: <moved>)
        node((3.5, 0.6), text(size: 6pt)[Moved], stroke: none, fill: none, name: <moved-label>)
        node((3.5, -0.5), [•], fill: colors.stream.accent, stroke: colors.stream.accent + 1pt, name: <borrowed>)
        node((3.5, -0.9), text(size: 6pt)[Borrow], stroke: none, name: <borrow-label>, fill: none)
        node(
          (3, -1.5),
          text(size: 7pt)[Explicit ownership,\ tracked at compile time],
          shape: rect,
          fill: none,
          stroke: none,
          inset: 0.5em,
          name: <rust-caption>,
        )

        edge(<owner>, <moved>, "->", stroke: colors.stream.accent + 1.5pt)
        edge(<owner>, <borrowed>, "->", stroke: (paint: colors.stream.accent, thickness: 1.5pt, dash: "dashed"))

        node(fill: colors.ui.base, stroke: colors.ui.accent + stroke-width, enclose: (
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
