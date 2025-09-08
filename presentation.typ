// Import template
#import "template.typ": presentation-template, slide

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
  === About me

  *Professionally:* Rust developer

  *Hobbies:*
  - Leading #link("https://sysghent.be")[SysGhent.be] - systems programming community in Ghent, Belgium
  - Giving workshops and talks
  - Formalizing mathematics in Lean

  #v(1em)

  _Find me at_ #link("https://github.com/wvhulle")[`github.com/wvhulle`] _or_ #link("https://willemvanhulle.tech")[`willemvanhulle.tech`]
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
  === Real-world streaming scenarios

  Data that arrives over time needs async handling:

  #text(size: 10pt)[
    ```rust
    // Incoming network messages
    let mut tcp_stream = TcpListener::bind("127.0.0.1:8080")
        .await?
        .incoming();

    while let Some(connection) = tcp_stream.next().await {
        handle_client(connection?).await;
    }
    ```]

  Can't process what hasn't arrived yet
]

#slide[
  === Why streams matter




  #text(size: 9pt)[

    This blocks the entire thread
    ```rust
        let messages: Vec<Message> = fetch_all_messages().await;
        for msg in messages { process(msg); }
    ```
    This processes messages as they arrive
    ```rust
    let message_stream = subscribe_to_messages().await;
    while let Some(msg) = message_stream.next().await {
        process(msg).await;
    }
    ```

  ]

  Streams enable reactive, efficient processing
]




#slide[
  === Iterator vs Stream: key difference

  #align(center)[
    #text(size: 9pt)[
      #grid(
        columns: (1fr, 0.3fr, 1fr),
        gutter: 1em,

        [
          *Iterator (sync)*
          #table(
            columns: 2,
            stroke: 0.5pt,
            [*Call*], [*Returns*],
            [`next()`], [`Some(1)`],
            [`next()`], [`Some(2)`],
            [`next()`], [`Some(3)`],
            [`next()`], [`None`],
          )

          ✓ Always returns immediately
        ],
        [#text(size: 14pt)[vs]],

        [
          *Stream (async)*
          #table(
            columns: 2,
            stroke: 0.5pt,
            [*Call*], [*Returns*],
            [`poll_next()`], [`Pending`],
            [`poll_next()`], [`Ready(Some(1))`],
            [`poll_next()`], [`Pending`],
            [`poll_next()`], [`Ready(Some(2))`],
          )

          ⚠️ May return `Pending`
        ],
      )
    ]]

  Streams handle data that arrives over time
]


