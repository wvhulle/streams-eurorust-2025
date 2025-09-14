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

  #v(1em)

  *What I observed:*
  - Every developer had their own approach to handle incoming streams
  - Inconsistent error handling across the codebase
  - Hard to reason about data flow and state
  - Debugging became a nightmare

  #v(1em)

  *The realization:* Most developers only encounter streams in distributed systems,
  where the gotchas become apparent too late
]

#slide[
  === About me

  *Professionally:* Rust developer

  *My stream processing journey:*
  - Started with reactive programming in TypeScript (frontend)
  - Moved to vehicle telemetry systems in Rust
  - Lots of trial and error with the unforgiving Rust compiler
  - Struggled with `'static` lifetimes and memory management

  *Today:* Want to share the patterns I discovered the hard way

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
  === Why streams are challenging

  Manual stream processing becomes messy quickly:

  #text(size: 8pt)[
    ```rust
    let mut filtered_messages = Vec::new();
    let mut count = 0;

    while let Some(connection) = tcp_stream.next().await {
        match connection {
            Ok(stream) => {
                if should_process(&stream) {
                    // ... nested processing logic
                }
            }
            Err(e) => log_connection_error(e),
        }
    }
    ```]

]

#slide[
  === The nested complexity continues...

  Each processing step adds more complexity:

  #text(size: 9pt)[
    ```rust
    // Inside the should_process block:
    match process_stream(stream).await {
        Ok(msg) if msg.len() > 10 => {
            filtered_messages.push(msg);
            count += 1;
            if count >= 5 { break; }
        }
        Ok(_) => continue,  // Skip short messages
        Err(e) => log_error(e),
    }
    ```]

  Hard to read, maintain, test, and reason about!
]

#slide[
  === Functional approach preview

  Same logic, much cleaner with stream operators:

  #text(size: 10pt)[
    ```rust
    let filtered_messages: Vec<String> = tcp_stream
        .filter_map(|connection| ready(connection.ok()))
        .filter_map(|stream| async {
            process_stream(stream).await.ok()
        })
        .filter(|msg| ready(msg.len() > 10))
        .take(5)
        .collect()
        .await;
    ```]

  Declarative, composable, and testable!
]

#slide[

  #align(center)[*Goal:* Build your own stream operators with confidence!]

  #v(1em)

  #outline(
    title: none,
    indent: auto,
    depth: 2,
  )

]

#slide[
  == Foundations
]

#slide[
  === Iterator vs Stream: key difference

  #align(center)[
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
  === Stream trait definition

  Streams are polled for the next item:

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

  - `Context` provides access to the current task's waker
  - Returns `Poll<Option<Item>>` - wrapped in polling state
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
  === The `None` confusion

  *Critical distinction:* `Ready(None)` has different meanings!

  #grid(
    columns: (1fr, 1fr),
    gutter: 2em,
    [
      *Regular `Stream`*
      - `None` may be temporary
      - Could yield `Some(item)` later
      - Example: empty channel buffer

      #text(size: 8pt)[
        ```rust
        // Channel stream
        if buffer.is_empty() {
            return Poll::Ready(None);
        }
        // But more data might arrive!
        ```
      ]
    ],
    [
      *`FusedStream`*
      - `None` means permanently done
      - Will never yield `Some(item)` again
      - Similar to `FusedFuture`

      #text(size: 7pt)[
        ```rust
        // Iterator-based stream
        match iter.next() {
            Some(item) => Poll::Ready(Some(item)),
            None => Poll::Ready(None), // Forever
        }
        ```
      ]
    ],
  )

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
  === Imperative approach problems

  Manual processing is verbose:

  #text(size: 9pt)[
    ```rust
    let mut evens = Vec::new();
    while let Some(item) = stream.next().await {
        if item % 2 == 0 {
            evens.push(item * 2);
            if evens.len() >= 3 { break; }
        }
    }
    ```]

  Hard to read, maintain, and reuse
]

#slide[
  === StreamExt operators are better

  Same logic, much cleaner:

  #text(size: 10pt)[
    ```rust
    let evens: Vec<i32> = stream
        .filter(|&x| ready(x % 2 == 0))
        .map(|x| x * 2)
        .take(3)
        .collect()
        .await;
    ```]


  *Note*: `ready(...)` wraps sync values into a future - some stream operators (like `filter`) expect `Future`s. See #link("https://docs.rs/futures/latest/futures/future/fn.ready.html")[`futures::future::ready`].
]

