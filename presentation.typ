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

  - Mathematician from Ghent, Belgium
  - Founder of #link("https://sysghent.be")[SysGhent.be] - systems programming community in Belgium


  #v(1em)

  _Find me at_ #link("https://github.com/wvhulle")[`github.com/wvhulle`] _or_ #link("https://willemvanhulle.tech")[`willemvanhulle.tech`]
]

#slide[
  === What we'll cover

  #grid(
    columns: (1fr, 1fr),
    gutter: 2em,
    [
      *Part 1: Foundations*
      - What are `Stream`s?
      - Basic consumption patterns
      - Existing combinators

      *Part 2: Building Custom*
      - The wrapper pattern
      - Implementing `Stream` trait
    ],
    [
      *Part 3: Real Example*
      - Clone-stream library walkthrough
      - Memory management gotchas

      *Part 4: Next Steps*
      - Advanced patterns
      - Resources for learning more
    ],
  )

  #align(center)[*Goal:* Build your own stream operators with confidence!]
]

#slide[
  == Part 1: Foundations
]

#slide[
  === What are `Stream`s?

  Think of them as "async `Iterator`s" – values that arrive over time:

  ```rust
  // Iterator: all values available immediately
  let numbers: Vec<i32> = vec![1, 2, 3, 4, 5];
  for n in numbers { /* process sync */ }

  // Stream: values arrive asynchronously
  let stream: impl Stream<Item = i32> = /* ... */;
  while let Some(n) = stream.next().await { /* process async */ };
  ```

  Perfect for network data, user events, sensor readings, etc.
]

#slide[
  === `Stream` vs `AsyncIterator`

  Rust has `AsyncIterator` in std, but it's much less complete than `Stream`:

  #grid(
    columns: (1fr, 1fr),
    gutter: 2em,
    [
      *`Stream` (futures crate)*
      - Mature ecosystem
      - Rich combinator library
      - `StreamExt` with `map`, `filter`, `collect`
      - Production ready
    ],
    [
      *`AsyncIterator` (std::async_iter)*
      - Nightly-only experimental API
      - NO combinators at all
      - Just `poll_next()` and `size_hint()`
      - Waiting for async closures
    ],
  )

  *Recommendation:* Use `Stream` - `AsyncIterator` lacks essential combinators
]

#slide[
  === When to use `Stream`s?

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
      - Lazy evaluation – only process what you need
      - Composable – chain operations like `Iterator`
      - Async-friendly – doesn't block other tasks
    ],
  )
]


#slide[
  === Understanding async: `Poll`

  Before diving into `Stream`s, you need to understand `Poll`:

  ```rust
  enum Poll<T> {
      Ready(T),
      Pending,
  }
  ```


  - *Ready* – "Here's your data!"
  - *Pending* – "Check back later, I'm still working on it"

  This is how all async operations communicate their state
]


#slide[
  === Simplified `Stream`

  A stream is "a future that may be polled more than once":

  #text(size: 8pt)[
    ```rust
    trait Stream {
        type Item;

        fn poll_next(
            &mut self
        ) -> Poll<Option<Self::Item>>;
    }
    ```]

  - `Poll::Ready(Some(item))` → yielded a value
  - `Poll::Ready(None)` → stream is exhausted
  - `Poll::Pending` → not ready, try again later

]



#slide[
  #align(horizon + center)[
    #text(size: 8pt)[
      #grid(
        columns: (1.5fr, 0.4fr, 2fr),

        [
          *Synchronous Iterator:*
          #table(
            columns: 2,
            [*Action*], [*Result*],
            [`iter(1..=3)`], [],
            [`next()`], [`Some(1)`],
            [`next()`], [`Some(2)`],
            [`next()`], [`Some(3)`],
            [`next()`], [`None`],
          )
          Values available immediately
        ],
        [#text(size: 16pt)[→]],

        [
          *Asynchronous Stream:*
          #table(
            columns: 2,
            [*Action*], [*Result*],
            [`stream::new()`], [],
            [`poll_next()`], [`Pending`],
            [`poll_next()`], [`Ready(Some(1))`],
            [`poll_next()`], [`Pending`],
            [`poll_next()`], [`Ready(Some(2))`],
            [`poll_next()`], [`Ready(None)`],
          )
          May return `Pending` - not ready yet
        ],
      )

    ]]]

