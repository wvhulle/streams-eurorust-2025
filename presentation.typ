// Import template
#import "template.typ": presentation-template, slide
#import "@preview/cetz:0.4.2": canvas, draw
#import "@preview/fletcher:0.5.8" as fletcher: diagram, edge, node
#import fletcher.shapes: pill

// Apply template and page setup
#show: presentation-template.with(
  title: "Make Your Own Stream Operators",
  subtitle: "Dealing with data flows",
  author: "Willem Vanhulle",
  event: "EuroRust 2025",
  location: "Paris, France",
  duration: "30 minutes + 10 minutes Q&A",
)

#slide[

  === Plan

  #v(2em)

  #outline(
    title: none,
    indent: auto,
    depth: 2,
  )

]


#slide[
  == Motivation
]


#slide[
  === Why streams matter: real-world chaos

  *The problem:* Processing streaming data from moving vehicles

  *What I observed:*
  - Inconsistent error handling across the codebase
  - Hard to reason about data flow and state

  #align(center)[
    #canvas(length: 1cm, {
      import draw: *

      // Car emoji
      content((0, 2), text(size: 2.5em, "🚗"), anchor: "center")

      // Arrow with data flow
      line((0.8, 1.8), (3.2, 1.8), mark: (end: ">"), stroke: blue + 3pt)
      content((1.8, 2.2), text(size: 7pt, "streaming data"), anchor: "center")

      // Central chaos fire
      content((4, 2), text(size: 2.5em, "🔥"), anchor: "center")

      // Developers around the chaos (positioned in a circle around the fire)
      content((3.2, 2.8), text(size: 1.2em, "👨‍💻"), anchor: "center") // Top-left dev
      content((4.8, 2.8), text(size: 1.2em, "👩‍💻"), anchor: "center") // Top-right dev
      content((3.2, 1.2), text(size: 1.2em, "🧑‍💻"), anchor: "center") // Bottom-left dev
      content((4.8, 1.2), text(size: 1.2em, "👨‍💻"), anchor: "center") // Bottom-right dev
      content((4, 2.8), text(size: 1.2em, "👩‍💻"), anchor: "center") // Top dev
      content((5.2, 2), text(size: 1.2em, "🧑‍💻"), anchor: "center") // Right dev
    })
  ]

  ... Let's fix this!
]



#slide[

  === Short history of reactive programming



  #align(center)[
    #canvas(length: 1cm, {
      import draw: *

      let draw-timeline-entry(y, year, event, description, color) = {
        // Year label
        rect((1, y - 0.3), (3, y + 0.3), fill: color, stroke: black + 1pt, radius: 0.2)
        content((2, y), text(size: 8pt, weight: "bold", year), anchor: "center")

        // Event description
        content((3.5, y + 0.1), text(size: 9pt, weight: "bold", event), anchor: "west")
        content((3.5, y - 0.2), text(size: 7pt, description), anchor: "west")

        // Connection line from timeline to date box
        line((0.8, y), (1, y), stroke: gray + 1pt)
      }

      // Timeline entries (bottom to top = old to new)
      draw-timeline-entry(5.5, "2019", "async/await in Rust", "Stream trait ecosystem matures", rgb("e6f3ff"))
      draw-timeline-entry(
        4.5,
        "2009",
        "Microsoft Reactive Extensions",
        "ReactiveX brings streams to mainstream",
        rgb("fff0e6"),
      )
      draw-timeline-entry(
        3.5,
        "1997",
        "Functional Reactive Programming",
        "Conal Elliott & Paul Hudak (Haskell)",
        rgb("f0ffe6"),
      )
      draw-timeline-entry(
        2.5,
        "1978",
        "Communicating Sequential Processes",
        "Tony Hoare formalizes concurrent dataflow",
        rgb("ffe6f0"),
      )
      draw-timeline-entry(1.5, "1973", "Unix Pipes", "Douglas McIlroy creates `|` operator", rgb("f0e6ff"))
      draw-timeline-entry(0.5, "1960s", "Dataflow Programming", "Hardware-level stream processing", rgb("ffeeee"))

      // Main timeline line (positioned to the left, not overlapping with date boxes)
      line((0.8, 0.3), (0.8, 5.7), stroke: gray + 2pt)
    })
  ]


]




#slide[
  === Why does Rust bring to the table?

  Reactivity in garbage collected languages is *completely different* from Rust's ownership system

  #align(center)[
    #canvas(length: 1cm, {
      import draw: *

      // TypeScript side
      rect((0.5, 1), (3.5, 4), fill: rgb("fff0e6"), stroke: orange + 2pt)
      content((2, 3.5), text(size: 8pt, weight: "bold", "TypeScript"), anchor: "center")

      // GC cleanup
      circle((2, 2.8), radius: 0.4, fill: rgb("e6ffe6"), stroke: green + 2pt)
      content((2, 2.8), text(size: 6pt, "GC"), anchor: "center")


      // Data flowing freely - simplified dots
      for i in range(3) {
        let x = 1.4 + i * 0.3
        circle((x, 2.0), radius: 0.08, fill: blue)
      }
      content((2, 1.4), text(size: 6pt, "Put anything\nanywhere"), anchor: "center")

      // VS separator
      content((4.5, 2.5), text(size: 12pt, weight: "bold", "vs"), anchor: "center")

      // Rust side
      rect((5.5, 1), (8.5, 4), fill: rgb("ffe6e6"), stroke: red + 2pt)
      content((7, 3.5), text(size: 8pt, weight: "bold", "Rust"), anchor: "center")

      // Ownership constraints
      rect((6.2, 2.6), (7.8, 3.2), fill: rgb("ffcccc"), stroke: red + 1pt)
      content((7, 2.9), text(size: 6pt, "Ownership\nRules"), anchor: "center")

      // Constrained data flow
      line((6.2, 2.2), (6.8, 2.2), stroke: blue + 2pt)
      line((6.8, 2.2), (7.2, 1.8), stroke: blue + 2pt, mark: (end: ">"))
      line((7.2, 1.8), (7.8, 1.8), stroke: blue + 2pt)
      content((7, 1.3), text(size: 6pt, "Explicit design\nrequired"), anchor: "center")
    })
  ]

  This fundamental difference explains why stream patterns from other languages don't translate directly
]


