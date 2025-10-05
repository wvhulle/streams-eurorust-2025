#import "../lib/constants.typ": *
#import "../lib/diagram-helpers.typ": *
#import "@preview/fletcher:0.5.8" as fletcher: diagram, edge, node

#let motivation-slides(slide) = {
  slide[
    == Motivation
  ]

  slide(title: "Processing data from moving vehicles")[
    #align(center)[
      #show text: it => [
        #set align(center + horizon)
        #box(baseline: -0.3em)[#it]
      ]
      #{
        styled-diagram(
          spacing: (2em, 1em),
          {
            emoji-node((-2, 1), colors.neutral, <vehicle>)[🚗]
            styled-edge(<vehicle>, <video>, color: colors.neutral)
            styled-edge(<vehicle>, <audio>, color: colors.neutral)
            styled-edge(<vehicle>, <data>, color: colors.neutral)

            emoji-node((0, 2), colors.stream, <video>)[📹]
            styled-edge(<video>, <control>, color: colors.stream)

            emoji-node((0, 1), colors.stream, <audio>)[🎵]
            styled-edge(<audio>, <control>, color: colors.data)

            emoji-node((0, 0), colors.stream, <data>)[📊]
            styled-edge(<data>, <control>, color: colors.operator)

            emoji-node((3, 1), colors.neutral, <control>)[🎛️]
          },
        )
      }
    ]
  ]

  slide(title: "Kinds of streams")[
    #styled-diagram(
      spacing: (1em, 2em),
      {
        layer(
          (0, 0),
          <operators>,
          "Stream operators",
          "Pure software transformations",
          ([`map()`], [*`double()`*], [*`fork()`*], [*`latency()`*], [*`hysteresis()`*]),
          color: colors.operator,
        )

        layer(
          (0, 1),
          <leaf>,
          "Leaf streams",
          "OS/kernel constraints",
          ([`tokio::fs::File`], [`TcpListener`], [`UnixStream`], [`Interval`]),
          color: colors.stream,
        )

        layer(
          (0, 2),
          <physical>,
          "Physical streams",
          "Electronic signals",
          ("GPIO interrupts", "UART frames", "Network packets"),
          color: colors.data,
        )

        styled-edge(<physical>, <leaf>, "->", color: colors.operator, label: "OS abstraction")
        styled-edge(<leaf>, <operators>, "->", color: colors.stream, label: "Stream operators")

        node(
          (-1, 1),
          name: <runtime-note>,
          [Requires an `async` runtime \ #text(size: 0.7em)[(see 'leaf future' by _Carl Fredrik Samson_)]],
          stroke: none,
        )
        styled-edge(<runtime-note>, <leaf>, "->", color: colors.neutral)

        node((-1, 0), name: <presentation-note>, [In this presentation], stroke: none)
        styled-edge(<presentation-note>, <operators>, "->", color: colors.neutral)

        node(
          (1, 2),
          name: <legend-data>,
          fill: none,
          stroke: none,
        )[ #box(width: 1em, height: 1em, rect(fill: colors.data, stroke: colors.data)) Data]

        node(
          (1, 1),
          name: <legend-streams>,
          fill: none,
          stroke: none,
        )[ #box(width: 1em, height: 1em, rect(fill: colors.stream, stroke: colors.stream)) Streams]

        node(
          (1, 0),
          name: <legend-operators>,
          fill: none,
          stroke: none,
        )[ #box(width: 1em, height: 1em, rect(fill: colors.operator, stroke: colors.operator))   Operators]
      },
    )
  ]

  slide(title: "Naive stream processing")[
    *The challenge:* Process TCP connections, filter messages, and collect 5 long ones

    #text(size: 8pt)[
      ```rust
      let mut filtered_messages = Vec::new(); let mut count = 0; let mut = 0;
      let mut tcp_stream = tokio::net::TcpListener::bind("127.0.0.1:8080")
            .await?
            .incoming();
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

  slide(title: "Complexity grows with each requirement")[
    Inside the processing block, *even more nested logic:*

    #text(size: 8pt)[
      ```rust
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

    *Problems:* hard to read, trace or test!
  ]


  slide(title: [`Stream` operators preview])[
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

    "Programs must be written *for people to read*, and only incidentally for machines to execute." — _Harold Abelson & Gerald Jay Sussman_
  ]
}