#slide[
  === Key difference: Timing

  From the comparison we just saw:


  #grid(
    columns: (1fr, 1fr),
    gutter: 2em,
    [
      *`Iterator`*
      - Synchronous – values ready immediately
      - `next()` returns instantly
      - Predictable timing
    ],
    [
      *`Stream`*
      - Asynchronous – values arrive over time
      - `next().await` might suspend
      - Unpredictable timing – that's the key!
    ],
  )


  This timing unpredictability is what makes `Stream`s perfect for real-world async data
]




#slide[

  === Processing

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

  === Collection

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

  === Reactivity

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
          tx.send(format!("Message {}", i)).unwrap();
          tokio::time::sleep(Duration::from_millis(100)).await;
      }
  });
  ```

  Could be on a different task or machine.
]

#slide[

  === Consumer

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
  == Part 2: Building custom operators
]


#slide[


  === Step 1: Create a wrapper struct around an existing stream

  The wrapper pattern - most custom operators follow this structure:

  ```rust
  struct Double<S> {
      stream: S,  // Wrap the inner stream
  }

  impl<S> Double<S> {
      fn new(stream: S) -> Self {
          Self { stream }
      }
  }
  ```



]

#slide[
  === Step 2: Implement `Stream` for your wrapper

  #text(size: 9pt)[
    ```rust
    impl<S> Stream for Double<S>
    where S: Stream<Item = i32>
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
  === The `Pin` challenge

  This naive approach doesn't work:

  ```rust
  fn poll_next(self: Pin<&mut Self>, cx: &mut Context<'_>)
      -> Poll<Option<Self::Item>>
  {
      let this = self.get_mut(); // Violates Pin contract
      // this.stream is not pinned but needs to be!
  }
  ```

  *Why it fails:* `get_mut()` requires `Self: Unpin`, but our wrapper might not be `Unpin` if the inner stream isn't.
]

#slide[
  === Pin projection explained

  *The problem:* We have `Pin<&mut Double>` but need `Pin<&mut InnerStream>`

  #align(center)[
    #text(size: 10pt)[
      #grid(
        columns: (1fr, 1fr),
        gutter: 2em,
        [
          *Memory Layout:*
          #v(0.5em)
          #rect(width: 4em, height: 3em, stroke: 1pt)[
            #align(top + left)[#text(size: 8pt)[Double]]
            #v(0.3em)
            #rect(width: 3em, height: 1.5em, stroke: 1pt, fill: gray.lighten(80%))[
              #text(size: 8pt)[stream]
            ]
          ]
        ],
        [
          *Pin Projection:*
          #v(0.5em)
          `Pin<&mut Double>`
          #v(0.3em)
          ↓
          #v(0.3em)
          `Pin<&mut stream>`
        ],
      )
    ]
  ]

  *Pin projection* safely converts pinned references without breaking "never move" guarantee
]

#slide[
  === Simple solution: Box the inner stream

  Avoid Pin projection complexity by making everything `Unpin`:

  #text(size: 8pt)[
    ```rust
    struct Double<S> {
        stream: Box<S>,  // Box<T> is always Unpin
    }

    impl<S> Double<S> {
        fn new(stream: S) -> Self {
            Self { stream: Box::new(stream) }
        }
    }
    ```]

  *Why this works:* `Box<T>` is always `Unpin`, so `self.get_mut()` is safe

  *Trade-off:* Extra heap allocation vs satisfying `Unpin` requirements

]



#slide[
  #text(size: 9pt)[
    Define a *blanket implementation* for `Double`:


    ```rust
      trait StreamExt: Stream {
          fn double(self) -> Double<Self>
          where
              Self: Sized + Stream<Item = i32>,
          {
            Double::new(self)
          }
      }
      impl<S: Stream> StreamExt for S {}
    ```
    Now you can easily double the values in a stream:

    ```rust
    let doubled = stream::iter(1..=5).double();
    ```
  ]
]

#slide[

  == Part 3: Real Example
]

#slide[
  === Real problem: `Stream`s aren't `Clone`

  You can't copy a stream like other Rust values:

  ```rust
  let numbers = stream::iter(vec![1, 2, 3, 4, 5]);
  let copy = numbers.clone(); // Error!
  ```


  But sometimes you need multiple consumers:
  - Process data in parallel
  - Split stream for different tasks
  - Cache results for replay
]

