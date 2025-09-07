#set page(
  width: 16cm,
  height: 9cm,
  margin: 1.5cm,
)
#set text(size: 12pt)
#set par(justify: false)


// #show raw.where(block: true): block.with(breakable: false)

#let slide(content) = {
  pagebreak(weak: true)
  content
  place(bottom + right, dx: -1em, dy: -1em)[
    #context text(size: 10pt, fill: gray)[#counter(page).display()]
  ]
}

#slide[
  #align(center)[
    = Make Your Own Stream Operators

    _Building Custom Stream Combinators in Rust_

    #v(2em)

    Willem Vanhulle \
    EuroRust 2025

    #v(1em)

    _30 minutes + 10 minutes Q&A_
  ]
]

#slide[
  = What we'll cover

  - Stream fundamentals in Rust
  - Working with existing stream operators
  - Building custom stream combinators
  - Real-world example: `clone-stream`
  - Advanced patterns and best practices

  #v(2em)

  *Goal:* By the end, you'll be comfortable creating your own stream operators!
]

#slide[
  = What are `Stream`s?

  Streams are _asynchronous iterators_ that produce values over time:

  ```rust
  trait Stream {
      type Item;

      fn poll_next(
          self: Pin<&mut Self>,
          cx: &mut Context<'_>
      ) -> Poll<Option<Self::Item>>;
  }
  ```

  Think: async version of `Iterator`
]

#slide[
  = When to use `Stream`s?

  #grid(
    columns: (1fr, 1fr),
    gutter: 2em,
    [
      *Perfect for:*
      - Multiple values arriving over time
      - Async data sources (network, files, timers)
      - Processing pipelines with transformations
      - Event handling (user input, sensors)
    ],
    [
      *Key benefits:*
      - Lazy evaluation - only process what you need
      - Composable - chain operations like `Iterator`
      - Async-friendly - doesn't block other tasks
    ],
  )
]


#slide[
  = Understanding async: `Poll`

  Before diving into `Stream`s, you need to understand `Poll`:

  ```rust
  enum Poll<T> {
      Ready(T),
      Pending,
  }
  ```


  - *Ready* - "Here's your data!"
  - *Pending* - "Check back later, I'm still working on it"

  #v(1em)

  This is how all async operations communicate their state
]


#slide[
  = Simplified `Stream`

  A stream is "a future that may be polled more than once":

  #show raw: set text(size: 8pt)

  ```rust
  trait Stream {
      type Item;

      fn poll_next(
          &mut self
      ) -> Poll<Option<Self::Item>>;
  }
  ```

  - `Poll::Ready(Some(item))` → yielded a value
  - `Poll::Ready(None)` → stream is exhausted
  - `Poll::Pending` → not ready, try again later

]



#slide[
  // = Iterator vs Stream Lifetimes


  #show raw: set text(size: 6pt)

  #text(size: 6pt)[
    #grid(
      columns: (1fr, 0.5fr, 1fr),
      gutter: 1.5em,

      [
        *Synchronous Iterator:*
        #table(
          columns: 3,
          [*T*], [*Action*], [*Result*],
          [1], [`(1..=10)`], [],
          [2], [`next()`], [],
          [3], [], [`Some(1)`],
          [4], [`next()`], [],
          [5], [*...*], [],
          [6], [`next()`], [],
          [7], [], [`None`],
          [8], [`next()`], [],
          [9], [], [`Some(2)`],
        )
      ],
      [#align(horizon)[#text(size: 24pt)[→]]],

      [
        *Asynchronous Stream:*
        #table(
          columns: 4,
          [*T*], [*Action*], [*Await*], [*Result*],
          [1], [`St::new()`], [], [],
          [2], [`next()`], [], [],
          [3], [], [`await`], [],
          [4], [], [], [`Some(1)`],
          [5], [`next()`], [], [],
          [6], [*...*], [], [],
          [7], [], [`await`], [],
          [8], [], [], [`Some(2)`],
          [9], [`next()`], [], [],
          [10], [], [], [`None`],
        )
      ],
    )

  ]]

#slide[
  == Stream Conceptual Definition

  A rough conceptual definition of a stream:

  #align(center)[
    #text(size: 14pt)[
      _"A function that returns multiple values at unpredictable times"_
    ]
  ]


  This captures the essential nature of streams:
  - *Multiple values* - not just one like a Future
  - *Unpredictable times* - values arrive asynchronously
  - *Function-like* - composable and transformable
]




#slide[

  Process items one by one:

  ```rust
  async fn consume_stream<S>(mut stream: S)
  where S: Stream<Item = i32>
  {
      while let Some(item) = stream.next().await {
          println!("Processing: {}", item);
      }
  }
  ```

  An *imperative* way to handle streams.
]

#slide[



  ```rust
  use futures::stream::{self, StreamExt};
  ```

  Collect all items at once:

  ```rust
  let numbers = stream::iter(vec![1, 2, 3, 4, 5]);
  let result: Vec<i32> = numbers.collect().await;
  // result: [1, 2, 3, 4, 5]

  let sum = stream::iter(1..=10).fold(0, |acc, x| async move { acc + x }).await;
  // sum: 55
  ```
]