#slide[
  === Stream hierarchy: from hardware to software

  #align(center)[
    #canvas(length: 1cm, {
      import draw: *

      let draw-layer(y, width, height, label, description, color, text-color: black) = {
        rect((1, y), (1 + width, y + height), fill: color, stroke: black + 1pt, radius: 0.2)
        content(
          (1 + width / 2, y + height - 0.3),
          text(size: 10pt, weight: "bold", fill: text-color, label),
          anchor: "center",
        )
        content((1 + width / 2, y + 0.3), text(size: 8pt, fill: text-color, description), anchor: "center")
      }

      let draw-examples(y, examples) = {
        let start-x = 8.5
        for (i, example) in examples.enumerate() {
          let x = start-x + calc.rem(i, 2) * 3
          let row = calc.floor(i / 2)
          content((x, y - row * 0.5), text(size: 7pt, example), anchor: "west")
        }
      }

      // Hardware layer (bottom)
      draw-layer(.5, 7, 1.2, "Physical Leaf Streams", "Physical hardware constraints", rgb("ffeeee"))
      draw-examples(1.4, ("GPIO sensors", "UART/Serial", "Hardware timers", "Network NICs"))

      // OS layer (middle)
      draw-layer(2.3, 7, 1.2, [Leaf Streams (real streams)], "OS/kernel constraints", rgb("fff3cd"))
      draw-examples(3.1, ("File I/O", "TCP sockets", "Process pipes", "System timers"))

      // Software layer (top)
      draw-layer(4.1, 7, 1.2, "Non-Leaf Streams (toy streams)", "Pure software transformations", rgb("e6f3ff"))
      draw-examples(5.0, ("map()", "filter()", "take()", "enumerate()"))

      // Arrows showing data flow upward
      line((4.5, 1.7), (4.5, 2.3), mark: (end: ">"), stroke: orange + 2pt)
      content((5.5, 2.0), text(size: 7pt, "OS abstraction"), anchor: "center")

      line((4.5, 3.5), (4.5, 4.1), mark: (end: ">"), stroke: blue + 2pt)
      content((5.8, 3.8), text(size: 7pt, "Software transform"), anchor: "center")
    })
  ]

  Only the bottom layer requires `async` - everything above could theoretically be synchronous! (See book by _Carl Fredrik Samson_)

]

#slide[
  === A basic TCP Stream


  #text(size: 10pt)[
    ```rust
    use futures::stream::StreamExt;

    let mut tcp_stream = tokio::net::TcpListener::bind("127.0.0.1:8080")
        .await?
        .incoming();

    while let Some(connection) = tcp_stream.next().await {
        handle_client(connection?).await;
    }
    ```]


]


#slide[
  === Problematic imperative stream processing

  *The challenge:* Process TCP connections, filter messages, and collect 5 long ones

  #text(size: 8pt)[
    ```rust
    let mut filtered_messages = Vec::new();
    let mut count = 0;
    let mut total_errors = 0;

    while let Some(connection) = tcp_stream.next().await {
        match connection {
            Ok(stream) => {
                if should_process(&stream) {
                    // More nested logic needed...
                }
            }
            Err(e) => {
                total_errors += 1;
                log_connection_error(e);
                if total_errors > 3 { break; }
            } } }
    ```]


]

#slide[
  === The complexity grows with each requirement

  *Inside the processing block, even more nested logic:*

  #text(size: 8pt)[
    ```rust
    // Inside the should_process(&stream) block:
    match process_stream(stream).await {
        Ok(msg) if msg.len() > 10 => {
            filtered_messages.push(msg);
            count += 1;
            if count >= 5 { break; }  // Break from outer loop!
        }
        Ok(_) => continue,  // Skip short messages
        Err(e) => {
            total_errors += 1;
            log_error(e);
            if total_errors > 3 { break; }  // Another outer break!
        }
    }
    ```]

  *Problems:* testing, coordination, control flow jumping around
]



#slide[
  === `Stream` preview

  Same logic, much cleaner with stream operators:

  #text(size: 10pt)[
    ```rust
    let filtered_messages: Vec<String> = tcp_stream
        .filter_map(|connection| ready(connection.ok()))
        .filter(|stream| ready(should_process(stream)))
        .then(|stream| process_stream(stream))
        .filter_map(|result| ready(result.ok()))
        .filter(|msg| ready(msg.len() > 10))
        .take(5)
        .collect()
        .await;
    ```]

  #align(center)[
    "Programs must be written *for people to read*, and only incidentally for machines to execute." — _Harold Abelson & Gerald Jay Sussman_]
]