#slide[

  My `clone-stream` crate solves this (but I was not the first):

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
  === `Waker` coordination

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
  === How waking works

  The coordination process:


  1. *Clone waits* - Clone calls `.next().await`, returns `Pending`
  2. *Waker stored* - Clone's waker gets stored in its state
  3. *Base stream polled* - Meta-waker given to base stream
  4. *New data arrives* - Base stream wakes the meta-waker
  5. *All wake up* - Meta-waker wakes all waiting clones


  Efficient: no unnecessary wake-ups for clones that aren't waiting
]

#slide[
  === Clone-stream usage

  #text(size: 10pt)[
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
    ```]
]





#slide[
  === Smart buffering: setup

  Bob polls first, but no data is available yet:

  #text(size: 9pt)[
    ```rust
    let (sender, rx) = tokio::sync::mpsc::unbounded_channel();
    let stream = tokio_stream::wrappers::UnboundedReceiverStream::new(rx);

    let mut adam = stream.fork();
    let mut bob = adam.clone();

    // Bob starts waiting for data (no data sent yet)
    let bob_task = tokio::spawn(async move {
        bob.next().await // Returns Pending, Bob gets suspended
    });
    ```]

  Bob is now in a "waiting" state with his waker stored
]

#slide[
  === Smart buffering: data arrives

  Adam polls and data arrives - this wakes Bob too:

  #text(size: 8pt)[
    ```rust
    sender.send('a').unwrap();

    // Adam polls and gets the data
    let adam_task = tokio::spawn(async move {
        adam.next().await // Gets Some('a') immediately
    });

    // Bob's waker gets triggered automatically!
    let (adam_result, bob_result) = tokio::join!(adam_task, bob_task);

    assert_eq!(adam_result.unwrap(), Some('a'));
    assert_eq!(bob_result.unwrap(), Some('a')); // Same data!
    ```]
]

#slide[
  === How it works

  The coordination:

  1. Bob waits → waker stored
  2. Adam polls → data arrives
  3. Meta-waker → wakes both
  4. Both get same data


  Buffering only happens when clones are actively waiting
]

#slide[
  === Late cloning

  You can clone even after receiving some items:

  #text(size: 8pt)[
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
    ```]
]

#slide[
  === Memory management warning

  Suspended clones *can cause memory buildup*:
  #text(size: 10pt)[
    ```rust
    let original = some_big_stream().fork();

    let mut fast = original.clone();
    let mut very_slow = original.clone();

    // very_slow gets suspended waiting for data
    let slow_task = tokio::spawn(async move {
        very_slow.next().await // Suspended!
    });
    ```]

  Now `very_slow` is in a suspended state
]

#slide[
  === Memory buildup problem

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
  == Part 4: Conclusion
]

#slide[
  === Next steps

  Exercises:
  - `timeout(duration)` - cancel slow streams
  - `batch(n)` - group items into chunks
  - `rate_limit(per_second)` - throttle stream speed


  Other topics:
  - `stream::unfold` for simple stream states
  - Flattening nested streams with `flatten_*` combinators
  - The complementary `Sink` trait
  - Reactive futures crate: #link("https://crates.io/crates/futures-rx")[`futures-rx`]
]

#slide[
  === Summary

  - Streams are async iterators that return multiple values at unpredictable times

  - Start with existing combinators - `map`, `filter`, `collect`, `fold`

  - Build custom operators using the wrapper pattern + `Stream` trait

  - Clone-stream enables parallel processing - but watch memory with slow readers



  #align(center)[
    _You can now build your own stream operators!_
  ]
]

#slide[

  === Links




  - Blogpost series about streams: #link("https://willemvanhulle.tech/blog/streams/")[`willemvanhulle.tech/blog/streams/`]

  - Stream cloning crate: #link("https://crates.io/crates/clone-stream")[clone-stream]

  - Stream operator docs: #link("https://docs.rs/futures")[`docs.rs/futures`]


  - These slides: #link("https://github.com/wvhulle/streams-eurorust-2025")[`github.com/wvhulle/streams-eurorust-2025`] (I recommend Typst!)

]


#slide[


  #align(center)[

    #text(size: 2em)[Thank you!]

    Willem Vanhulle \

    #v(5em)


    Contact me!

    #link("mailto:willemvanhulle@protonmail.com") \
    #link("https://willemvanhulle.tech")[willemvanhulle.tech]


  ]


]
