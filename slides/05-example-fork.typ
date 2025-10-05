#import "../lib/constants.typ": *
#import "../lib/diagram-helpers.typ": *
#import "@preview/fletcher:0.5.8" as fletcher: diagram, edge, node
#import "@preview/cetz:0.4.2": canvas, draw

#let example-fork-slides(slide) = {
  slide[
    == Example 2: One-to-N  Operator
  ]

  slide(title: "Complexity 1-N operators")[
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
          circle((x, y), radius: 0.2, fill: if i < 2 { colors.pin.base } else { colors.state.base })
          content((x, y - 0.5), text(size: 6pt, "C" + str(i + 1)), anchor: "center")
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
        spacing: (6em, 1em),

        stream-node((0, 1), [`InputStream`], <input-stream>),
        labeled-flow(<input-stream>, <fork>, [`.fork()`], colors.stream, label-pos: 0.4),

        stream-node((1, 1), [`Fork`], <fork>),
        labeled-flow(<fork>, <bob>, [`.clone()`], colors.ui, bend: -20deg),
        labeled-flow(<fork>, <alice>, [`.clone()`], colors.ui, bend: 20deg),
        queue-link(<fork>, <queue-a-consumed>, "queue", colors),

        stream-node((2, 2), "Bob", color: colors.state, <bob>),
        simple-flow(<bob>, <bob-a>, colors.operator),

        stream-node((2, 0), "Alice", color: colors.ui, <alice>),
        simple-flow(<alice>, <alice-a>, colors.operator),

        queue-item((3, 1), "'a'", true, <queue-a-consumed>, colors),
        queue-item((3.5, 1), "'b'", true, <queue-b-consumed>, colors),
        queue-item((4, 1), "'c'", false, <queue-c>, colors),
        queue-item((4.5, 1), "'d'", false, <queue-d>, colors),

        data-item((3, 3), "'a'", <bob-a>, colors),
        data-item((3.5, 3), "'b'", <bob-b>, colors),
        data-item((4, 3), "'c'", <bob-c>, colors),
        data-item((3, -1), "'a'", <alice-a>, colors),
        data-item((3.5, -1), "'b'", <alice-b>, colors),
      )
    }

    #align(center)[
      #grid(
        columns: (auto, auto, auto, auto, auto, auto, auto, auto),
        column-gutter: 1.5em,

        rect(width: 1em, height: 0.6em, fill: colors.stream.base, stroke: colors.stream.accent + 0.5pt),
        [Streams],
        rect(width: 1em, height: 0.6em, fill: colors.operator.base, stroke: colors.operator.accent + 0.5pt),
        [Operators],
        rect(width: 1em, height: 0.6em, fill: colors.state.base, stroke: colors.state.accent + 0.5pt),
        [Consumers],
        rect(width: 1em, height: 0.6em, fill: colors.data.base, stroke: colors.data.accent + 0.5pt),
        [Data],
      )
    ]
  ]

  slide(title: "Polling and waking flow")[
    #set text(size: 7pt)
    #styled-diagram(
      spacing: (3em, 2.5em),

      node(
        (1, 0),
        [`InputStream`],
        fill: colors.stream.base,
        stroke: colors.stream.accent + stroke-width,
        name: <poll-input-stream>,
      ),
      edge(
        <poll-input-stream>,
        <poll-alice>,
        [2. `Pending`],
        "->",
        stroke: colors.neutral.accent + stroke-width,
        bend: -85deg,
        label-pos: 90%,
      ),
      edge(<poll-input-stream>, <poll-data>, [4. `Ready`], "->", stroke: colors.operator.accent + arrow-width),

      node(
        (0, 3),
        [Alice\ 💤 Sleeping],
        fill: colors.ui.base,
        stroke: colors.ui.accent + stroke-width,
        shape: fletcher.shapes.circle,
        name: <poll-alice>,
      ),
      edge(
        <poll-alice>,
        <poll-input-stream>,
        [1. `poll_next()`],
        "->",
        stroke: colors.neutral.accent + stroke-width,
        bend: 50deg,
        label-pos: 79%,
      ),
      edge(
        <poll-alice>,
        <poll-data>,
        [6. `poll_next()`],
        "->",
        stroke: colors.stream.accent + stroke-width,
        bend: -40deg,
        label-pos: 30%,
      ),

      node(
        (2, 3),
        [Bob\ 🔍 Polling],
        fill: colors.state.base,
        stroke: colors.state.accent + stroke-width,
        shape: fletcher.shapes.circle,
        name: <poll-bob>,
      ),
      edge(
        <poll-bob>,
        <poll-input-stream>,
        [3. `poll_next()`],
        "->",
        stroke: colors.state.accent + arrow-width,
        bend: -50deg,
        label-pos: 70%,
      ),
      edge(
        <poll-bob>,
        <poll-alice>,
        [5. `wake()` Alice],
        "->",
        stroke: colors.state.accent + arrow-width,
        bend: 40deg,
      ),

      node(
        (1, 1.5),
        [data 'x'],
        fill: colors.data.base,
        stroke: colors.data.accent + stroke-width,
        name: <poll-data>,
      ),
      edge(
        <poll-data>,
        <poll-alice>,
        [7. `clone()`],
        "->",
        stroke: colors.operator.accent + stroke-width,
        bend: -40deg,
        label-pos: 30%,
      ),
      edge(
        <poll-data>,
        <poll-bob>,
        [8. original],
        "->",
        stroke: colors.operator.accent + stroke-width,
        bend: 40deg,
        label-pos: 30%,
      ),
    )
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

        edge(<send-start>, <send-end>, stroke: colors.neutral.accent + 1.5pt, "->")
        edge(<consume1-start>, <consume1-end>, stroke: colors.neutral.accent + 1.5pt, "->")
        edge(<consume2-start>, <consume2-end>, stroke: colors.neutral.accent + 1.5pt, "->")

        node((4, 0), [•], fill: colors.pin.base, stroke: colors.pin.accent + 1pt, name: <b1>)
        node((4, 0.5), text(size: 7pt)[`b1.wait().await`], stroke: none, name: <b1-label>)

        node((5, 1), [•], fill: colors.pin.base, stroke: colors.pin.accent + 1pt, name: <b2>)
        node((5, 1.6), text(size: 7pt)[`b2.wait().await`], stroke: none, name: <b2-label>)

        node((6, 2), [•], fill: colors.pin.base, stroke: colors.pin.accent + 1pt, name: <b3>)
        node((6, 2.6), text(size: 7pt)[`b3.wait().await`], stroke: none, name: <b3-label>)

        node((6, -1), [•], fill: colors.state.base, stroke: colors.state.accent + 1.5pt, name: <crossed>)
        node((5.5, -1), text(size: 7pt)[Barrier crossed], stroke: none, name: <crossed-label>)
        node((10, -1), [], stroke: none, name: <end>)

        edge(<crossed>, <b3>, stroke: (paint: colors.state.accent, dash: "dashed", thickness: 1pt), "-")
        edge(<crossed>, <end>, stroke: colors.state.accent + 2pt, "->")
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
        transition(
          <polling-base-stream>,
          <processing-queue>,
          [input stream ready,\ queue item],
          label-pos: 0.5,
          label-anchor: "north",
          label-sep: 0em,
        ),
        transition(
          <polling-base-stream>,
          <pending>,
          "input stream pending",
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
        transition(
          <processing-queue>,
          <polling-base-stream>,
          [buffer empty,\ poll base],
          bend: 40deg,
          label-pos: 0.5,
        ),

        state-node((1, 0), "Sleeping", "Waiting with stored waker", colors.ui, <pending>),
        transition(<pending>, <polling-base-stream>, "woken", bend: -15deg, label-pos: 0.7, label-sep: 1em),
        transition(<pending>, <processing-queue>, "fresh buffer", bend: 15deg, label-pos: 0.7),
      )
    }

    Each clone maintains its own #link("https://github.com/wvhulle/clone-stream/blob/main/src/states.rs")[state]:
  ]
}