#slide[
  == Rust's `Stream` trait


]


#slide[
  === Iterator vs Stream

  #align(center + horizon)[
    #canvas(length: 1cm, {
      import draw: *

      let draw-data-flow(start-x, title, calls, results, is-async) = {
        // Title
        content((start-x + 3, 5.5), text(size: 11pt, weight: "bold", title), anchor: "center")

        // Draw calls and results
        for (i, (call, result)) in calls.zip(results).enumerate() {
          let y = 4.5 - i * 0.8
          let result-color = if is-async and result.starts-with("Pending") { orange } else { green }

          // Call box
          rect((start-x, y - 0.2), (start-x + 2, y + 0.2), fill: rgb("e6f3ff"), stroke: blue)
          content((start-x + 1, y), text(size: 8pt, call), anchor: "center")

          // Arrow
          line((start-x + 2.1, y), (start-x + 2.9, y), mark: (end: ">"))

          // Result box
          rect((start-x + 3, y - 0.2), (start-x + 6, y + 0.2), fill: rgb("f0f0f0"), stroke: result-color)
          content((start-x + 4.5, y), text(size: 8pt, result), anchor: "center")
        }

        // Summary
        let summary = if is-async { "⚠️ May return Pending" } else { "✓ Always returns immediately" }
        content((start-x + 3, 0.5), text(size: 9pt, summary), anchor: "center")
      }

      // Iterator flow
      draw-data-flow(
        0,
        "Iterator (sync)",
        ("next()", "next()", "next()", "next()"),
        ("Some(1)", "Some(2)", "Some(3)", "None"),
        false,
      )

      // Stream flow
      draw-data-flow(
        8,
        "Stream (async)",
        ("poll_next()", "poll_next()", "poll_next()", "poll_next()"),
        ("Pending", "Ready(Some(1))", "Pending", "Ready(Some(2))"),
        true,
      )

      // VS separator
      content((7, 3), text(size: 14pt, weight: "bold", "vs"), anchor: "center")
    })
  ]

]

#slide[
  === `Stream` trait

  Similar to `Future`, but yields multiple items over time:

  #text(size: 10pt)[

    #grid(
      columns: (1fr, 1fr),
      [
        ```rust
        trait Stream {
            type Item;

            fn poll_next(
                self: Pin<&mut Self>,
                cx: &mut Context
            ) -> Poll<Option<Self::Item>>;
        }
        ```],
      [
        Returned values:

        1. `Pending` - Not ready yet, will notify via waker
        2. `Ready( ... )` - Ready with result:
          - `Some(item)` - New data is available
          - `None` - *May* be done - depends on stream type
      ],
    )]

  Ignore for now: `Context`, `Pin`.
]




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
  == Consumption of streams
]

#slide[
  === Building pipelines

  The basic stream operators of #link("https://docs.rs/futures/latest/futures/stream/trait.StreamExt.html")[`futures::StreamExt`]:

  #align(center)[
    #canvas(length: 1cm, {
      import draw: *

      let draw-stage(x, y, width, label, input, output, color) = {
        rect((x, y), (x + width, y + 0.8), fill: color, stroke: black, radius: 4pt)
        content((x + width / 2, y + 0.6), text(size: 7pt, weight: "bold", label), anchor: "center")
        content((x + width / 2, y + 0.4), text(size: 6pt, input), anchor: "center")
        content((x + width / 2, y + 0.2), text(size: 6pt, output), anchor: "center")

        if x > 0 {
          line((x - 2, y + 0.4), (x - 0.5, y + 0.4), mark: (end: ">"))
        }
      }

      // First row - transformation stages
      draw-stage(0, 3.5, 1.8, "iter(0..10)", "source", "0,1,2,3...", rgb("e6f3ff"))
      draw-stage(4, 3.5, 1.8, "map(*2)", "0,1,2,3...", "0,2,4,6...", rgb("fff0e6"))
      draw-stage(8, 3.5, 1.8, "filter(>4)", "0,2,4,6...", "6,8,10...", rgb("f0ffe6"))

      // Connection arrow between rows
      line((9, 3.1), (0.9, 2.7), mark: (end: ">"), stroke: blue + 1.5pt)

      // Second row - aggregation stages
      draw-stage(0, 1.5, 1.8, "enumerate", "6,8,10...", "(0,6),(1,8)...", rgb("ffe6f0"))
      draw-stage(4, 1.5, 1.8, "take(3)", "(0,6),(1,8)...", "first 3", rgb("f0e6ff"))
      draw-stage(8, 1.5, 2.2, "skip_while(<1)", "first 3", "(1,8),(2,10)", rgb("e6fff0"))
    })
  ]

  #align(center)[
    #text(size: 9pt)[
      ```rust
      stream::iter(0..10)
        .map(|x| x * 2)
        .filter(|&x| ready(x > 4))
        .enumerate().take(3).skip_while(|&(i, _)| i < 1)
      ```]

  ]]


#slide[
  === The less-known `futures::ready` function

  Filter needs an *async closure* (or closure returning `Future`):

  #text(size: 9pt)[
    ```rust
    // Option 1: Async block
    stream.filter(|&x| async move { x % 2 == 0 })
    // Option 2: Async closure (Rust 2025+)
    stream.filter(async |&x| x % 2 == 0)
    // Option 3: Wrap sync output with ready()
    stream.filter(|&x| ready(x % 2 == 0))
    ```
  ]
  `ready(value)` creates a `Future` that immediately resolves to `value`.

  *Bonus*: `future::ready()` is `Unpin`, helping make the entire stream pipeline `Unpin` (through common blanket implementations)!
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
  == Example 1: Doubling integer streams

]