#slide[
  === Real example: broadcast channels

  Tokio channels need `tokio_stream` wrappers to become streams:

  ```rust
  use tokio::sync::broadcast;
  let (tx, rx) = broadcast::channel(16);
  ```

  Let's turn the receiver into a stream.
]

#slide[
  === Handling broadcast errors functionally

  Broadcast streams return `Result<T, BroadcastStreamRecvError>`:

  ```rust
  use tokio_stream::wrappers::BroadcastStream;
  use futures::future::ready;
  BroadcastStream::new(rx)
      .filter_map(|result| ready(result.ok()))
      .collect::<Vec<_>>()
      .await;
  ```

  - `Result::ok()` converts `Result<T, E>` → `Option<T>`
  - `filter_map` drops `None` values (errors become `None`)

]

#slide[
  === Before building your own operators

  *Check existing solutions first:*

  #grid(
    columns: (1fr, 1fr),
    gutter: 2em,
    [
      *Official operators*
      - #link("https://docs.rs/futures/latest/futures/stream/trait.StreamExt.html")[`futures::StreamExt`]
      - Production ready & comprehensive
    ],
    [
      *Community extensions*
      - #link("https://crates.io/crates/futures-rx")[`futures-rx`]
      - Reactive operators & specialized use cases
    ],
  )

  #v(1.5em)

  *Build custom only when:*
  - No existing operator fits
  - Domain-specific functionality needed
  - Performance requires specialization

]

#slide[
  == Basic stream operator

]


#slide[


  === Step 1: Create a wrapper struct around an existing stream

  The wrapper pattern - most custom operators follow this structure:

  ```rust
  struct Double<InSt> {
      stream: InSt,  // Wrap the input stream
  }
  impl<InSt> Double<InSt> {
      fn new(stream: InSt) -> Self {
          Self { stream }
      }
  }
  ```
  The constructor will be necessary later on.


]

#slide[
  === Step 2: Implement `Stream` for your wrapper

  #text(size: 9pt)[
    ```rust
    impl<InSt> Stream for Double<InSt>
    where InSt: Stream<Item = i32>
    {
        type Item = i32;

        fn poll_next(
            self: Pin<&mut Self>,
            cx: &mut Context<'_>
        ) -> Poll<Option<Self::Item>> {
            // Implementation goes here...
        }
    }
    ```]
]

#slide[
  === Why Pin exists: self-referential structs

  Future state machines can point to their own data:

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

  Moving this struct would break the internal pointer → undefined behavior
]

#slide[
  === The Pin challenge

  Pin prevents direct field access - but we need the inner stream:

  #text(size: 9pt)[
    ```rust
    impl<InSt: Stream<Item = i32>> Stream for Double<InSt> {
        type Item = i32;

        fn poll_next(self: Pin<&mut Self>, cx: &mut Context<'_>)
            -> Poll<Option<Self::Item>>
        {
            // ❌ self.stream.poll_next(cx)        // Can't move out of Pin
            // ❌ Pin::new(&mut self.stream)       // Can't get &mut from Pin

            // ✓ What we need: Pin<&mut InSt> from Pin<&mut Self>
        }
    }
    ```
  ]
]

#slide[
  === Pin projection concept

  We need to safely convert `Pin<&mut Self>` → `Pin<&mut Field>`:

  #text(size: 10pt)[
    ```rust
    struct Double<InSt> {
        stream: InSt,  // We need Pin access to this field
    }

    // Pin<&mut Double<InSt>> → Pin<&mut InSt>
    ```
  ]

  Three approaches:
  - *Box the field* (simple, heap allocation)
  - *Use `pin-project` crate* (recommended, no unsafe)
  - *Manual unsafe projection* (experts only)
]