#slide[

  ```rust
  use futures::stream::{self, StreamExt};
  ```

  Familiar operators:

  ```rust
  let result: Vec<_> = stream::iter(1..=10)
      .filter(|&x| async move { x % 2 == 0 })  // Keep evens
      .map(|x| x * 2)                          // Double them
      .take(3)                                 // Take first 3
      .collect()
      .await;

  // result: [4, 8, 12]
  ```
]

#slide[
  = Tokio broadcast `Stream`

  Needs helper library `tokio_stream`.


  ```rust
    use tokio::sync::broadcast;
    use tokio_stream::wrappers::BroadcastStream;
    use futures::stream::StreamExt;
  ```
  Consume receiving end with a stream wrapper:

  ```rs
  let (tx, rx) = broadcast::channel(16);
  let mut stream = BroadcastStream::new(rx);
  ```

]


#slide[

  == Producer

  Simulating a real producer:

  ```rs
  tokio::spawn(async move {
      for i in 0..5 {
          tx.send(format!("Message {}", i)).unwrap();
          tokio::time::sleep(Duration::from_millis(100)).await;
      }
  });
  ```

  Could be on a different task or machine.
]

#slide[

  == Consumer

  Process messages as they arrive

  ```rust

  stream
      .map(Result::ok)
      .filter_map(future::ready)
      .for_each(|msg| async move {
          println!("Processing: {}", msg);
      })
      .await;
  ```

  Use `Result::ok` and `futures::ready` to ignore broadcast errors.
]

#slide[
  = Building custom `Stream` operators

  Let's create our own `double` combinator:

  ```rust
  struct Double<S> {
      stream: S,
  }

  impl<S> Double<S> {
      fn new(stream: S) -> Self {
          Self { stream }
      }
  }
  ```
]

#slide[

  #show raw: set text(size: 8pt)

  ```rust
  impl<S> Stream for Double<S>
  where
      S: Stream<Item = i32>,
  {
      type Item = i32;

      fn poll_next(
          self: Pin<&mut Self>,
          cx: &mut Context<'_>
      ) -> Poll<Option<Self::Item>> {
         ...
      }
  }
  ```

  `Pin` prevents the struct from moving in memory while async
]

#slide[

  #show raw: set text(size: 10pt)
  ```rust
  fn poll_next(
      self: Pin<&mut Self>,
      cx: &mut Context<'_>
  ) -> Poll<Option<Self::Item>> {
      let this = self.get_mut(); // Violates Pin contract
      match this.stream.poll_next(cx) { // Stream not pinned
          Poll::Ready(x) => Poll::Ready(...),
          Poll::Pending => Poll::Pending,
      }
  }
  ```
]

#slide[

  We need to convert `Pin<&mut Self>` to `&mut Self` with `get_mut()`



  ```rs
  let this = self.get_mut();
  ```

  Boxed values (on the heap) are safe to _`Unpin`_.

  ```rs
  impl<S> Double<S> {
      fn new(stream: S) -> Self {
          Self { stream: Box::new(stream) }
      }
  }
  ```

  Now the  `Double` struct is `Unpin` = safe to move / drop pin:
]



#slide[
  Define a *blanket implementation* for `Double`:

  ```rust
    trait StreamExt: Stream {
        fn double(self) -> Double<Self>
        where
            Self: Sized + Stream<Item = i32>,
        { Double::new(self) }
    }

    impl<S: Stream> StreamExt for S {}
  ```
  Now you can easily double the values in a stream:

  ```rust
  let doubled = stream::iter(1..=5).double();
  ```
]

#slide[
  = Real problem: `Stream`s aren't `Clone`

  You can't copy a stream like other Rust values:

  ```rust
  let numbers = stream::iter(vec![1, 2, 3, 4, 5]);
  let copy = numbers.clone(); // Error!
  ```

  #v(1em)

  But sometimes you need multiple consumers:
  - Process data in parallel
  - Split stream for different tasks
  - Cache results for replay
]

#slide[

  My `clone-stream` crate solves this:

  ```rust
  use clone_stream::ForkStream;

  let numbers = stream::iter(vec![1, 2, 3, 4, 5]).fork();
  let copy = numbers.clone(); // Works!
  ```


  Now you can:
  ```rust
  let stream1 = numbers.clone();
  let stream2 = numbers.clone();
  ```
  Both get the same items: [1, 2, 3, 4, 5]
]

#slide[
  = How clones work

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
  = `Waker` coordination

  Clone-stream creates a "meta-waker" that wakes all waiting clones:

  ```rust
  fn waker(&self, extra_waker: &Waker) -> Waker {
      let wakers = self.clones
          .iter()
          .filter_map(|(_id, state)| state.waker())
          .collect::<Vec<_>>();

      MultiWaker::new(wakers)
  }
  ```

  Only waiting clones contribute their wakers
]