#slide[


  === Step 1: The 'wrapper `Stream`' pattern



  ```rust
  struct Double<InSt> {
      in_stream: InSt,
  }
  impl<InSt> Double<InSt> {
    fn poll_next(self: Pin<&mut Self>, cx: &mut Context<'_>)
        -> Poll<Option<Self::Item>> {
              // ⚠️ Will not compile!
              self.in_stream.poll_next(cx).map(|x| x * 2)
    }
  }
  ```
  `Pin` blocks access to `self.in_stream`!
]


#slide[
  === *Projecting* the _'pinned wrapper'_ `Pin<&mut Double>`
  #text(size: 8pt)[
    #align(center)[
      #grid(
        columns: (1fr, auto, 1fr),
        column-gutter: 2em,
        row-gutter: 1.5em,
        // First row - diagrams
        [
          #canvas(length: 1.2cm, {
            import draw: *

            // Helper functions for Pin diagrams
            let draw-pin-shape(center, size, fill-color, stroke-color, label, label-pos, radius: 0.3) = {
              let half = size / 2
              rect(
                (center.at(0) - half, center.at(1) - half),
                (center.at(0) + half, center.at(1) + half),
                fill: fill-color,
                stroke: stroke-color + 2pt,
                radius: radius,
              )
              content(label-pos, text(size: 8pt, weight: "bold", label), anchor: "center")
            }

            let draw-nested-structure(center, outer-radius, inner-radius, outer-label, inner-label) = {
              circle(center, radius: outer-radius, fill: rgb("fff0e6"), stroke: orange + 1.5pt)
              content(
                (center.at(0), center.at(1) + 0.6),
                text(size: 7pt, weight: "bold", outer-label),
                anchor: "center",
              )
              circle(center, radius: inner-radius, fill: rgb("e6f3ff"), stroke: green + 1.5pt)
              content(center, text(size: 6pt, inner-label), anchor: "center")
            }

            // Pin<&mut Self> with nested circles
            draw-pin-shape((2, 2), 2.5, rgb("ffeeee"), blue, "Pin<&mut Double>", (2, 3.5))
            draw-nested-structure((2, 2), 0.8, 0.4, "Double", "InSt")
          })
        ],
        [
          #align(center + horizon)[
            #text(size: 20pt, weight: "bold")[⟶]
            #v(0.5em)
            *Warning*: only possible when\
            `Double<InSt>: Unpin`
          ]
        ],
        [
          #canvas(length: 1.2cm, {
            import draw: *

            // Helper functions for Pin diagrams
            let draw-pin-shape(center, size, fill-color, stroke-color, label, label-pos, radius: 0.3) = {
              let half = size / 2
              rect(
                (center.at(0) - half, center.at(1) - half),
                (center.at(0) + half, center.at(1) + half),
                fill: fill-color,
                stroke: stroke-color + 2pt,
                radius: radius,
              )
              content(label-pos, text(size: 8pt, weight: "bold", label), anchor: "center")
            }

            let draw-simple-inner(center, radius, label) = {
              circle(center, radius: radius, fill: rgb("e6f3ff"), stroke: green + 1.5pt)
              content(center, text(size: 6pt, label), anchor: "center")
            }

            // Pin<&mut InSt>
            draw-pin-shape((2, 2), 2, rgb("eeffee"), blue, "Pin<&mut InSt>", (2, 3.3), radius: 0.5)
            draw-simple-inner((2, 2), 0.4, "InSt")
          })
        ],
        // Second row - code fragments
        [
          ```rust
          self: Pin<&mut Self>
          ```
          How to convert into `&mut self.in_stream`?

        ],
        [
          ```rust
          let this =
                self // Pin<&mut Double>
                .get_mut() // &mut Double
                .in_stream; // &mut InSt
          ```
        ],
        [
          Can now call
          ```rust
          Pin::new(this)
              .poll_next(cx)
          ```
        ],
      )
    ]
  ]]



