// Import template
#import "template.typ": presentation-template, slide
#import "@preview/cetz:0.4.2": canvas, draw

// Apply template and page setup
#show: presentation-template.with(
  title: "Make Your Own Stream Operators",
  subtitle: "Playing with moving data in Rust",
  author: "Willem Vanhulle",
  event: "EuroRust 2025",
  location: "Paris, France",
  duration: "30 minutes + 10 minutes Q&A",
)




#slide[
  === Why streams matter: real-world chaos

  *The problem:* Processing streaming data from moving vehicles

  *What I observed:*
  - Every developer had their own approach
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

      // Chaos emoji
      content((4, 2), text(size: 2.5em, "🔥"), anchor: "center")
      content((4, 1.2), text(size: 8pt, weight: "bold", "Developer Chaos"), anchor: "center")
    })
  ]

  *The realization:* Most developers encounter streams too late in distributed systems
]

#slide[
  === About me

  *My stream processing journey:*
  - Started with reactive programming in TypeScript
  - Moved to vehicle telemetry systems in Rust
  - Struggled with async lifetimes and memory management

  *Today:* Want to share the patterns I discovered the hard way
]

#slide[
  === Why reactive programming feels different in Rust

  *Key insight:* Reactivity in garbage collected languages is *completely different* from Rust's ownership system

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
  === Real-world streaming scenarios

  Data that arrives over time needs async handling:

  #text(size: 10pt)[
    ```rust
    use tokio::net::TcpListener;
    use futures::stream::StreamExt;

    // Incoming network messages
    let mut tcp_stream = TcpListener::bind("127.0.0.1:8080")
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

  *Problems:* Nested breaks, scattered error handling, mixed concerns
]

#slide[
  === Problems with imperative approach

  #grid(
    columns: (1fr, 1fr),
    gutter: 3em,
    [
      *🧠 Hard to reason about:*
      - Multiple mutable variables
      - Control flow chaos (`if`, `break`, `continue`)
      - Scattered error handling

      *🧪 Hard to test:*
      - No isolation of transformations
      - Complex state combinations
    ],
    [
      *🔧 Hard to maintain:*
      - Changes touch multiple paths
      - Cannot reuse components
      - Easy to introduce bugs with nested loops

      *Result:* Technical debt accumulates quickly
    ],
  )
]

#slide[
  === Functional approach preview

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

  *What do you think?*
]

#slide[

  #align(center)[*Goal:* Build your own stream operators with confidence!]

  #v(2em)

  #outline(
    title: none,
    indent: auto,
    depth: 2,
  )

]

#slide[
  == The `Stream` trait


]

#slide[
  === Water vs. `Stream`s

  *Stream in Rust ≠ Moving body of water* 🌊

  A stream is simply an *front-end for the carrier* that we can process and feed into something else.

  #align(center + horizon)[
    #canvas(length: 1cm, {
      import draw: *

      // Stream container (front-end - Stream trait)
      rect((1, 1), (7, 3), fill: rgb("e6f3ff"), stroke: blue + 3pt, radius: 0.2)
      content((4, 3.5), text(size: 10pt, weight: "bold", "Stream Trait (Front-end)"), anchor: "center")


      // Data flow arrow (back-end - data carrier)
      line((1.5, 2), (6.5, 2), stroke: orange + 8pt, mark: (end: ">"))

      // Data items flowing through
      for (i, item) in ("'a'", "'b'", "'c'", "'d'").enumerate() {
        let x = 2.2 + i * 1.2
        circle((x, 2), radius: 0.15, fill: rgb("fff3cd"), stroke: orange + 2pt)
        content((x, 2), text(size: 7pt, item), anchor: "center")
      }

      content((4, 1.4), text(size: 10pt, weight: "bold", "Data Carrier (Back-end)"), anchor: "center")

      // Labels with arrows pointing to components
      line((1, 0.5), (2, 1.8), mark: (end: ">"), stroke: gray + 1pt)
      content((0.8, 0.3), text(size: 8pt, "TCP, Channel,\nIterator, etc."), anchor: "center")
    })
  ]

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
    ```rust
    trait Stream {
        type Item;

        fn poll_next(
            self: Pin<&mut Self>,
            cx: &mut Context
        ) -> Poll<Option<Self::Item>>;
    }
    ```]

  - *`Context`*: Runtime manages this - contains waker for async notifications
  - *Returns*: `Poll<Option<Item>>` instead of `Poll<Item>` (futures)
  - *Pin safety*: Same as futures - prevents moving during async operations
]

#slide[
  === Stream polling results

  Three possible outcomes when polling:

  #align(center)[
    #text(size: 10pt)[
      #table(
        columns: 2,
        stroke: 0.5pt,
        align: left,
        [*Return Value*], [*Meaning*],
        [`Ready(Some(item))`], [New data is available],
        [`Ready(None)`], [*May* be done - depends on stream type],
        [`Pending`], [Not ready yet, will notify via waker],
      )
    ]]

  When `Pending`: runtime suspends task until waker signals readiness
]

#slide[
  === The meaning of `Ready(None)`

  `None` from a stream has different meanings depending on the stream type:

  #grid(
    columns: (1fr, 1fr),
    gutter: 3em,
    [
      #align(center)[*Regular Stream*]

      `None` is *temporary* - the stream might yield more items later

      *Example:* Empty channel buffer waiting for new messages
    ],
    [
      #align(center)[*Fused Stream*]

      `None` is *permanent* - the stream will never yield items again

      *Create with:* `.fuse()` method (like `Iterator::fuse()`)
    ],
  )
]

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
      rows: (auto, auto, auto, auto),
      gutter: 2em,
      [], [*Future*], [*Stream*], [*Meaning*],
      [*Regular*],
      [#draw-arrow(multiple: false, fused: false, blue)],
      [#draw-arrow(multiple: true, fused: false, green)],
      [May continue],

      [*Fused*],
      [#draw-arrow(multiple: false, fused: true, blue)],
      [#draw-arrow(multiple: true, fused: true, green)],
      [Done permanently],

      [*Fused value*], [Pending], [Ready(None)], [Final value],
    )
  ]
]

#slide[
  === Why `is_terminated()` exists

  Checking if a *fused* stream/future is done can be done *immediately*, without polling:

  ```rust
  fn is_terminated(&self) -> bool;
  ```

  Use cases:
  - *Avoid unnecessary polling*: Skip polling if already terminated
  - *Resource cleanup*: Know when to drop or ignore inactive streams or futures

]


#slide[
  === `Stream` vs `AsyncIterator`

  #grid(
    columns: (1fr, 1fr),
    gutter: 1.5em,
    [
      *`Stream` (futures)*
      - Rich combinators
      - Production ready
      - Full ecosystem
    ],
    [
      *`AsyncIterator` (std)*
      - Nightly only
      - No combinators
      - Experimental
    ],
  )

  *Use `Stream`* - `AsyncIterator` still lacks essential features
]




#slide[
  == Consumption of streams
]

#slide[
  === Common existing operators

  Transform and filter stream items functionally:

  #align(center)[
    #canvas(length: 1cm, {
      import draw: *

      let draw-stage(x, y, width, label, input, output, color) = {
        rect((x, y), (x + width, y + 0.8), fill: color, stroke: black)
        content((x + width / 2, y + 0.6), text(size: 7pt, weight: "bold", label), anchor: "center")
        content((x + width / 2, y + 0.4), text(size: 6pt, input), anchor: "center")
        content((x + width / 2, y + 0.2), text(size: 6pt, output), anchor: "center")

        if x > 0 {
          line((x - 0.2, y + 0.4), (x + 0.1, y + 0.4), mark: (end: ">"))
        }
      }

      // First row - transformation stages
      draw-stage(0, 3.5, 1.8, "iter(0..10)", "source", "0,1,2,3...", rgb("e6f3ff"))
      draw-stage(2, 3.5, 1.8, "map(*2)", "0,1,2,3...", "0,2,4,6...", rgb("fff0e6"))
      draw-stage(4, 3.5, 1.8, "filter(>4)", "0,2,4,6...", "6,8,10...", rgb("f0ffe6"))

      // Connection arrow between rows
      line((5.8, 3.1), (0.9, 2.7), mark: (end: ">"), stroke: blue + 1.5pt)

      // Second row - aggregation stages
      draw-stage(0, 1.5, 1.8, "enumerate", "6,8,10...", "(0,6),(1,8)...", rgb("ffe6f0"))
      draw-stage(2, 1.5, 1.8, "take(3)", "(0,6),(1,8)...", "first 3", rgb("f0e6ff"))
      draw-stage(4, 1.5, 2.2, "skip_while(<1)", "first 3", "(1,8),(2,10)", rgb("e6fff0"))
    })
  ]

  #v(0.5em)

  #text(size: 8pt)[
    ```rust
    stream::iter(0..10).map(|x| x * 2).filter(|&x| ready(x > 4))
        .enumerate().take(3).skip_while(|&(i, _)| i < 1)
    ```]

]


#slide[
  === The 'ready trick'

  Stream operators expect async closures returning `Future`s:

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
  === Flattening stream collections

  Takes an iterator/IntoIterator of streams and merges them:

  ```rust
  let streams = vec![
      stream::iter(1..=3),
      stream::iter(4..=6),
      stream::iter(7..=9),
  ];

  let merged = stream::select_all(streams);
  ```


  Merges all streams concurrently
]

#slide[
  === Flattening an infinite stream


  Use `flatten_unordered`, `flatten`, or `switch`:

  ```rust
  let requests = stream::unfold(0, |id| async move {
      // Each `fetch_stream` returns a stream of data chunks
      Some((fetch_stream(format!("/api/data/{}", id)), id + 1))
  });

  let flat = requests.flatten_unordered(Some(10));
  ```

  Processes up to 10 concurrent request streams

]

#slide[
  == Streams 'in the wild'
]

#slide[
  === Channel receivers as streams

  #link("https://docs.rs/async-channel/2.5.0/async_channel/")[`async-channel`] receivers implement `Stream` directly:

  ```rust
  use async_channel::unbounded;
  let (tx, rx) = unbounded();

  // rx is already a Stream!
  rx.map(|msg| format!("Got: {}", msg))
    .collect::<Vec<_>>()
    .await;
  ```

  Alternative with more channel types: #link("https://docs.rs/postage/latest/postage/")[`postage`] (older).
]

#slide[
  === Tokio channels

  Tokio channels need `tokio_stream` wrappers to become streams:

  ```rust
  let (tx, rx) = tokio::sync::broadcast::unbounded();
  tokio_stream::wrappers::BroadcastStream::new(rx)
      .collect::<Vec<_>>()
      .await;
  ```

  For converting sender into `Sink`, you need `tokio-util` crate.

  *Not a great experience for beginners...*

]




#slide[
  === Ignoring broadcast errors

  Broadcast streams return `Result<T, BroadcastStreamRecvError>`:

  ```rust
  // Easy way: ignore all errors
  BroadcastStream::new(rx)
      .filter_map(|result| ready(result.ok()))
      .collect::<Vec<_>>()
      .await
  ```

  - `Result::ok()` converts `Result<T, E>` → `Option<T>`
  - `filter_map` drops `None` values (errors become `None`)

  ⚠️ *Warning*: Silently drops `Lagged` errors (missed messages)
]

#slide[
  === Before building your own operators

  *Check existing solutions first:*

  #grid(
    columns: (1fr, 1fr),
    gutter: 2em,
    [
      *Official*: #link("https://docs.rs/futures/latest/futures/stream/trait.StreamExt.html")[`futures::StreamExt`]

      Production ready & comprehensive
    ],
    [
      *Community*: #link("https://crates.io/crates/futures-rx")[`futures-rx`]

      Reactive operators & specialized cases
    ],
  )

  *Build custom only when no existing operator fits*
]

#slide[
  == Basic stream operator

]


#slide[


  === Wrapper pattern

  Most custom operators follow this structure:

  ```rust
  struct Double<InSt> {
      stream: InSt,
  }
  impl<InSt> Double<InSt> {
    fn poll_next(self: Pin<&mut Self>, cx: &mut Context<'_>)
        -> Poll<Option<Self::Item>> {
              // Delegate to inner stream (will not compile!)
              self.stream.poll_next(cx).map(|x| x * 2)
    }
  }
  ```
  ⚠️ Delegation is not possible without removing `Pin`!
]



#slide[
  === Pin projection concept

  We cannot just convert `self` into `&mut self.stream`!

  #text(size: 10pt)[
    ```rust
    fn poll_next(self: Pin<&mut Self>, cx: &mut Context<'_>)
        -> Poll<Option<Self::Item>> {
              self.stream.poll_next(cx).map(|x| x * 2)
    }
    ```
  ]

  We need projection to access inner stream safely

  #text(size: 10pt)[
    ```rust
    fn poll_next(self: Pin<&mut Self>, cx: &mut Context<'_>)
        -> Poll<Option<Self::Item>> {
              Pin::new(self.project()).poll_next(cx).map(|x| x * 2)
    }
    ```
  ]
]

#slide[
  === Pin projection


  #align(center)[
    #canvas(length: 1.2cm, {
      import draw: *

      let draw-square(center, size, fill-color, stroke-color, label, label-pos) = {
        let half = size / 2
        rect(
          (center.at(0) - half, center.at(1) - half),
          (center.at(0) + half, center.at(1) + half),
          fill: fill-color,
          stroke: stroke-color + 2pt,
        )
        content(label-pos, text(size: 8pt, weight: "bold", label), anchor: "center")
      }

      // Left side: Pin<&mut Self>
      draw-square((2, 4), 4, rgb("ffeeee"), blue, "Pin<&mut Self>", (2, 6.3))

      // Double wrapper circle
      circle((2, 4), radius: 1.2, fill: rgb("fff0e6"), stroke: orange + 1.5pt)
      content((2, 5.5), text(size: 7pt, weight: "bold", "Double"), anchor: "center")

      // Inner stream circle
      circle((2, 4), radius: 0.6, fill: rgb("e6f3ff"), stroke: green + 1.5pt)
      content((2, 4), text(size: 7pt, "InSt"), anchor: "center")

      // Projection arrow
      line((4.3, 4), (6.2, 4), mark: (end: ">"), stroke: blue + 2pt)
      content((5.25, 4.5), text(size: 7pt, weight: "bold", "Pin projection"), anchor: "center")

      // Right side: Pin<&mut InSt>
      draw-square((7.4, 4.1), 1.8, rgb("eeffee"), blue, "Pin<&mut InSt>", (7.4, 5.3))

      // Projected inner stream
      circle((7.4, 4.1), radius: 0.6, fill: rgb("e6f3ff"), stroke: green + 1.5pt)
      content((7.4, 4.1), text(size: 7pt, "InSt"), anchor: "center")
    })
  ]
]

#slide[
  === Why Pin exists: self-referential futures

  Futures are state machines that can reference their own data:

  #grid(
    columns: (1fr, 1fr),
    gutter: 1.5em,
    [
      *Your async code:*
      #text(size: 9pt)[
        ```rust
        async fn example() {
            let data = vec![1, 2, 3];
            let reference = &data[0];
            some_async_fn().await;
            println!("{}", reference);
        }
        ```
      ]

      Reference points into owned data
    ],
    [
      *Compiler generates:*
      #text(size: 9pt)[
        ```rust
        struct ExampleFuture {
            data: Vec<i32>,
            reference: *const i32, // ⚠️
            // ... other state
        }
        ```
      ]

      Pointer into same struct!
    ],
  )

  ⚠️ Moving this struct breaks internal pointers → undefined behavior
]

#slide[
  === Pin protects futures and streams

  Both are self-referential state machines that cannot be moved:

  ```rust
  // Future version:
  fn poll(self: Pin<&mut Self>, cx: &mut Context) -> Poll<T> {}

  // Stream version:
  fn poll_next(self: Pin<&mut Self>, cx: &mut Context) -> Poll<Option<T>> {}
  ```

  Pin promise: *"The thing this points to won't move anymore"* (unless destroyed)
]

#slide[



  === Stripping the `Pin` safely from `Unpin`

  #align(center)[
    #canvas(length: 1.2cm, {
      import draw: *

      let draw-square(center, size, fill-color, stroke-color, label, label-pos) = {
        let half = size / 2
        rect(
          (center.at(0) - half, center.at(1) - half),
          (center.at(0) + half, center.at(1) + half),
          fill: fill-color,
          stroke: stroke-color + 2pt,
        )
        content(label-pos, text(size: 8pt, weight: "bold", label), anchor: "center")
      }

      // Left side: Pin<&mut Self>
      draw-square((2, 4), 4, rgb("ffeeee"), blue, "Pin<&mut Self>", (2, 6.3))

      // Double wrapper circle
      circle((2, 4), radius: 1.2, fill: rgb("fff0e6"), stroke: orange + 1.5pt)
      content((2, 5.5), text(size: 7pt, weight: "bold", "Double"), anchor: "center")

      // Inner stream circle with Unpin annotation
      circle((2, 4), radius: 0.6, fill: rgb("e6f3ff"), stroke: green + 1.5pt)
      content((2, 4.2), text(size: 6pt, "InSt"), anchor: "center")
      content((2, 3.7), text(size: 5pt, "Unpin"), anchor: "center")

      // get_mut arrow
      line((4.3, 4), (6.2, 4), mark: (end: ">"), stroke: red + 2pt)
      content((5.25, 4.5), text(size: 7pt, weight: "bold", "get_mut()"), anchor: "center")

      // Arrow pointing to Double circle
      line((5.5, 6.5), (2.4, 5.0), mark: (end: ">"), stroke: purple + 1.5pt)
      content((6.0, 6.8), text(size: 7pt, "Also Unpin"), anchor: "center")

      // Right side: &mut InSt (no Pin box!)
      circle((7.4, 4.1), radius: 0.6, fill: rgb("e6f3ff"), stroke: green + 1.5pt)
      content((7.4, 4.3), text(size: 6pt, "InSt"), anchor: "center")
      content((7.4, 3.8), text(size: 5pt, "Unpin"), anchor: "center")
      content((7.4, 5.3), text(size: 8pt, weight: "bold", "&mut InSt"), anchor: "center")
    })
  ]

]



#slide[
  === Making `Double` `Unpin`

  *Problem:* Can't delegate to inner stream without Pin projection

  *Solution:* Move stream to heap with `Box`

  ```rust
  struct Double<InSt> { stream: Box<InSt> }
  ```


  #align(center)[
    #canvas(length: 1cm, {
      import draw: *

      // Stack representation
      rect((0.5, 2.5), (3.5, 4.5), fill: rgb("ffeeee"), stroke: red + 2pt)
      content((2, 3.8), text(size: 8pt, weight: "bold", "Stack"), anchor: "center")
      content((2, 3.2), text(size: 7pt, "❌ Can move"), anchor: "center")

      // Arrow to heap
      line((3.8, 3.5), (5.7, 3.5), mark: (end: ">"), stroke: blue + 2pt)
      content((4.75, 4.2), text(size: 8pt, weight: "bold", "Box"), anchor: "center")

      // Heap representation
      rect((6, 2.5), (9, 4.5), fill: rgb("e6ffe6"), stroke: green + 2pt)
      content((7.5, 3.8), text(size: 8pt, weight: "bold", "Heap"), anchor: "center")
      content((7.5, 3.2), text(size: 7pt, "✅ Stable address"), anchor: "center")
    })
  ]

  #v(0.5em)

  *Result:* `Box<InSt>` is always `Unpin` → `Double<InSt>` becomes `Unpin` ✅
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
  === Share your operators with the world

  Rust's trait system makes custom operators easily shareable:

  ```rust
  // In your new crate `double-stream`
  trait DoubleStream: Stream {
      fn double(self) -> Double<Self>
      where Self: Sized + Stream<Item = i32>,
      { Double::new(self) }
  }
  // Blanket impl for all integer streams
  impl<S> DoubleStream for S where S: Stream<Item = i32> {}
  ```

  *Publish once, use everywhere:* One crate enables the operator for all users
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

  *Rust's superpower:* Extension traits make any stream instantly gain your methods
]

#slide[

  == Real-life operator: `clone-stream`
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

  *Solution*: #link("https://crates.io/crates/clone-stream")[`clone-stream`] makes any stream cloneable:
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
  === Usage example

  Both clones process the same data independently:

  #text(size: 10pt)[
    ```rust
    // Functional logging pipeline
    let log_task = logger
        .filter_map(|line| ready(line.ok()))
        .for_each(|line| ready(println!("Log: {}", line)));

    // Functional processing pipeline
    let parse_task = parser
        .filter_map(|line| ready(line.ok()))
        .for_each(|line| process_message(line));

    tokio::join!(log_task, parse_task);
    ```]

]





#slide[
  === Shared queue with RwLock

  Clones consume data *independently* at different speeds and share a queue behind `RwLock` for efficiency:

  #align(center)[
    #canvas(length: 1cm, {
      import draw: *

      let draw-queue-item(i) = {
        let x = i * 1.5
        rect((x, 2), (x + 1, 2.8), fill: rgb("f0f0f0"), stroke: black)
        content((x + 0.5, 2.4), text(size: 8pt, str(i)), anchor: "center")
        content((x + 0.5, 1.6), text(size: 8pt, "'" + ("abcde".at(i)) + "'"), anchor: "center")
      }

      let draw-clone-row(y, consumed-count, ready-index, name) = {
        for i in range(5) {
          let (color, symbol) = if i < consumed-count {
            (green, "✓")
          } else if i == ready-index {
            (blue, "📖")
          } else {
            (gray, "⏳")
          }
          content((i * 1.5 + 0.5, y), text(size: 10pt, fill: color, symbol), anchor: "center")
        }
        content((-0.8, y), text(size: 9pt, weight: "bold", name), anchor: "center")
      }

      // Draw components
      for i in range(5) { draw-queue-item(i) }
      content((-0.8, 2.4), text(size: 9pt, weight: "bold", "Queue"), anchor: "center")
      draw-clone-row(0.8, 1, 1, "Clone A") // consumed 1, ready at 1
      draw-clone-row(0.3, 3, 3, "Clone B") // consumed 3, ready at 3
    })
  ]

  Each clone tracks *where it left off* in the shared data:
  - Clone A will read `'b'` next, Clone B will read `'d'` next
  - Items kept until all clones consume them (or when ringbuffer overflows)
  - *RwLock allows multiple concurrent readers but exclusive writes*
]

#slide[
  === Only waiting clones store wakers


  #align(center)[
    #canvas(length: 1.2cm, {
      import draw: *

      // Configuration
      let clone-radius = 0.5
      let colors = (
        sleeping: rgb("ffcccc"),
        active: rgb("ccffcc"),
        item: rgb("fff3cd"),
        stream: rgb("e6f3ff"),
      )

      let draw-clone(pos, name, state, color) = {
        let (x, y) = pos
        circle((x, y), radius: clone-radius, fill: color, stroke: black + 1.5pt)
        content((x, y + 0.1), text(size: 8pt, weight: "bold", name))
        content((x, y - 0.1), text(size: 6pt, state))
        content((x, y + 1), text(size: 7pt, if state == "Sleeping" { "💤 Waiting" } else { "⚡ Ready" }))
      }

      let draw-item(pos, value) = {
        let (x, y) = pos
        rect((x - 0.4, y - 0.3), (x + 0.4, y + 0.3), fill: colors.item, stroke: blue + 2pt)
        content((x, y), text(size: 10pt, weight: "bold", value))
      }

      let draw-arrow(from, to, label, color) = {
        line(from, to, mark: (end: ">"), stroke: color + 2pt)
        let mid = ((from.at(0) + to.at(0)) / 2, (from.at(1) + to.at(1)) / 2 - 0.3)
        content(mid, text(size: 9pt, label))
      }

      // Base stream
      rect((1, 0), (7, 0.8), fill: colors.stream, stroke: gray)
      content((4, 0.4), text(size: 8pt, "Base Stream"))

      // Clones
      draw-clone((2, 3), "Alice", "Sleeping", colors.sleeping)
      draw-clone((6, 3), "Bob", "Active", colors.active)

      // Item
      draw-item((4, 1.5), "'x'")

      // Arrows with labels
      draw-arrow((4.3, 2.0), (5.4, 2.6), "direct", green)
      draw-arrow((3.7, 2.0), (2.6, 2.6), "wake + copy", blue)
    })
  ]

  Have to store these wakers in a state machine for each waiting clone.

]

#slide[
  === Each clone needs a mini state machine

  *Beware*: First write unit tests, then create states.

  #align(center)[
    #canvas(length: 1cm, {
      import draw: *

      let draw-state(pos, name, color, has-waker: false) = {
        let (x, y) = pos
        let stroke-color = if has-waker { red + 2pt } else { black + 1pt }
        let height = if has-waker { 1.2 } else { 1.0 }
        rect((x - 1.2, y - height / 2), (x + 1.2, y + height / 2), fill: color, stroke: stroke-color, radius: 0.3)
        content((x, y + 0.2), align(center, text(size: 6pt, weight: "bold", name)))
        if has-waker {
          content((x, y - 0.3), align(center, text(size: 6pt, "💤 waker")))
        }
      }

      let draw-arrow(from, to, label, curve: 0) = {
        let (x1, y1) = from
        let (x2, y2) = to
        if curve == 0 {
          line((x1, y1), (x2, y2), mark: (end: ">"))
          let mid = ((x1 + x2) / 2, (y1 + y2) / 2 + 0.3)
          content(mid, text(size: 6pt, label), fill: white, stroke: white + 1pt)
        } else {
          arc((x1, y1), start: 30deg, stop: 150deg, radius: 1.5, mark: (end: ">"))
          content((x1, y1 + 1.2), text(size: 6pt, label))
        }
      }

      // Actual states from clone-stream source
      draw-state((1, 4), "Never\nPolled", rgb("f0f0f0"))
      draw-state((4, 4), "QueueEmpty\nBaseReady", rgb("ffffcc"))
      draw-state((7, 4), "UnseenQueued\nReady", rgb("ccffcc"))
      draw-state((1, 2), "QueueEmpty\nBasePending", rgb("ffcccc"), has-waker: true)
      draw-state((4, 2), "NoUnseen\nBasePending", rgb("ffcccc"), has-waker: true)
      draw-state((7, 2), "NoUnseen\nBaseReady", rgb("ffffcc"))

      // Key transitions from source code (simplified)
      // From NeverPolled
      draw-arrow((1.7, 4), (3.3, 4), "base Ready")
      draw-arrow((1, 3.3), (1, 2.7), "base Pending")

      // From QueueEmptyBaseReady
      draw-arrow((4, 3.3), (4, 2.7), "base Pending")

      // From UnseenQueuedReady (two different paths)
      draw-arrow((6.3, 3.8), (6.3, 2.3), "→ Pending") // Straight down
      draw-arrow((7.7, 3.8), (7.7, 2.3), "→ Ready") // Offset to the right

      // Note: Complex conditional logic determines exact transitions
    })
  ]

  #text(size: 8pt)[
    #grid(
      columns: (1fr, 1fr),
      gutter: 2em,
      [
        - 🟨 Yellow: Clone has data ready (hot path)
        - 🟩 Green: Clone has queued items to consume (hot path)
      ],
      [
        - 🟥 Red: Clone is waiting, stored waker (cold path)
        - ⬜ Gray: Initial state
      ],
    )]


]


#slide[
  === Watch out for slow readers!

  A blocked clone can cause memory leaks:

  #text(size: 10pt)[
    ```rust
    let mut fast = stream.fork();
    let mut slow = stream.clone();

    // Slow reader blocks on I/O or computation
    tokio::spawn(async move {
        while let Some(item) = slow.next().await {
            blocking_database_call(item); // Blocks!
        }
    });
    ```]

  The slow reader may cause the queue to overflow quickly:

  (Slow readers will miss elements.)
]




#slide[
  == Conclusion
]




#slide[
  === Not discussed

  Many more advanced topics await:

  - *Boolean ops*: `any`, `all`
  - *Async item processing*: `then`
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

  📖 Deep dive: #link("https://willemvanhulle.tech/blog/streams/func-async/")[willemvanhulle.tech/blog/streams/func-async]
]

#slide[
  === Last recommendation

  *⚠️ Streams don't replace good software engineering!*

  #grid(
    columns: (1fr, 1fr),
    gutter: 2em,
    [
      *Don't overuse streams:*
      - Avoid forcing everything into streams
      - More operators ≠ better code
      - Use for *genuine async data flow*
      - Get team buy-in before adoption
    ],
    [
      *Follow best practices:*
      - Keep functions modular & readable
      - Use descriptive names & generics
      - Split long function bodies
      - Test components individually
    ],
  )

  #v(0.5em)

  #align(center)[
    _Streams are powerful, but code principles still apply!_
  ]
]


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
