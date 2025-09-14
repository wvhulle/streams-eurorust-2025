// Import template
#import "template.typ": presentation-template, slide
#import "@preview/cetz:0.3.1": canvas, draw

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
  === Channel receivers

  Try #link("https://docs.rs/postage/latest/postage/")[`postage`] crate for channels with receivers that implement `Stream`

  Using `tokio` ecosystem? Use:

  1. `tokio_stream::wrappers` for `Stream`s
  2. `tokio_util::sync::PollSender` for `Sink`s

  Create a channel as usual:

  ```rust
  let (tx, rx) = tokio::sync::broadcast::channel(16);
  ```
  Let's convert `rx` into a stream.


]



#slide[
  === Filtering broadcast errors functionally

  Use `filter_map` with `future::ready` and `Result::ok`:

  ```rust
  use futures::future::ready;
  BroadcastStream::new(rx)
      .filter_map(|result| ready(result.ok()))
      .collect::<Vec<_>>()
      .await;
  ```

  - `Result::ok()` converts `Result<T, E>` → `Option<T>`
  - `future::ready()` wraps sync values for async context
  - Errors (like lagged messages) are silently dropped
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
  === The Pin challenge

  Pin prevents direct field access - but we need the inner stream:

  #text(size: 10pt)[
    ```rust
    fn poll_next(self: Pin<&mut Self>, cx: &mut Context<'_>)
        -> Poll<Option<Self::Item>>
    {
        // ❌ self.stream.poll_next(cx)        // Can't move out of Pin
        // ❌ Pin::new(&mut self.stream)       // Can't get &mut from Pin
    }
    ```
  ]

  Need "pin projection" to safely access inner `Pin<&mut InSt>`
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
  === Solution: Pin projection

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
        where
            Self: Sized + Stream<Item = i32>,
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
  === Solution: `clone-stream` crate

  #link("https://crates.io/crates/clone-stream")[`clone-stream`] makes any stream cloneable:

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
  === Fork data structure

  The core `Fork` struct tracks clones and their states:

  #text(size: 9pt)[
    ```rust
    struct Fork<BaseStream> {
        base_stream: Pin<Box<BaseStream>>,
        queue: BTreeMap<usize, Option<BaseStream::Item>>,
        clones: BTreeMap<usize, CloneState>,
        available_clone_indices: BTreeSet<usize>,
        // ... other fields omitted for brevity
    }
    ```]

  Clone IDs are now reused efficiently via `available_clone_indices`.
]

#slide[
  === Clone state diagram

  #align(center)[
    #text(size: 8pt)[
      #table(
        columns: 4,
        stroke: 0.5pt,
        align: center,
        [*Clone ID*], [*State*], [*Has Waker*], [*Position*],
        [`0`], [`Waiting`], [✓], [`item_2`],
        [`1`], [`Ready`], [✗], [`item_0`],
        [`2`], [`Waiting`], [✓], [`item_1`],
      )
    ]
  ]

  Only waiting clones store wakers for coordination
]

#slide[
  === Multi-waker coordination

  The fork creates a meta-waker from all waiting clones:

  #text(size: 9pt)[
    ```rust
    pub fn waker(&self, extra_waker: &Waker) -> Waker {
        let wakers = self.clones
            .iter()
            .filter(|(_id, state)| state.should_still_see_base_item())
            .filter_map(|(_id, state)| state.waker().clone())
            .chain(std::iter::once(extra_waker.clone()))
            .collect::<Vec<_>>();

        Waker::from(Arc::new(MultiWaker { wakers }))
    }
    ```]

  When data arrives, all waiting clones wake up simultaneously
]


#slide[
  == Smart buffering behavior

  Items are only buffered when other clones need them
]

#slide[
  === Buffering: Both clones waiting

  When both clones poll and get `Pending`, they enter waiting states:

  #text(size: 9pt)[
    ```rust
    let bob_task = tokio::spawn(async move {
        bob.next().await // Enters QueueEmptyThenBasePending state
    });

    let adam_task = tokio::spawn(async move {
        adam.next().await // Also enters QueueEmptyThenBasePending
    });
    ```]

  Both clones store wakers and register interest in base stream items
]

#slide[
  === Buffering: Item arrives for waiting clones

  Base stream produces item, gets buffered for both waiting clones:

  #text(size: 9pt)[
    ```rust
    // Base stream becomes ready with 'x'
    // Since multiple clones are in pending states,
    // item gets cloned and queued

    let (adam_result, bob_result) = tokio::join!(adam_task, bob_task);
    assert_eq!(adam_result.unwrap(), Some('x'));
    assert_eq!(bob_result.unwrap(), Some('x'));
    ```]

  Both clones receive the same item from their queue positions
]