#slide[
  === `Pin`:  prevents movement only for types that need it (`!Unpin`)

  #text(size: 9pt)[
    Only two safe operations with `Pin`: creation and conditional escape

    #align(center)[
      #canvas(length: 1cm, {
        import draw: *

        // Three-column layout: Free bird | Arrows | Pinned bird

        // Left column: Free bird (can move)
        content((1, 3), text(size: 2em, "🐦"), anchor: "center")
        content((1, 2.3), text(size: 8pt, weight: "bold", "Free Bird"), anchor: "center")
        content((1, 2), text(size: 7pt, [(`Unpin`)]), anchor: "center")
        content((1, 1.6), text(size: 6pt, "✅ Can move"), anchor: "center")

        // Middle column: Arrows with operations

        // Pin::new() arrow (left to right)
        line((1.8, 3.0), (5.2, 3.0), mark: (end: ">"), stroke: blue + 3pt)
        content((3.5, 3.3), text(size: 7pt, weight: "bold", [`Pin::new()`]), anchor: "center")
        content((3.5, 2.7), text(size: 6pt, "Always safe"), anchor: "center")

        // Pin::get_mut() arrow (right to left)
        line((5.2, 2.0), (1.8, 2.0), mark: (end: ">"), stroke: green + 3pt)
        content((3.5, 2.3), text(size: 7pt, weight: "bold", [`Pin::get_mut()`]), anchor: "center")
        content((3.5, 1.7), text(size: 6pt, [if `T: Unpin`]), anchor: "center")

        // Right column: Pin box with bird inside (similar to previous slide style)
        let pin-width = 2.5
        let pin-height = 1.8
        let pin-x = 6.5
        let pin-y = 2.6

        // Pin box with similar styling as before
        rect(
          (pin-x - pin-width / 2, pin-y - pin-height / 2),
          (pin-x + pin-width / 2, pin-y + pin-height / 2),
          fill: rgb("ffeeee"),
          stroke: blue + 2pt,
          radius: 0.3,
        )
        content((pin-x, pin-y + 0.6), text(size: 8pt, weight: "bold", [`Pin<&mut Bird>`]), anchor: "center")

        // Bird inside the pin box
        content((pin-x, pin-y), text(size: 1.5em, "🐦"), anchor: "center")
        content((pin-x, pin-y - 0.6), text(size: 6pt, "📌 Caged "), anchor: "center")
      })
    ]

    #v(0.5em)

    #grid(
      columns: (1fr, 1fr),
      column-gutter: 1.5em,
      [
        *`Unpin` types* (safe to move)
        - Primitives, most structs, `Box<T>`

        ✅ Can use `Pin::get_mut()`
      ],
      [
        *`!Unpin` types* (self-referential)
        - Hand-written futures/generators

        ❌ `Pin::get_mut()` blocked by compiler
      ],
    )

    *Pin prevents movement by restricting safe functions to `Unpin` types only*


  ]
]

#slide[
  === Boxing `!Unpin` streams
  #text(size: 10pt)[
    *Can't access `!Unpin` stream inside `Pin<&mut Double>`*


    #grid(
      columns: (1fr, 1fr),
      column-gutter: 1em,
      [
        #rect(
          fill: red.lighten(90%),
          stroke: red.lighten(50%),
          radius: 8pt,
          inset: 1em,
          width: 100%,
          [
            #align(center)[
              *Before: `!Unpin` stream*

              #v(1em)

              ```rust
              struct Double<InSt> {
                stream: InSt  // !Unpin
              }
              ```

              #v(1em)

              ❌ Cannot escape `Pin` wrapper
            ]
          ],
        )
      ],
      [
        #rect(
          fill: green.lighten(90%),
          stroke: green.lighten(50%),
          radius: 8pt,
          inset: 1em,
          width: 100%,
          [
            #align(center)[
              *After: `Box` wrapper*

              #v(1em)

              ```rust
              struct Double<InSt> {
                stream: Box<InSt>  // Unpin!
              }
              ```

              #v(1em)

              ✅ Can safely call `.get_mut()`
            ]
          ],
        )
      ],
    )
  ]]

#slide[
  === Why `Box<T>` is always `Unpin`
  #text(size: 10pt)[
    #align(center)[
      #canvas(length: 1.2cm, {
        import draw: *

        // Stack - Box pointer
        rect((1, 3), (4, 5), fill: rgb("e6f3ff"), stroke: blue + 2pt)
        content((2.5, 4.3), text(size: 9pt, weight: "bold", "Stack"), anchor: "center")
        content((2.5, 3.7), text(size: 8pt, "Box<InSt>"), anchor: "center")
        content((2.5, 3.3), text(size: 7pt, "✅ Safe to move"), anchor: "center")

        // Arrow to heap
        line((4.2, 4), (6.3, 4), mark: (end: ">"), stroke: orange + 2pt)
        content((5.25, 4.5), text(size: 7pt, "points to"), anchor: "center")

        // Heap - actual stream
        rect((6.5, 3), (9.5, 5), fill: rgb("fff0e6"), stroke: orange + 2pt)
        content((8, 4.3), text(size: 9pt, weight: "bold", "Heap"), anchor: "center")
        content((8, 3.7), text(size: 8pt, "InSt (!Unpin)"), anchor: "center")
        content((8, 3.3), text(size: 7pt, "📌 Fixed address"), anchor: "center")
      })
    ]
  ]


  1. `Box` is just a pointer - moving pointers is safe
  2. Heap content stays at fixed address
  3. `Box<T>` derefs to `T` - behaves like the stream
  4. Even `!Unpin` content becomes accessible through `Unpin` `Box`

  *Result:* `Box<InSt>` is always `Unpin` → `Double<InSt>` becomes `Unpin` ✅
]

