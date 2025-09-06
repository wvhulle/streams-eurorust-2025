#set page(
  width: 16cm,
  height: 9cm,
  margin: 1.5cm,
)
#set text(size: 12pt)
#set par(justify: false)

#show raw: set text(size: 8pt)

#show raw.where(block: true): block.with(breakable: false)

#let slide(content) = {
  pagebreak(weak: true)
  content
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
  = What We'll Cover

  - Stream fundamentals in Rust
  - Working with existing stream operators
  - Building custom stream combinators
  - Real-world example: `clone-stream`
  - Advanced patterns and best practices

  #v(2em)

  *Goal:* By the end, you'll be comfortable creating your own stream operators!
]

#slide[
  = What Are Streams?

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
  = When to Use Streams?

  #grid(
    columns: (1fr, 1fr),
    gutter: 2em,
    [
      *Use Streams when:*
      - Handling async data sources
      - Processing data pipelines
      - Working with I/O events
      - Need backpressure control
      - Composable transformations
    ],
    [
      *Alternatives:*
      - `Iterator` for sync data
      - `async fn` for single values
      - Channels for message passing
      - Direct polling for simple cases
    ],
  )
]

#slide[
  = Stream Fundamentals: Pin & Poll

  ```rust
  // Poll represents the state of async operations
  enum Poll<T> {
      Ready(T),    // Value is ready now
      Pending,     // Not ready, try again later
  }

  // Pin ensures memory safety for self-referential types
  // Pin<&mut Self> = "this won't move in memory"
  ```

  Key insight: Streams are _pull-based_ and _lazy_
]

#slide[
  = Basic Stream Consumption

  ```rust
  async fn consume_stream<S>(mut stream: S)
  where S: Stream<Item = i32> + Unpin
  {
      while let Some(item) = stream.next().await {
          println!("Got: {}", item);
      }
  }

  // Or collect all items
  async fn collect_all<S>(stream: S) -> Vec<i32>
  where S: Stream<Item = i32>
  {
      stream.collect().await
  }
  ```
]

#slide[
  = Working with Existing Operators

  The `futures` crate provides many built-in combinators:

  ```rust
  let numbers = stream::iter(1..=10);

  let result: Vec<_> = numbers
      .filter(|&x| async move { x % 2 == 0 })  // Keep evens
      .map(|x| x * 2)                          // Double them
      .take(3)                                 // Take first 3
      .collect()
      .await;

  // result: [4, 8, 12]
  ```
]

#slide[
  = More Stream Combinators

  ```rust
  // Error handling
  let results = stream::iter(vec![Ok(1), Err("oops"), Ok(3)]);
  let successes: Vec<i32> = results
      .try_filter(|&x| async move { x > 0 })
      .try_collect()
      .await
      .unwrap_or_default();

  // Async transformations
  let transformed = stream::iter(1..=5)
      .then(|x| async move {
          tokio::time::sleep(Duration::from_millis(x * 10)).await;
          x * x
      });
  ```
]

#slide[
  = Building Custom Stream Operators

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
  = Implementing the Stream Trait

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
          // ...
      }
  }
  ```
]

#slide[
  = Stream Implementation Body

  ```rust
  fn poll_next(
      self: Pin<&mut Self>,
      cx: &mut Context<'_>
  ) -> Poll<Option<Self::Item>> {
      let stream = unsafe {
          self.map_unchecked_mut(|s| &mut s.stream)
      };

      match ready!(stream.poll_next(cx)) {
          Some(value) => Poll::Ready(Some(value * 2)),
          None => Poll::Ready(None),
      }
  }
  ```
]

#slide[
  = Making It Ergonomic

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

  // Usage:
  let doubled = stream::iter(1..=5).double();
  ```
]

#slide[
  = Real-World Example: Clone Stream

  Problem: Streams are not `Clone` by default

  ```rust
  let stream = some_expensive_stream();
  let cloned = stream.clone(); // Doesn't work!

  // We want to split the stream:
  let (stream1, stream2) = stream.split_somehow();
  ```

  Solution: Create a cloneable wrapper that broadcasts values
]

#slide[
  = Clone Stream Architecture

  ```rust
  struct CloneStream<T> {
      shared: Arc<Mutex<SharedState<T>>>,
      position: usize,
  }

  struct SharedState<T> {
      buffer: VecDeque<T>,
      completed: bool,
      wakers: Vec<Waker>,
  }
  ```

  Each clone reads from a shared buffer at its own pace
]

#slide[
  = Clone Stream Implementation

  ```rust
  impl<T: Clone> Stream for CloneStream<T> {
      type Item = T;

      fn poll_next(
          mut self: Pin<&mut Self>,
          cx: &mut Context<'_>
      ) -> Poll<Option<Self::Item>> {
          // ...
      }
  }
  ```
]

#slide[
  = Clone Stream Poll Logic

  ```rust
  fn poll_next(
      mut self: Pin<&mut Self>,
      cx: &mut Context<'_>
  ) -> Poll<Option<Self::Item>> {
      let mut shared = self.shared.lock().unwrap();

      if let Some(item) = shared.buffer.get(self.position) {
          self.position += 1;
          Poll::Ready(Some(item.clone()))
      } else if shared.completed {
          Poll::Ready(None)
      } else {
          shared.wakers.push(cx.waker().clone());
          Poll::Pending
      }
  }
  ```
]