#slide[
  === Solution: Pin projection visualization

  We need to "project" the Pin from outer to inner field:

  #align(center)[
    #canvas(length: 1.2cm, {
      import draw: *

      let draw-box(x, y, w, h, color, stroke-color, texts) = {
        rect((x, y), (x + w, y + h), fill: color, stroke: stroke-color + 1.5pt)
        let center-y = y + h / 2
        let start-y = center-y + (texts.len() - 1) * 0.2
        for (i, txt) in texts.enumerate() {
          content((x + w / 2, start-y - i * 0.4), txt, anchor: "center")
        }
      }

      let draw-problem(x, y, message) = {
        content((x, y), text(size: 7pt, fill: red, "❌ " + message), anchor: "center")
      }

      let draw-benefit(x, y, message) = {
        content((x, y), text(size: 7pt, fill: green, "✓ " + message), anchor: "center")
      }

      // Input box
      draw-box(0, 3, 5, 2.5, rgb("ffeeee"), red, (
        text(size: 9pt, weight: "bold", "Pin<&mut Self>"),
        text(size: 8pt, "stream: InSt"),
      ))

      // Projection arrow
      line((5.3, 4.2), (7.2, 4.2), mark: (end: ">"), stroke: blue + 2pt)
      content((6.25, 4.8), text(size: 8pt, weight: "bold", "Pin projection"), anchor: "center")
      content((6.25, 4.5), text(size: 7pt, "safe field access"), anchor: "center")

      // Output box
      draw-box(7.5, 3, 5, 2.5, rgb("eeffee"), green, (
        text(size: 9pt, weight: "bold", "Pin<&mut InSt>"),
        text(size: 7pt, "Can poll inner stream"),
        text(size: 7pt, "Pin safety preserved"),
      ))

      // Problems and benefits
      draw-problem(2.5, 2.4, "Direct access blocked")
      draw-benefit(10, 2.4, "Safe projection enabled")

      // Labels
      content((2.5, 1.8), text(size: 8pt, weight: "bold", "Input"), anchor: "center")
      content((10, 1.8), text(size: 8pt, weight: "bold", "Output"), anchor: "center")
    })
  ]
]

#slide[
  === Solution 1: Boxing (easiest)

  #text(size: 9pt)[
    Make everything `Unpin` by boxing the inner stream:

    ```rust
    struct Double<InSt> {
        stream: Box<InSt>,  // Box<T> is always Unpin
    }
    ```

    *Why it works:* `Box<T>` is always `Unpin`, allowing safe mutable access

    *Trade-off:* Extra heap allocation but simple implementation
  ]
]

#slide[
  === Boxing implementation

  #text(size: 8pt)[
    ```rust
    impl<InSt> Stream for Double<InSt>
    where InSt: Stream<Item = i32>
    {
        fn poll_next(self: Pin<&mut Self>, cx: &mut Context<'_>)
            -> Poll<Option<Self::Item>>
        {
            let this = self.get_mut();
            Pin::new(&mut this.stream).poll_next(cx)
                .map(|opt| opt.map(|x| x * 2))
        }
    }
    ```]
]

#slide[
  === Solution 2: Safe pin projection

  Use `pin_project` crate for safe field access:

  #text(size: 10pt)[
    ```rust
    use pin_project::pin_project;

    #[pin_project]
    struct Double<InSt> {
        #[pin]
        stream: InSt,
    }
    ```
  ]

  The `#[pin]` attribute marks fields that need pin projection
]

#slide[
  === Safe pin projection implementation

  #text(size: 9pt)[
    ```rust
    impl<InSt> Stream for Double<InSt>
    where InSt: Stream<Item = i32>
    {
        fn poll_next(self: Pin<&mut Self>, cx: &mut Context<'_>)
            -> Poll<Option<Self::Item>>
        {
            let this = self.project();  // Generated method
            this.stream.poll_next(cx).map(|opt| opt.map(|x| x * 2))
        }
    }
    ```
  ]

  *Recommended:* Eliminates `unsafe` and prevents pin-safety bugs
]

#slide[
  === Solution 3: Manual unsafe projection

  For advanced users only:

  #text(size: 10pt)[
    ```rust
    fn poll_next(self: Pin<&mut Self>, cx: &mut Context<'_>)
        -> Poll<Option<Self::Item>>
    {
        let stream = unsafe {
            self.map_unchecked_mut(|s| &mut s.stream)
        };
        stream.poll_next(cx).map(|opt| opt.map(|x| x * 2))
    }
    ```
  ]

  *Not recommended:* Error-prone and requires deep pin understanding
]