#slide[



  === Step 3: Stripping the `Pin` safely from `Unpin`

  ... and wrapping it around the boxed stream:

  #align(center)[
    #canvas(length: 1.2cm, {
      import draw: *

      // Helper functions for Pin diagrams (reused from earlier slide)
      let draw-pin-shape(center, size, fill-color, stroke-color, label, label-pos, radius: 0.3) = {
        let half = size / 2
        rect(
          (center.at(0) - half, center.at(1) - half),
          (center.at(0) + half, center.at(1) + half),
          fill: fill-color,
          stroke: stroke-color + 2pt,
          radius: radius,
        )
        content(label-pos, text(size: 8pt, weight: "bold", label), anchor: "center")
      }

      let draw-nested-structure(center, outer-radius, inner-radius, outer-label, inner-label) = {
        circle(center, radius: outer-radius, fill: rgb("fff0e6"), stroke: orange + 1.5pt)
        content((center.at(0), center.at(1) + 1.7), text(size: 7pt, weight: "bold", outer-label), anchor: "center")
        circle(center, radius: inner-radius, fill: rgb("e6f3ff"), stroke: green + 1.5pt)
        content(center, text(size: 6pt, inner-label), anchor: "center")
        content((center.at(0), center.at(1) - 0.3), text(size: 5pt, [`(!Unpin)`]), anchor: "center")
      }

      let draw-box-wrapper(center, width, height, label, label-pos) = {
        rect(
          (center.at(0) - width / 2, center.at(1) - height / 2),
          (center.at(0) + width / 2, center.at(1) + height / 2),
          fill: none,
          stroke: (paint: purple, dash: "dashed", thickness: 2pt),
        )
        content(label-pos, text(size: 6pt, weight: "bold", label), anchor: "center")
      }

      let draw-annotation(pos, text1, text2) = {
        content(pos, text(size: 6pt, fill: purple, text1), anchor: "center")
        content((pos.at(0), pos.at(1) - 0.3), text(size: 6pt, fill: purple, text2), anchor: "center")
      }

      // Left side: Pin<&mut Self>
      draw-pin-shape((2, 4), 4, rgb("ffeeee"), blue, [`Pin<&mut Double>`], (2, 6.3))
      draw-nested-structure((2, 4), 1.5, 0.5, [`Double`], [`InSt`])
      draw-box-wrapper((2, 4), 1.8, 1.8, [`Box<InSt>`], (2, 5.2))

      // get_mut arrow


      // Box annotation
      draw-annotation((0.5, 5.8), "Box makes", [it `Unpin`])

      // Right side: &mut Box<InSt>
      draw-pin-shape((7.4, 4.2), 2.5, rgb("ffeeee"), blue, "", (8, 6.3))
      draw-box-wrapper((7.4, 4.1), 1.6, 1.6, [`&mut  Box<InSt>`], (7.4, 5.2))
      circle((7.4, 4.1), radius: 0.6, fill: rgb("e6f3ff"), stroke: green + 1.5pt)
      content((7.4, 4.3), text(size: 6pt, [`InSt`]), anchor: "center")
      content((7.4, 3.8), text(size: 5pt, [(`!Unpin`)]), anchor: "center")
      content((7.4, 6.0), text(size: 8pt, weight: "bold", [`Pin<&mut Double>`]), anchor: "center")
      line((4.3, 4), (6.5, 4), mark: (end: ">"), stroke: red + 2pt)
      content((5.15, 4.5), text(size: 7pt, weight: "bold", [`Pin::get_mut()`]), anchor: "center")
    })
  ]

]




#slide[
  === Finish `Stream` impl
  We can call `get_mut()` to get `&mut Double<InSt>` safely since:
  - `self` is of type `Pin<&mut Double<InSt>>`
  - `Double<InSt>` is `Unpin`,


  #text(size: 9pt)[
    ```rust
    impl<InSt> Stream for Double<InSt>
    where InSt: Stream<Item = i32>
    {
        fn poll_next(self: Pin<&mut Self>, cx: &mut Context<'_>)
            -> Poll<Option<Self::Item>>
        {
            let this = self.get_mut(); // Safe because Double is Unpin
            Pin::new(&mut this.stream).poll_next(cx)
            ...
        }
    }
    ```]
]





#slide[
  === Step 4: Extension trait and *'blanket' `impl`*

  Create an extension trait to add `.double()` method to any integer stream:

  ```rust
  trait DoubleStream: Stream {
      fn double(self) -> Double<Self>
      where Self: Sized + Stream<Item = i32>,
      { Double::new(self) }
  }
  ```

  Add a *blanket `impl`* that automatically implements `DoubleStream` for any `Stream<Item = i32>`:

  ```rs
  impl<S> DoubleStream for S where S: Stream<Item = i32> {}
  ```

  *Important*: The `DoubleStream` trait must be in scope to use `.double()`

]

#slide[
  === Users just add dependency + import

  Super simple for users to adopt your custom operators:

  ```toml
  [dependencies]
  double-stream = "1.0"
  ```

  ```rust
  use double_stream::DoubleStream;  // Trait in scope

  let doubled = stream::iter(1..=5).double();  // Now works!
  ```
  *Compositionality of traits* (versus traditional OOP) shines!
]

#slide[

  == Example 2: Cloning streams at run-time (optional)
]


#slide[
  === Before building your own operators

  *Check existing solutions first:*

  #grid(
    columns: (1fr, 1fr),
    gutter: 2em,
    [
      *Official*: #link("https://docs.rs/futures/latest/futures/stream/trait.StreamExt.html")[`futures::StreamExt`]

      - Production ready & comprehensive
      - 5.7k ⭐, 342 contributors
      - Since 2016, actively maintained
      - Latest: v0.3.31 (Oct 2024)
    ],
    [
      *Community*: #link("https://crates.io/crates/futures-rx")[`futures-rx`]

      - Reactive operators & specialized cases
      - 8 ⭐, small project
      - Since Dec 2024, very new
      - Fills gaps in StreamExt
    ],
  )

  *Build custom only when no existing operator fits*
]


