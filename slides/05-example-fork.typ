#import "../lib/constants.typ": *
#import "../lib/diagram-helpers.typ": *
#import "@preview/fletcher:0.5.8" as fletcher: diagram, edge, node
#import "@preview/cetz:0.4.2": canvas, draw

#let example-fork-slides(slide) = {
  slide[
    == Example 2: One-to-N  Operator
  ]

  slide(title: [Complexity $1-N$ operators])[
    Challenges for `Stream` operators are combined from:

    #grid(
      columns: (1fr, 1fr),
      column-gutter: 2em,
      [
        *Inherent `Future` challenges:*
        - Clean up orphaned wakers
        - Cleanup when tasks abort
        - Task coordination complexity
      ],
      [
        *Inherent `Iterator` challenges:*
        - Ordering guarantees across consumers
        - Backpressure with slow consumers
        - Sharing mutable state safely
        - Avoiding duplicate items
      ],
    )

    #align(center)[
      #canvas(length: 1cm, {
        import draw: *

        let clone-positions = ((0.5, 1), (2, 0.5), (4, 0.2), (6, 1.2), (7.5, 0.8))
        for (i, pos) in clone-positions.enumerate() {
          let (x, y) = pos
          let color = if i < 2 { colors.pin } else { colors.state }
          styled-circle(draw, (x, y), color, radius: 0.2)[C]
        }

        content((4, 1), text(size: 8pt, "Thousands of clones..."), anchor: "center")
      })
    ]
  ]

  slide(title: "Sharing latency between tasks")[
    Latency may need to processed by different async tasks:

    ```rust
    let tcp_stream = TcpStream::connect("127.0.0.1:8080").await?;
    let latency = tcp_stream.latency(); // Stream<Item = Duration>
    spawn(async move { display_ui(latency).await; });
    spawn(async move { engage_breaks(latency).await; }); // Error!
    ```

    *Error*: `latency` is moved into the first task,   so the second task can't access it.
  ]

  slide(title: "Cloning streams with an operator")[
    *Solution*: Create a _*stream operator*_ `fork()` makes the input stream `Clone`.

    ```rust
    let tcp_stream = TcpStream::connect("127.0.0.1:8080").await?;

    // Fork makes the input stream cloneable
    let ui_latency = tcp_stream.latency().fork();

    let breaks_latency_clone = ui_latency.clone();
    // Warning: `Clone` needs to be implemented!

    spawn(async move { display_ui(ui_latency).await; });
    spawn(async move { engage_breaks(breaks_latency_clone).await; });
    ```

    *Requirement*: `Stream<Item: Clone>`, so we can clone the items (`Duration` is `Clone`)
  ]

  slide(title: [Rough architecture of #link("https://crates.io/crates/clone-stream")[`clone-stream`]])[
    #set text(size: 9pt)
    #{
      styled-diagram(
        spacing: (5em, 1em),

        stream-node((0, 1), <input-stream>)[`InputStream`],
        styled-edge(<input-stream>, <fork>, color: colors.operator, label: [`.fork()`], label-pos: 0.4),

        stream-node((1, 1), <fork>)[`Fork`],
        styled-edge(<fork>, <bob>, color: colors.neutral, label: [`.clone()`], bend: -20deg),
        styled-edge(<fork>, <alice>, color: colors.neutral, label: [`.clone()`], bend: 20deg),
        queue-link(<fork>, <queue-a-consumed>, "queue", colors.neutral),

        stream-node((2, 2), <bob>, color: colors.stream)[Bob],
        styled-edge(<bob>, <bob-a>, color: colors.action),

        stream-node((2, 0), <alice>, color: colors.stream)[Alice],
        styled-edge(<alice>, <alice-a>, color: colors.action),

        queue-item((3, 1), true, <queue-a-consumed>)['a'],
        queue-item((3.5, 1), true, <queue-b-consumed>)['b'],
        queue-item((4, 1), false, <queue-c>)['c'],
        queue-item((4.5, 1), false, <queue-d>)['d'],

        data-item((3, 3), <bob-a>)['a'],
        data-item((3.5, 3), <bob-b>)['b'],
        data-item((4, 3), <bob-c>)['c'],
        data-item((3, -1), <alice-a>)['a'],
        data-item((3.5, -1), <alice-b>)['b'],
      )
    }

    #align(center)[
      #legend((
        (color: colors.stream, label: [Streams]),
        (color: colors.operator, label: [Operators]),
        (color: colors.data, label: [Data]),
      ))
    ]
  ]

  slide(title: "Polling and waking flow")[
    #set text(size: 7pt)
    #v(-5em)

    #styled-diagram(
      spacing: (3em, 2.5em),

      colored-node(
        (1, 0),
        color: colors.stream,
        name: <poll-input-stream>,
      )[`InputStream`],
      styled-edge(
        <poll-input-stream>,
        <poll-alice>,
        label: [2. `Pending`],
        color: colors.data,
        bend: -85deg,
        label-pos: 90%,
      ),
      styled-edge(<poll-input-stream>, <poll-data>, label: [4. `Ready`], color: colors.data),

      colored-node(
        (0, 3),
        color: colors.stream,
        name: <poll-alice>,
        shape: fletcher.shapes.circle,
      )[Alice\ 💤 Sleeping],
      styled-edge(
        <poll-alice>,
        <poll-input-stream>,
        label: [1. `poll_next()`],
        color: colors.action,
        bend: 50deg,
        label-pos: 79%,
      ),
      styled-edge(
        <poll-alice>,
        <poll-data>,
        label: [6. `poll_next()`],
        color: colors.action,
        bend: -40deg,
        label-pos: 30%,
      ),

      colored-node(
        (2, 3),
        color: colors.stream,
        name: <poll-bob>,
        shape: fletcher.shapes.circle,
      )[Bob\ 🔍 Polling],
      styled-edge(
        <poll-bob>,
        <poll-input-stream>,
        label: [3. `poll_next()`],
        color: colors.action,
        stroke-width: arrow-width,
        bend: -50deg,
        label-pos: 70%,
      ),
      styled-edge(
        <poll-bob>,
        <poll-alice>,
        label: [5. `wake()` Alice],
        color: colors.action,
        stroke-width: arrow-width,
        bend: 40deg,
      ),

      colored-node(
        (1, 1.5),
        color: colors.data,
        name: <poll-data>,
      )[data 'x'],
      styled-edge(
        <poll-data>,
        <poll-alice>,
        label: [7. `clone()`],
        color: colors.neutral,
        bend: -40deg,
        label-pos: 30%,
      ),
      styled-edge(
        <poll-data>,
        <poll-bob>,
        label: [8. original],
        color: colors.data,
        bend: 40deg,
        label-pos: 30%,
      ),
    )

    #v(1em)

    #legend((
      (color: colors.stream, label: [Streams]),
      (color: colors.action, label: [Actions]),
      (color: colors.data, label: [Data]),
      (color: colors.neutral, label: [Clone operations]),
    ))
  ]

  slide(title: [`Barrier`s for task synchronization])[
    #set text(size: 8pt)

    For performance reasons, you may want to *ignore unpolled consumers* (init required) in 1-to-N stream operators.

    Synchronisation after the "init" phase is done with a single `Barrier` ot type $N + 1$.

    ```rs
    let b1 = Arc::new(Barrier::new(3)); // For input task
    let b2 = b1.clone(); // First output
    let b3 = b1.clone(); // For second output
    ```
    #v(-1em)
    #styled-diagram(
      spacing: (1em, 1em),
      {
        node((0, 0), align(left)[*Send task*], stroke: none, name: <send-label>)
        node((0, 1), align(left)[*Consume 1*], stroke: none, name: <consume1-label>)
        node((0, 2), align(left)[*Consume 2*], stroke: none, name: <consume2-label>)

        node((1, 0), [], stroke: none, name: <send-start>)
        node((1, 1), [], stroke: none, name: <consume1-start>)
        node((1, 2), [], stroke: none, name: <consume2-start>)

        node((10, 0), [], stroke: none, name: <send-end>)
        node((10, 1), [], stroke: none, name: <consume1-end>)
        node((10, 2), [], stroke: none, name: <consume2-end>)

        styled-edge(<send-start>, <send-end>, color: colors.neutral)
        styled-edge(<consume1-start>, <consume1-end>, color: colors.neutral)
        styled-edge(<consume2-start>, <consume2-end>, color: colors.neutral)

        colored-node((4, 0), color: colors.action, name: <b1>, stroke-width: 1pt)[•]
        node((4, 0.5), text(size: 7pt)[`b1.wait().await`], stroke: none, name: <b1-label>)

        colored-node((5, 1), color: colors.action, name: <b2>, stroke-width: 1pt)[•]
        node((5, 1.6), text(size: 7pt)[`b2.wait().await`], stroke: none, name: <b2-label>)

        colored-node((6, 2), color: colors.action, name: <b3>, stroke-width: 1pt)[•]
        node((6, 2.6), text(size: 7pt)[`b3.wait().await`], stroke: none, name: <b3-label>)

        colored-node((6, -1), color: colors.state, name: <crossed>)[•]
        node((5.5, -1), text(size: 7pt)[Barrier crossed], stroke: none, name: <crossed-label>)
        node((10, -1), [], stroke: none, name: <end>)

        edge(<crossed>, <b3>, stroke: (paint: accent(colors.state), dash: "dashed", thickness: 1pt), "-")
        styled-edge(<crossed>, <end>, color: colors.state, stroke-width: 2pt)
      },
    )
  ]

  slide(title: [Including `Barrier`s in your unit tests])[
    #text(size: 8pt)[
      #grid(
        columns: (1fr, 1fr),
        gutter: 1em,
        [
          When you build your own:

          1. Pick a `Barrier` crate (tokio / #link("https://crates.io/crates/async-lock")[async-lock]).
          2. Define synchronization points with `Barrier`:
            ```rs
            let b1 = Arc::new(Barrier::new(3));
            let b2 = b1.clone(); // Second output
            let b3 = b1.clone(); // For input
            ```

          3. Apply your custom operator
            ```rs
            let out_stream1 = create_test_stream(in_stream)
                .your_custom_operator();
            let out_stream2 = out_stream1.clone();
            ```

          4. Send your inputs and outputs to separate tasks
        ],
        [
          5. Do not use `sleep` and await all tasks.
          ```rs
          try_join_all([
              spawn(async move {
                  setup_task().await;
                  b1.wait().await;
                  out_stream1.collect().await;
              }),
              spawn(async move {
                  setup_task().await;
                  b2.wait().await;
                  out_stream2.collect().await;
              }),
              spawn(async move {
                  b3.wait().await;
                  send_input(in_stream).await;
              })
          ]).await.unwrap();
          ```
        ],
      )
    ]
  ]

  slide(
    title: [Simplified state machine of  #link("https://github.com/wvhulle/clone-stream/blob/main/src/states.rs")[`clone-stream`]],
  )[
    #set text(size: 8pt)
    Enforcing simplicity, *correctness and performance*:

    #{
      styled-diagram(
        node-inset: 1em,
        spacing: (4em, 1.5em),

        state-node(
          (0, 1),
          "PollingInputStream",
          "Actively polling input stream",
          colors.state,
          <polling-base-stream>,
        ),
        styled-edge(
          <polling-base-stream>,
          <processing-queue>,
          label: [input stream ready,\ queue item],
          label-pos: 0.5,
          label-anchor: "north",
          label-sep: 0em,
        ),
        styled-edge(
          <polling-base-stream>,
          <pending>,
          label: "input stream pending",
          bend: -15deg,
          label-pos: 0.7,
          label-sep: 0.5em,
          label-anchor: "west",
        ),

        state-node(
          (2, 1),
          "ReadingBuffer",
          "Reading from shared buffer",
          colors.data,
          <processing-queue>,
        ),
        styled-edge(
          <processing-queue>,
          <polling-base-stream>,
          label: [buffer empty,\ poll base],
          bend: 40deg,
          label-pos: 0.5,
        ),

        state-node((1, 0), "Sleeping", "Waiting with stored waker", colors.action, <pending>),
        styled-edge(<pending>, <polling-base-stream>, label: "woken", bend: -15deg, label-pos: 0.7, label-sep: 1em),
        styled-edge(<pending>, <processing-queue>, label: "fresh buffer", bend: 15deg, label-pos: 0.7),
      )
    }

    Each clone maintains its own #link("https://github.com/wvhulle/clone-stream/blob/main/src/states.rs")[state]:
  ]
}