#slide[
  === Stream trait definition

  Streams are polled for the next item:

  #text(size: 10pt)[
    ```rust
    trait Stream {
        type Item;

        fn poll_next(
            &mut self,
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
        [`Ready(None)`], [Stream is exhausted, no more items],
        [`Pending`], [Not ready yet, will notify via waker],
      )
    ]]

  When `Pending`: runtime suspends task until waker signals readiness
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
  === Operator benefits

  StreamExt operators offer:

  - *Composability*: Chain operations
  - *Readability*: Clear intent
  - *Performance*: Low-overhead (in-place async stack state)

  #text(size: 9pt)[
    ```rust
    fn double_evens<S>(stream: S) -> impl Stream<Item = i32>
    where S: Stream<Item = i32>
    { stream.filter(|&x| ready(x % 2 == 0)).map(|x| x * 2) }

    let result: Vec<_> = stream::iter(1..=10)
        .pipe(double_evens).take(3).collect().await;
    ```]
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

  *Use `Stream`* - `AsyncIterator` lacks essential features
]


#slide[
  === Tokio broadcast `Stream`

  Needs helper library `tokio_stream`.


  ```rust
  use tokio::sync::broadcast;
  use tokio_stream::wrappers::BroadcastStream;
  use futures::stream::StreamExt;
  ```
  Consume receiving end with a stream wrapper:

  ```rust
  let (tx, rx) = broadcast::channel(16);
  let mut stream = BroadcastStream::new(rx);
  ```

]


#slide[

  === Producer

  Simulating a real producer:

  ```rust
  tokio::spawn(async move {
      for i in 0..5 {
          if tx.send(format!("Message {}", i)).is_err() {
              break; // No active receivers
          }
          tokio::time::sleep(Duration::from_millis(100)).await;
      }
  });
  ```

  `send()` returns `Err` when no receivers are active
]

#slide[

  === Consumer

  Process messages with proper error handling:

  ```rust
  while let Some(result) = stream.next().await {
      match result {
          Ok(msg) => println!("Processing: {}", msg),
          Err(BroadcastStreamRecvError::Lagged(n)) => {
              println!("Lagged by {} messages", n);
          }
      }
  }
  ```

  Handle lagging receivers explicitly for robustness
]

#slide[
  == Building operators in general


  #v(5em)

  #align(right)[
    First try: \
    Official operators: #link("https://docs.rs/futures/latest/futures/stream/trait.StreamExt.html")[`StreamExt`]\
    Extend reactive operators: #link("https://crates.io/crates/futures-rx")[`futures-rx`]
  ]
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
  === Why `Pin` matters for stream operators

  #text(size: 9pt)[
    *The challenge:* Streams can contain self-referential data (async state machines)

    ```rust
    fn poll_next(self: Pin<&mut Self>, cx: &mut Context<'_>)
        -> Poll<Option<Self::Item>>
    {
        // We receive Pin<&mut Double<InSt>>
        // But need Pin<&mut InSt> to poll inner stream
    }
    ```

    *Pin contract:* data inside the `Pin` is partially guaranteed by the compiler *at compile-time* that the content in it must not move in memory at run-time.
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
    where InSt: Stream<Item = i32> + Unpin
    {
        fn poll_next(mut self: Pin<&mut Self>, cx: &mut Context<'_>)
            -> Poll<Option<Self::Item>>
        {
            let stream = &mut self.stream;
            match stream.as_mut().poll_next(cx) {
                Poll::Ready(Some(val)) => Poll::Ready(Some(val * 2)),
                other => other,
            }
        }
    }
    ```]
]

#slide[
  === Solution 2: Safe pin projection

  #text(size: 9pt)[
    Use `pin_project` macro for safe projection without `unsafe`:

    ```rust
    #[pin_project]
    struct Double<InSt> {
        #[pin]
        stream: InSt,  // Mark field as pinned
    }
    ```

    The macro generates safe projection methods automatically
  ]
]

#slide[
  === Solution 3: Manual unsafe projection

  #text(size: 9pt)[
    For advanced users only:

    ```rust
    impl<InSt> Stream for Double<InSt>
    where InSt: Stream<Item = i32>
    {
        fn poll_next(self: Pin<&mut Self>, cx: &mut Context<'_>)
            -> Poll<Option<Self::Item>>
        {
            let stream = unsafe {
                self.map_unchecked_mut(|s| &mut s.stream)
            };
            // Use projected stream...
        }
    }
    ```

    *Requires:* Careful reasoning about pin invariants
  ]
]



#slide[
  === Creating your own extension trait

  #text(size: 9pt)[
    Create your own extension trait with blanket implementation:

    ```rust
    trait StreamExt: Stream {
        fn double(self) -> Double<Self>
        where
            Self: Sized + Stream<Item = i32>,
        {
          Double::new(self)
        }
    }
    ```

    ```rust
    impl<S: Stream> StreamExt for S where S: Stream<Item = i32> {}
    ```

    This implements `StreamExt` for *all* streams that produce `i32` values
  ]
]