#slide[
  === Problem: most streams aren't `Clone`

  Many useful streams can't be copied:

  #text(size: 10pt)[
    ```rust
    let tcp_stream = TcpStream::connect("127.0.0.1:8080").await?;
    let lines = BufReader::new(tcp_stream).lines();

    let copy = lines.clone(); // Error! Can't clone TCP stream
    ```]

  *But*: Sometime you need multiple consumers.

  *Solution*: a crate #link("https://crates.io/crates/clone-stream")[`clone-stream`] makes any stream cloneable:

  Pre-existing stream cloning crate: `fork_stream`.
]

#slide[
  #align(center)[
    #canvas(length: 1.2cm, {
      import draw: *

      let draw-stream-box(pos, label, color) = {
        let (x, y) = pos
        rect((x - 1.2, y - 0.5), (x + 1.2, y + 0.5), fill: color, stroke: black + 1pt)
        content((x, y), text(size: 8pt, weight: "bold", label), anchor: "center")
      }

      let draw-data-flow(y, items) = {
        for (i, item) in items.enumerate() {
          let x = 5.5 + i * 0.8
          circle((x, y), radius: 0.25, fill: rgb("fff3cd"), stroke: orange + 1pt)
          content((x, y), text(size: 7pt, item), anchor: "center")
        }
      }

      // Source stream
      draw-stream-box((1, 3), "TCP Stream", rgb("e6f3ff"))

      // Fork operation
      rect((3.5, 2.5), (4.5, 3.5), fill: rgb("f0ffe6"), stroke: green + 2pt)
      content((4, 3), text(size: 7pt, weight: "bold", ".fork()"), anchor: "center")

      // Data items flowing right
      draw-data-flow(3, ("'a'", "'b'", "'c'", "'d'"))

      // Fork arrow right
      line((2.2, 3), (3.3, 3), mark: (end: ">"), stroke: blue + 2pt)

      // Split arrows to clones
      line((4.7, 3), (6.8, 4.5), mark: (end: ">"), stroke: purple + 2pt)
      line((4.7, 3), (6.8, 1.5), mark: (end: ">"), stroke: purple + 2pt)

      // Clone streams
      draw-stream-box((8, 5), "Parser Clone", rgb("ffeeee"))
      draw-stream-box((8, 1), "Logger Clone", rgb("fff0e6"))

      // Data flows to both clones
      draw-data-flow(5, ("'a'", "'b'"))
      draw-data-flow(1, ("'a'", "'b'"))

      // Labels
      content((5.8, 4), text(size: 7pt, ".clone()"), anchor: "center")
      content((5.8, 2), text(size: 7pt, ".clone()"), anchor: "center")
    })
  ]

]








#slide[
  #set text(size: 8pt)
  === Visualizing the polling and waking flow

  #align(center)[
    #diagram(
      node-corner-radius: 5pt,
      spacing: (3em, 2.5em),

      // Base stream at bottom
      node(
        (1, 0),
        [Base Stream],
        fill: rgb("e6f3ff"),
        stroke: blue + 2pt,
      ),

      // Alice - sleeping after first poll
      node(
        (0, 3),
        [Alice\ 💤 Sleeping],
        fill: rgb("ffcccc"),
        stroke: red + 2pt,
        shape: fletcher.shapes.circle,
      ),

      // Bob - actively polling
      node(
        (2, 3),
        [Bob\ 🔍 Polling],
        fill: rgb("ccffcc"),
        stroke: green + 2pt,
        shape: fletcher.shapes.circle,
      ),

      // Data item that will be shared
      node((1, 1.5), [data 'x'], fill: rgb("fff3cd"), stroke: orange + 2pt),

      // Flow sequence with better spacing
      edge((1, 0), (1, 1.5), [ready], "->", stroke: orange + 2pt),
      edge((0, 3), (1, 0), [1. poll\ (not ready)], "->", stroke: gray + 1.5pt, bend: 50deg),
      edge((2, 3), (1, 0), [2. poll\ (ready!)], "->", stroke: green + 2pt, bend: -50deg),
      edge((2, 3), (0, 3), [3. wake Alice], "->", stroke: blue + 2pt, bend: 40deg),
      edge((1, 1.5), (0, 3), [4. copy], "->", stroke: orange + 1.5pt, bend: -40deg),
      edge((1, 1.5), (2, 3), [5. original], "->", stroke: orange + 1.5pt, bend: 40deg),
    )
  ]

]


#slide[
  === Complexity grows with thousands of clones

  Real-world challenges that require careful state management:


  #grid(
    columns: (1fr, 1fr),
    column-gutter: 2em,
    [
      *Dynamic clone lifecycle:*
      - Clones created at runtime
      - Clones dropped unexpectedly
      - Avoid memory leaks
    ],
    [
      *Ordering guarantees:*
      - All clones see same order
      - No clone misses values
      - Handle concurrent access
    ],
  )


  #align(center)[
    #canvas(length: 1cm, {
      import draw: *

      // Shared queue visualization
      rect((1, 2), (7, 3), fill: rgb("f0f0f0"), stroke: black + 2pt)
      content((4, 2.5), text(size: 9pt, weight: "bold", "Shared Queue (RwLock)"))

      // Multiple clones at different positions
      let clone-positions = ((0.5, 1), (2, 0.5), (4, 0.2), (6, 1.2), (7.5, 0.8))
      for (i, pos) in clone-positions.enumerate() {
        let (x, y) = pos
        circle((x, y), radius: 0.2, fill: if i < 2 { rgb("ffcccc") } else { rgb("ccffcc") })
        content((x, y - 0.5), text(size: 6pt, "C" + str(i + 1)), anchor: "center")
      }

      content((4, 1), text(size: 8pt, "Thousands of clones..."), anchor: "center")
    })
  ]

]