#slide[
  === No buffering: Clone not actively waiting

  Bob clone exists but hasn't started polling yet:

  #text(size: 9pt)[
    ```rust
    let bob_task = tokio::spawn(async move {
        tokio::time::sleep(Duration::from_secs(3)).await;
        bob.next().await // Still in NeverPolled state
    });

    // Adam polls immediately
    let adam_result = adam.next().await; // Some('x')
    ```]

  Bob's clone is in `NeverPolled` state - not eligible for buffering
]

#slide[
  === Smart buffering decision

  Items only get buffered when `should_still_see_base_item()` returns `true`:

  #text(size: 8pt)[
    ```rust
    // From the actual implementation:
    if fork.clones.iter()
        .any(|(_id, state)| state.should_still_see_base_item()) {
        // Clone and queue the item
        fork.queue.insert(queue_index, item.clone());
    }
    // Otherwise, item goes only to current clone
    ```]

  Only clones in pending states (actively waiting) trigger buffering
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

  All 10,000 items remain buffered in memory
]

#slide[
  === Current limitation

  Buffer grows indefinitely with slow readers:

  - Memory usage grows with items buffered between fastest and slowest reader
  - Can cause OOM with high-throughput streams

  *Workaround:* Avoid blocking operations in clone tasks

  #text(size: 8pt)[
    ```rust
    // Good: non-blocking
    tokio::spawn(async move { slow.next().await });
    // Bad: blocks executor
    tokio::spawn(async move {
        let item = slow.next().await;
        std::thread::sleep(Duration::from_secs(10)); // Blocks!
    });
    ```]
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

      // Pipeline stages
      draw-stage(0, 2, 1.8, "iter(0..10)", "source", "0,1,2,3...", rgb("e6f3ff"))
      draw-stage(2, 2, 1.8, "map(*2)", "0,1,2,3...", "0,2,4,6...", rgb("fff0e6"))
      draw-stage(4, 2, 1.8, "filter(>4)", "0,2,4,6...", "6,8,10...", rgb("f0ffe6"))
      draw-stage(6, 2, 1.8, "enumerate", "6,8,10...", "(0,6),(1,8)...", rgb("ffe6f0"))
      draw-stage(8, 2, 1.8, "take(3)", "(0,6),(1,8)...", "first 3", rgb("f0e6ff"))
      draw-stage(10, 2, 2.2, "skip_while(<1)", "first 3", "(1,8),(2,10)", rgb("e6fff0"))

      // Final result
      content((11, 1), text(size: 8pt, weight: "bold", "Final: [(1,8), (2,10)]"), anchor: "center")
    })
  ]

  #v(0.5em)

  #text(size: 8pt)[
    ```rust
    stream::iter(0..10).map(|x| x * 2).filter(|&x| x > 4)
        .enumerate().take(3).skip_while(|&(i, _)| i < 1)
    ```]

  Chain operations to build complex data pipelines declaratively
]

#slide[
  === Stream aggregation & boolean operations

  Consume entire streams to produce single results:

  #text(size: 9pt)[
    ```rust
    let numbers = stream::iter(vec![2, 4, 6, 8]);

    // Check conditions across all items
    let all_even = numbers.clone().all(|x| async move { x % 2 == 0 }).await;
    let has_large = numbers.clone().any(|x| async move { x > 5 }).await;

    // Process each item with side effects
    numbers.for_each(|x| async move {
        println!("Processing: {}", x);
        // Could save to database, send to API, etc.
    }).await;
    ```]

  Transform entire streams into scalar values or side effects
]

#slide[
  === Stream composition & advanced operations

  Combine and manipulate multiple streams:

  #text(size: 8pt)[
    ```rust
    // Merge multiple streams
    let stream1 = stream::iter(vec![1, 2, 3]);
    let stream2 = stream::iter(vec![4, 5, 6]);
    let merged = stream::select_all(vec![stream1, stream2]);

    // Peek without consuming
    let mut peekable = stream::iter(vec![1, 2, 3]).peekable();
    if let Some(next) = peekable.as_mut().peek().await {
        println!("Next item will be: {}", next);
    }

    // Forward to sink (write side)
    stream.forward(sink).await?;  // Flush entire stream to sink
    ```]

  Build complex stream topologies and data flow patterns
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

  - **Streams vs iterators**: Handle async data with `Poll<Option<T>>`
  - **Rich combinators**: Transform, filter, aggregate streams functionally
  - **Check existing solutions**: `StreamExt` and `futures-rx` before custom operators
  - **Building operators**: Wrapper struct + `Stream` trait + pin projection
  - **Extension traits**: Make operators discoverable in separate crates
  - **Smart cloning**: `clone-stream` buffers only when clones are waiting

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