#slide[
  = Making It Cloneable

  ```rust
  impl<T> Clone for CloneStream<T> {
      fn clone(&self) -> Self {
          Self {
              shared: Arc::clone(&self.shared),
              position: self.position, // Each clone has its own position
          }
      }
  }

  trait StreamExt: Stream {
      fn cloneable(self) -> CloneStream<Self::Item>
      where
          Self: Sized,
          Self::Item: Clone,
      {
          CloneStream::from_stream(self)
      }
  }
  ```
]

#slide[
  = Using Clone Stream

  ```rust
  let original = stream::iter(vec![1, 2, 3, 4, 5])
      .cloneable(); // Now it's Clone!

  let stream1 = original.clone().take(3);
  let stream2 = original.clone().skip(2);

  // stream1 gets: [1, 2, 3]
  // stream2 gets: [3, 4, 5]

  let (results1, results2) = tokio::join!(
      stream1.collect::<Vec<_>>(),
      stream2.collect::<Vec<_>>()
  );
  ```
]

#slide[
  = Advanced Patterns: Error Handling

  ```rust
  struct TryDouble<S> {
      stream: S,
  }

  impl<S, E> Stream for TryDouble<S>
  where
      S: Stream<Item = Result<i32, E>>,
  {
      type Item = Result<i32, E>;

      fn poll_next(
          self: Pin<&mut Self>,
          cx: &mut Context<'_>
      ) -> Poll<Option<Self::Item>> {
          // ...
      }
  }
  ```
]

#slide[
  = Error Handling Logic

  ```rust
  fn poll_next(
      self: Pin<&mut Self>,
      cx: &mut Context<'_>
  ) -> Poll<Option<Self::Item>> {
      let stream = unsafe {
          self.map_unchecked_mut(|s| &mut s.stream)
      };

      match ready!(stream.poll_next(cx)) {
          Some(Ok(value)) => Poll::Ready(Some(Ok(value * 2))),
          Some(Err(e)) => Poll::Ready(Some(Err(e))),
          None => Poll::Ready(None),
      }
  }
  ```
]

#slide[
  = Performance Considerations

  - *Pin projections*: Use `pin-project` crate for complex cases
  - *Avoid unnecessary allocations*: Buffer when needed, not always
  - *Batch operations*: Process multiple items when possible
  - *Fuse streams*: Handle completion properly

  ```rust
  #[pin_project]
  struct MyStream<S> {
      #[pin]
      inner: S,
      count: usize,
  }

  // pin_project generates safe Pin projections
  ```
]

#slide[
  = Testing Stream Operators

  ```rust
  #[tokio::test]
  async fn test_double_stream() {
      let input = stream::iter(vec![1, 2, 3]);
      let doubled = input.double();

      let result: Vec<_> = doubled.collect().await;
      assert_eq!(result, vec![2, 4, 6]);
  }
  ```
]

#slide[
  = Testing Clone Streams

  ```rust
  #[tokio::test]
  async fn test_clone_stream() {
      let original = stream::iter(vec![1, 2, 3]).cloneable();
      let clone1 = original.clone();
      let clone2 = original.clone();

      let (r1, r2) = tokio::join!(
          clone1.collect::<Vec<_>>(),
          clone2.collect::<Vec<_>>()
      );

      assert_eq!(r1, r2);
  }
  ```
]

#slide[
  = Common Pitfalls & Solutions

  #grid(
    columns: (1fr, 1fr),
    gutter: 1em,
    [
      *Pitfalls:*
      - Forgetting to pin-project properly
      - Not handling stream completion
      - Memory leaks in shared state
      - Blocking in `poll_next`
      - Ignoring waker notifications
    ],
    [
      *Solutions:*
      - Use `pin-project` crate
      - Always check for `None`
      - Clean up resources properly
      - Keep `poll_next` non-blocking
      - Wake all relevant tasks
    ],
  )
]

#slide[
  = Key Takeaways

  1. *Streams are async iterators* - understand Pin & Poll
  2. *Start with existing combinators* - they cover most cases
  3. *Custom operators follow patterns* - wrapper struct + Stream impl
  4. *Pin projections are tricky* - use `pin-project` for complex cases
  5. *Testing is crucial* - async code has subtle bugs

  #v(1em)

  *Remember:* Build on existing patterns, test thoroughly, and keep it simple!
]

#slide[
  = Resources & Next Steps

  - *Blog series:* `willemvanhulle.tech/blog/streams/`
  - *Code examples:* `github.com/wvhulle/clone-stream`
  - *Documentation:* `docs.rs/futures`
  - *Advanced patterns:* `tokio.rs` and `async-stream` crate

  #v(2em)

  #align(center)[
    = Questions?

    _Let's explore streams together!_

    #v(1em)

    Willem Vanhulle \
    `@wvhulle`
  ]
]