#slide[
  === The right approach: behavior-driven design
  #v(2em)
  State machines are everywhere because *every program is a state machine* (Turing)

  #grid(
    columns: (1fr, 1fr),
    column-gutter: 3em,
    [
      #rect(
        fill: blue.lighten(90%),
        stroke: blue.lighten(50%),
        radius: 8pt,
        inset: 1.5em,
        width: 100%,
        [
          *Start with:*


          - Required behavior (tests)
          - Performance requirements

        ],
      )
    ],
    [
      #rect(
        fill: green.lighten(90%),
        stroke: green.lighten(50%),
        radius: 8pt,
        inset: 1.5em,
        width: 100%,
        [
          *Then derive:*


          - Minimal state set
          - Clean transitions
          - Minimise function calls
        ],
      )
    ],
  )



  #align(center)[
    "Perfection is achieved, not when there is nothing more to add, but when there is nothing left to take away." — _Antoine de Saint-Exupéry_
  ]

]


#slide[
  #let yellow-color = rgb("ffffcc")
  #let green-color = rgb("ccffcc")
  #let red-color = rgb("ffcccc")

  === Example: `clone-stream` states and transitions
  #text(size: 8pt)[
    Final #link("https://github.com/wvhulle/clone-stream/tree/main/src/states")[`clone-stream` states]:
    #align(center)[
      #diagram(
        node-stroke: 1pt,
        spacing: (3em, 1.5em),

        // Top row: Ready states
        node((0, 1), text(size: 7pt)[AwaitingFirstItem], fill: yellow-color, shape: pill),
        node((1, 1), text(size: 7pt)[BaseStreamReady], fill: green-color, shape: pill),
        node((2, 1), text(size: 7pt)[BaseStreamReady\ WithHistory], fill: green-color, shape: pill),
        node((3, 1), text(size: 7pt)[ProcessingQueue], fill: green-color, shape: pill),

        // Bottom row: Pending states with wakers
        node((0, 0), text(size: 7pt)[AwaitingBase\ 💤], fill: red-color, stroke: red + 2pt, shape: pill),
        node(
          (2, 0),
          text(size: 7pt)[AwaitingBase\ WithHistory\ 💤],
          fill: red-color,
          stroke: red + 2pt,
          shape: pill,
        ),

        // Main flow transitions
        edge((0, 1), (1, 1), text(size: 6pt)[ready], "->"),
        edge((1, 1), (2, 1), text(size: 6pt)[history], "->"),
        edge((2, 1), (3, 1), text(size: 6pt)[queue], "->"),
        edge((3, 1), (2, 1), text(size: 6pt)[done], "->", bend: 30deg),

        // Pending transitions
        edge((1, 1), (0, 0), text(size: 6pt)[pending], "->", bend: -20deg),
        edge((2, 1), (2, 0), text(size: 6pt)[pending], "->", bend: 20deg),
        edge((0, 0), (1, 1), text(size: 6pt)[ready], "->", bend: -20deg),
        edge((0, 0), (3, 1), text(size: 6pt)[queue ready], "->", bend: 40deg),
        edge((2, 0), (3, 1), text(size: 6pt)[queue ready], "->", bend: 0deg),
        edge((2, 0), (2, 1), text(size: 6pt)[ready], "->", bend: 20deg),
      )
    ]


    #grid(
      columns: (1fr, 1fr),
      gutter: 2em,
      [
        - #box(rect(width: 0.8em, height: 0.8em, fill: yellow-color, stroke: 0.5pt)) Yellow: Initial state, reads from base stream
        - #box(rect(width: 0.8em, height: 0.8em, fill: green-color, stroke: 0.5pt)) Green: Processing items (base or queue)
      ],
      [
        - #box(rect(width: 0.8em, height: 0.8em, fill: red-color, stroke: 0.5pt)) Red: Pending state with stored waker
      ],
    )]


]




#slide[
  == Side remarks
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

  Longer introduction to streams: #link("https://willemvanhulle.tech/blog/streams/func-async/")[willemvanhulle.tech/blog/streams/func-async]
]

#slide[
  === Last recommendation

  *⚠️ Streams don't replace good software engineering!*

  #align(horizon)[
    #grid(
      columns: (1fr, 1fr, 1fr),
      gutter: 2em,
      [
        *Don't overuse streams:*
        - Keep pipelines short
        - Only _physical async data flow_
      ],
      [
        *Follow best practices:*
        - Modular functions
        - Descriptive names
        - Split long functions
      ],
      [
        *Use objective targets:*
        - Interval-based tests
        - Representative benchmarks (use `criterion`)
      ],
    )

    #v(0.5em)

    #align(center)[
      "When you have a hammer, everything looks like a nail." _— Abraham Maslow_




    ]
  ]]


#slide[


  #align(center)[

    #text(size: 1em)[Any questions?]

    #text(size: 2em)[Thank you!]

    Willem Vanhulle \

    #v(3em)


    Feel free to reach out!

    #link("mailto:willemvanhulle@protonmail.com") \
    #link("https://willemvanhulle.tech")[willemvanhulle.tech] \
    #link("https://github.com/wvhulle/streams-eurorust-2025")[github.com/wvhulle/streams-eurorust-2025]
  ]


]