#slide[
  === Using your custom stream operators

  #text(size: 9pt)[
    Import your trait and use your custom operator:

    ```rust
    use my_stream_ops::StreamExt;  // Import your extension trait

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

  Each clone has its own reading position in the shared buffer:

  #text(size: 8pt)[
    #align(center)[
      #table(
        columns: 6,
        stroke: 0.5pt,
        align: center,
        [*Buffer*], [`1`], [`2`], [`3`], [`4`], [`5`],
        [*Clone A*], [👆], [], [], [], [],
        [*Clone B*], [], [], [👆], [], [],
      )
    ]
  ]

  - Clone A will read `1` next
  - Clone B will read `3` next
  - Both share the same buffer data
  - Each tracks their own position independently
]

#slide[
  === Fork data structure

  The core `Fork` struct tracks clones and their states:

  #text(size: 9pt)[
    ```rust
    struct Fork<BaseStream> {
        base_stream: Pin<Box<BaseStream>>,
        queue: BTreeMap<usize, Option<BaseStream::Item>>,
        clones: BTreeMap<usize, CloneState>,  // Clone ID → State
        next_clone_index: usize,
        next_queue_index: usize,
    }
    ```]

  Each clone has an ID and tracks its own state.

  You can also use `stream::unfold` for simple stream states
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

        Waker::from(Arc::new(SleepWaker { wakers }))
    }
    ```]

  When data arrives, all waiting clones wake up simultaneously
]


#slide[
  == Stream buffering behavior
]

#slide[
  === Buffering behavior: step 1

  Bob spawns task and gets suspended:

  #text(size: 10pt)[
    ```rust
    let bob_task = tokio::spawn(async move {
        bob.next().await // Pending → suspended
    });


    ```]

  _Some time passes..._
]

#slide[
  === Buffering behavior: step 2

  Adam spawns task from the main thread.

  1. In the task, adam polls the stream.
  2. Stream not ready, Adam gets suspended:

  #text(size: 10pt)[
    ```rust
    let adam_task = tokio::spawn(async move {
        adam.next().await // Pending → suspended
    });

    ```]

  _Some time passes..._
]

#slide[
  === Buffering behavior: step 3

  Sender sends data, both wake up:

  #text(size: 10pt)[
    ```rust
    sender.send('x').unwrap(); // Both wake and get 'x'

    let (adam_result, bob_result) = tokio::join!(adam_task, bob_task);
    assert_eq!(adam_result.unwrap(), Some('x'));
    assert_eq!(bob_result.unwrap(), Some('x'));
    ```]
]

#slide[
  === No buffering when not waiting: step 1

  Bob spawns task but doesn't poll immediately:

  #text(size: 10pt)[
    ```rust
    let bob_task = tokio::spawn(async move {
        tokio::time::sleep(Duration::from_secs(3)).await;
        bob.next().await // Will poll later
    });
    ```]

  Bob is not waiting yet, no waker stored
]

#slide[
  === No buffering when not waiting: step 2

  Adam spawns task and polls immediately:

  #text(size: 10pt)[
    ```rust
    let adam_task = tokio::spawn(async move {
        adam.next().await // Gets Some('x') immediately
    });

    sender.send('x').unwrap(); // Only Adam gets this

    let adam_result = adam_task.await.unwrap();
    assert_eq!(adam_result, Some('x'));
    ```]

  Data goes only to Adam - Bob wasn't waiting
]

#slide[
  === No buffering when not waiting: step 3

  Bob finally polls but data is gone:

  #text(size: 10pt)[
    ```rust
    // Bob's task wakes up and polls
    let bob_result = bob_task.await.unwrap();
    assert_eq!(bob_result, None); // No data available
    ```]

  Data is only buffered for actively waiting clones
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

  - Memory usage = (slowest reader position) × (item count)
  - Can cause OOM with high-throughput streams

  *Temporary solution:* Avoid blocking operations in clone tasks

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

  - Streams handle async data that arrives over time
  - Use StreamExt combinators before building custom ones
  - Custom operators: wrapper struct + `Stream` trait implementation
  - `clone-stream` enables parallel processing (beware slow readers)

  #align(center)[
    _You can now build your own stream operators!_
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