#slide[
  = How waking works

  The coordination process:

  #v(1em)

  1. *Clone waits* - Clone calls `.next().await`, returns `Pending`
  2. *Waker stored* - Clone's waker gets stored in its state
  3. *Base stream polled* - Meta-waker given to base stream
  4. *New data arrives* - Base stream wakes the meta-waker
  5. *All wake up* - Meta-waker wakes all waiting clones

  #v(1em)

  Efficient: no unnecessary wake-ups for clones that aren't waiting
]

#slide[

  ```rust
  let original = stream::iter(vec![1, 2, 3, 4, 5]).fork();

  let evens = original.clone()
      .filter(|&x| async move { x % 2 == 0 });

  let doubled = original.clone()
      .map(|x| x * 2);

  // Both process the same source data independently
  let (even_results, doubled_results) = tokio::join!(
      evens.collect::<Vec<_>>(),
      doubled.collect::<Vec<_>>()
  );
  ```
]




#slide[
  = Clone-stream usage

  Both clones get all items:
  #show raw: set text(size: 8pt)

  ```rust
  use clone_stream::ForkStream;

  let original = stream::iter(vec!['a', 'b', 'c']).fork();
  let mut adam = original.clone();
  let mut bob = original.clone();

  // Both receive 'a'
  assert_eq!(adam.next().await, Some('a'));
  assert_eq!(bob.next().await, Some('a'));
  ```

  Each clone maintains its own position
]



#slide[
  = Smart buffering: Setup

  Bob polls first, but no data is available yet:
  #show raw: set text(size: 7pt)

  ```rust
  let (sender, rx) = tokio::sync::mpsc::unbounded_channel();
  let stream = tokio_stream::wrappers::UnboundedReceiverStream::new(rx);

  let mut adam = stream.fork();
  let mut bob = adam.clone();

  // Bob starts waiting for data (no data sent yet)
  let bob_task = tokio::spawn(async move {
      bob.next().await // Returns Pending, Bob gets suspended
  });
  ```

  Bob is now in a "waiting" state with his waker stored
]

#slide[
  = Smart buffering: Data arrives

  Adam polls and data arrives - this wakes Bob too:
  #show raw: set text(size: 7pt)

  ```rust
  // Meanwhile, data gets sent
  sender.send('a').unwrap();

  // Adam polls and gets the data
  let adam_task = tokio::spawn(async move {
      adam.next().await // Gets Some('a') immediately
  });

  // Bob's waker gets triggered automatically!
  let (adam_result, bob_result) = tokio::join!(adam_task, bob_task);

  assert_eq!(adam_result.unwrap(), Some('a'));
  assert_eq!(bob_result.unwrap(), Some('a')); // Same data!
  ```
]

#slide[
  = How it works

  The coordination:

  1. Bob waits → waker stored
  2. Adam polls → data arrives
  3. Meta-waker → wakes both
  4. Both get same data

  #v(1em)

  Buffering only happens when clones are actively waiting
]

#slide[
  = Late cloning

  You can clone even after receiving some items:
  #show raw: set text(size: 7pt)

  ```rust
  let (sender, rx) = tokio::sync::mpsc::unbounded_channel();
  let stream = tokio_stream::wrappers::UnboundedReceiverStream::new(rx);

  let mut adam = stream.fork();

  sender.send('a').unwrap();
  assert_eq!(adam.next().await, Some('a'));

  // Clone after adam already read 'a'
  let mut bob = adam.clone();

  sender.send('b').unwrap();
  assert_eq!(bob.next().await, Some('b')); // Bob gets the next item
  ```
]

#slide[
  = Memory management warning

  ⚠️ Suspended clones can cause memory buildup:
  #show raw: set text(size: 7pt)

  ```rust
  let original = some_big_stream().fork();

  let mut fast = original.clone();
  let mut very_slow = original.clone();

  // very_slow gets suspended waiting for data
  let slow_task = tokio::spawn(async move {
      very_slow.next().await // Suspended!
  });
  ```

  Now very_slow is in a suspended state
]

#slide[
  = Memory buildup problem

  Fast reader can't clean up items. `fast` reader processes 1000s of items:

  ```rust
  for _ in 0..1000 {
      fast.next().await;
  }
  ```

  All 1000 items still buffered!  `very_slow` hasn't read them yet



  *Solution:* Drop unused clones
  ```rust
  drop(slow_task); // Frees buffered memory
  ```
]

#slide[
  = Summary

  #v(1em)

  *Streams are async iterators* that return multiple values at unpredictable times

  *Start with existing combinators* - `map`, `filter`, `collect`, `fold`

  *Build custom operators* using the wrapper pattern + `Stream` trait

  *Clone-stream enables parallel processing* - but watch memory with slow readers



  #align(center)[
    _You can now build your own stream operators!_
  ]
]

#slide[
  #align(center)[
    = Questions?


    📖 Blog series: `wvhulle.github.io/blog/streams/`

    📦 Clone-stream: `github.com/wvhulle/clone-stream`

    📚 Futures docs: `docs.rs/futures`

    #v(2em)

    Willem Vanhulle • `@wvhulle` • EuroRust 2025
  ]
]
