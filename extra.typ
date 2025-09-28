
#slide[
  === The `Stream` trait: a lazy query interface

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


#slide[

  === The _'real'_ stream drivers

  #align(center + horizon)[
    #canvas(length: 1cm, {
      import draw: *

      // Leaf streams (drivers) at bottom
      rect((0.5, 0.5), (7.5, 2), fill: rgb("fff0e6"), stroke: orange + 2pt, radius: 0.2)
      content((4, 1.6), text(size: 9pt, weight: "bold", "Leaf Streams (Real Drivers)"), anchor: "center")
      content((4, 1.1), text(size: 7pt, "TCP, Files, Timers, Hardware, Channels"), anchor: "center")

      // Data flow upward
      line((4, 2.2), (4, 2.8), stroke: orange + 4pt, mark: (end: ">"))
      content((5.2, 2.5), text(size: 7pt, "Data pushed up"), anchor: "center")

      // Stream trait interface at top
      rect((1, 3), (7, 4), fill: rgb("e6f3ff"), stroke: blue + 2pt, radius: 0.2)
      content((4, 3.7), text(size: 9pt, weight: "bold", "Stream Trait Interface"), anchor: "center")
      content((4, 3.3), text(size: 7pt, "Lazy: .poll_next() only responds when called"), anchor: "center")
    })
  ]

  `Stream` trait just provides a *uniform way to query* - it doesn't create or drive data flow.
]


#slide[
  === The meaning of `Ready(None)`

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
  ]]



#slide[

  === 'Fusing' streams and futures



  #align(center + horizon)[
    #let draw-arrow(multiple: false, fused: false, color) = {
      canvas(length: 0.8cm, {
        import draw: *

        if multiple {
          // Stream: arrow with multiple dashes
          if fused {
            line((-0.8, 0), (0.6, 0), stroke: color + 2pt)
            line((0.8, -0.3), (0.8, 0.3), stroke: color + 4pt)
          } else {
            line((-0.8, 0), (0.8, 0), stroke: color + 2pt, mark: (end: ">"))
          }
          for i in range(if fused { 4 } else { 3 }) {
            let dash-x = -0.6 + i * 0.4
            line((dash-x, -0.15), (dash-x, 0.15), stroke: color + 3pt)
          }
        } else {
          // Future: arrow with single dash
          line((-0.8, 0), (0.3, 0), stroke: color + 2pt)
          line((0, -0.2), (0, 0.2), stroke: color + 3pt)
          if fused {
            line((0.3, 0), (0.6, 0), stroke: color + 2pt)
            line((0.8, -0.3), (0.8, 0.3), stroke: color + 4pt)
          } else {
            line((0.3, 0), (0.8, 0), stroke: color + 2pt, mark: (end: ">"))
          }
        }
      })
    }

    #grid(
      columns: (auto, 1fr, 1fr, 2fr),
      rows: (auto, auto, auto, auto, auto),
      gutter: 2em,
      [], [*Future*], [*Stream*], [*Meaning*],
      [*Regular*],
      [#draw-arrow(multiple: false, fused: false, blue)],
      [#draw-arrow(multiple: true, fused: false, green)],
      [May continue],

      [*Fused*], [*FusedFuture*], [*FusedStream*], [`is_terminated()` method],

      [*Fused*],
      [#draw-arrow(multiple: false, fused: true, blue)],
      [#draw-arrow(multiple: true, fused: true, green)],
      [Done permanently],

      [*Fused value*], [Pending], [Ready(None)], [Final value],
    )
  ]
]




#slide[
  === Flatten a *finite collection* of `Stream`s

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

#slide[
  === Flattening an infinite stream

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





#slide[
  === More `Stream` features to explore

  Many more advanced topics await:

  - *Boolean operations*: `any`, `all`
  - *Async operations*: `then`
  - *`Sink`s*: The write-side counterpart to `Stream`s

  #align(center)[
    #canvas(length: 1cm, {
      import draw: *

      let draw-box(pos, label, color) = {
        let (x, y) = pos
        rect((x - 0.8, y - 0.4), (x + 0.8, y + 0.4), fill: color, stroke: black + 1pt)
        content((x, y), text(size: 8pt, weight: "bold", label), anchor: "center")
      }

      // Stream source
      draw-box((1, 2), "Stream", rgb("e6f3ff"))

      // Data items
      for (i, item) in ("'a'", "'b'", "'c'").enumerate() {
        let x = 2.5 + i * 0.6
        circle((x, 2), radius: 0.2, fill: rgb("fff3cd"), stroke: orange + 1pt)
        content((x, 2), text(size: 6pt, item), anchor: "center")
      }

      // Forward arrow
      line((1.8, 2), (2.2, 2), mark: (end: ">"), stroke: blue + 2pt)
      line((4.3, 2), (4.7, 2), mark: (end: ">"), stroke: blue + 2pt)
      content((3.5, 2.5), text(size: 7pt, weight: "bold", ".forward()"), anchor: "center")

      // Sink destination
      draw-box((6, 2), "Sink", rgb("ffe6f0"))

      // Labels
      content((1, 1.2), text(size: 7pt, "Read side"), anchor: "center")
      content((6, 1.2), text(size: 7pt, "Write side"), anchor: "center")
    })
  ]


]