#slide[
  === Creating your own extension trait

  #text(size: 9pt)[
    Recommended: Name your trait after functionality and put in separate crate:

    ```rust
    // In crate `double-stream`
    trait DoubleStream: Stream {
        fn double(self) -> Double<Self>
        where Self: Sized + Stream<Item = i32>,
        {
          Double::new(self)
        }
    }
    ```

    ```rust
    impl<S> DoubleStream for S where S: Stream<Item = i32> {}
    ```

    Separate crates make functionality discoverable and reusable
  ]
]

#slide[
  === Using your custom stream operators

  #text(size: 9pt)[
    Import your trait and use your custom operator:

    ```rust
    use double_stream::DoubleStream;  // Import your extension trait

    let doubled = stream::iter(1..=5).double();
    ```

    *Key insight:* You only need to import the trait once to unlock all your custom stream operators

    The blanket implementation makes `.double()` available on any compatible stream
  ]
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

  But you often need multiple consumers:
  - Parse different message types in parallel
  - Log while processing
  - Fan-out to multiple handlers
]

#slide[
  === No `clone` in `futures` crate

  *Solution*: #link("https://crates.io/crates/clone-stream")[`clone-stream`] makes any stream cloneable:

  #text(size: 10pt)[
    ```rust
    use clone_stream::ForkStream;

    let tcp_stream = TcpStream::connect("127.0.0.1:8080").await?;
    let lines = BufReader::new(tcp_stream).lines().fork();

    let logger = lines.clone();
    let parser = lines.clone();
    ```]

]

#slide[
  === Usage example

  Both clones process the same data independently:

  #text(size: 10pt)[
    ```rust
    tokio::spawn(async move {
        while let Some(line) = logger.next().await {
            println!("Log: {}", line?);
        }
    });
    tokio::spawn(async move {
        while let Some(line) = parser.next().await {
            process_message(line?);
        }
    });
    ```]

]

#slide[
  === How clones work

  Each clone tracks which queue items it still needs to see:

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

  - ✓ = consumed, 📖 = next to read, ⏳ = waiting for
  - Clone A will read `'b'` next, Clone B will read `'d'` next
  - Items kept until all clones consume them
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

  Simple operators like `map` just transform items - no state needed!
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

  The slow reader becomes a bottleneck
]

#slide[
  === Memory leak scenario

  Incoming stream produces many items:

  #text(size: 10pt)[
    ```rust
    // Fast reader processes items quickly
    for i in 0..10_000 {
        sender.send(i).unwrap();
        let item = fast.next().await; // Fast!
    }
    ```]

  But slow reader is still blocked on item #1!

  All 10,000 items remain buffered in memory.

  *Solution*: Use a _ringbuffer_ for overflow handling.
]



#slide[
  == Conclusion
]

#slide[
  === Data transformation & filtering combinators

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
    stream::iter(0..10).map(|x| x * 2).filter(|&x| x > 4)
        .enumerate().take(3).skip_while(|&(i, _)| i < 1)
    ```]

]



#slide[
  === Not discussed

  Many more advanced topics await:

  - *Flattening*: `flatten`, `flatten_unordered`, `select_all`
  - *Buffering*: `buffer_unordered`, `buffered`
  - *Peeking*: `peekable`, `skip_while`
  - *Boolean ops*: `any`, `all`
  - *Sinks*: The write-side counterpart to streams
  - *Fanout*: Broadcasting to multiple destinations

  📖 Deep dive: #link("https://willemvanhulle.tech/blog/streams/func-async/")[willemvanhulle.tech/blog/streams/func-async]
]

#slide[
  === Summary

  - *Streams vs iterators*: Handle async data with `Poll<Option<T>>`
  - *Rich combinators*: Transform, filter, aggregate streams functionally
  - *Check existing solutions*: `StreamExt` and `futures-rx` before custom operators
  - *Building operators*: Wrapper struct + `Stream` trait + pin projection
  - *Extension traits*: Make operators discoverable in separate crates
  - *Smart cloning*: `clone-stream` buffers only when clones are waiting

  #align(center)[
    _Build expressive async data pipelines with confidence!_
  ]
]


#slide[


  #align(center)[


    #text(size: 2em)[Thank you!]

    Willem Vanhulle \

    #v(4em)


    Contact me!

    #link("mailto:willemvanhulle@protonmail.com") \
    #link("https://willemvanhulle.tech")[willemvanhulle.tech] \
    #link("https://github.com/wvhulle/streams-eurorust-2025")[github.com/wvhulle/streams-eurorust-2025]
  ]


]
