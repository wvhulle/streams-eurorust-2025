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
          spacing: (5em, 2em),
          {
            emoji-node((-2, 1), colors.neutral, <vehicle>)[🚗]
            styled-edge(<vehicle>, <video>, color: colors.data)
            styled-edge(<vehicle>, <audio>, color: colors.data)
            styled-edge(<vehicle>, <data>, color: colors.data)


            emoji-node((0, 2), colors.stream, <video>)[📹]
            styled-edge(<video>, <control>, color: colors.data)

            emoji-node((0, 1), colors.stream, <audio>)[🎵]
            styled-edge(<audio>, <control>, color: colors.data)

            emoji-node((0, 0), colors.stream, <data>)[📊]
            styled-edge(<data>, <control>, color: colors.data)

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
        )[ #box(width: 1em, height: 1em, rect(fill: colors.data, stroke: accent(colors.data))) Data]

        node(
          (1, 1),
          name: <legend-streams>,
          fill: none,
          stroke: none,
        )[ #box(width: 1em, height: 1em, rect(fill: colors.stream, stroke: accent(colors.stream))) Streams]

        node(
          (1, 0),
          name: <legend-operators>,
          fill: none,
          stroke: none,
        )[ #box(width: 1em, height: 1em, rect(fill: colors.operator, stroke: accent(colors.operator))) Operators]
      },
    )
  ]

  slide(title: "Process TCP connections and collect 5 long messages")[

    #set text(size: 8pt)


    #grid(
      columns: (1fr, 0.4fr),
      column-gutter: 1em,
      ```rust
      let mut results = Vec::new(); let mut count = 0;

      while let Some(connection) = tcp_stream.next().await {
          match connection {
              Ok(stream) if should_process(&stream) => {
                  match process_stream(stream).await {
                      Ok(msg) if msg.len() > 10 => {
                          results.push(msg);
                          count += 1;
                          if count >= 5 { break; }
                      }
                      Ok(_) => continue,
                      Err(_) => continue,
                  }
              }
              Ok(_) => continue,
              Err(_) => continue,
          }
      }
      ```,
      align(horizon)[
        *Problems:*
        - Deeply nested
        - Hard to read
        - Cannot test pieces independently
      ],
    )
  ]

  slide(title: [`Stream` operators: declarative & composable])[


    #set text(size: 9pt)
    Same logic with stream operators:


    #grid(
      columns: (1fr, 0.4fr),
      column-gutter: 1em,
      ```rust
      let results: Vec<String> = tcp_stream
          .filter_map(|conn| ready(conn.ok()))
          .filter(|stream| ready(should_process(stream)))
          .then(|stream| process_stream(stream))
          .filter_map(|result| ready(result.ok()))
          .filter(|msg| ready(msg.len() > 10))
          .take(5)
          .collect()
          .await;
      ```,
      align(horizon)[
        *Benefits:*
        - Each operation is isolated
        - Testable
        - Reusable
      ]
    )



    #quote(attribution: [Abelson & Sussman])[Programs must be written *for people to read*]

  ]
}
