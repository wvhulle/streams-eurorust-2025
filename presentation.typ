// Import template
#import "template.typ": *
#import "@preview/cetz:0.4.2": canvas, draw
#import "@preview/fletcher:0.5.8" as fletcher: diagram, edge, node
#import fletcher.shapes: pill



// Apply template and page setup
#show: presentation-template.with(
  title: "Make Your Own Stream Operators",
  subtitle: "Advanced stream processing in Rust",
  author: "Willem Vanhulle",
  event: "EuroRust 2025",
  location: "Paris, France",
  duration: "30 minutes + 10 minutes Q&A",
  repository: "https://github.com/wvhulle/streams-eurorust-2025",
)

#slide[

  === Plan

  #v(2em)

  #outline(
    title: none,
    indent: auto,
    depth: 2,
  )

]


#slide[
  == Motivation
]


#slide[
  === My interest in stream processing (with Rust)

  *The problem:* Processing incoming (streaming) data from moving vehicles

  - Inconsistent error handling
  - Complex nested control flow, hard to read
  - Difficult to test individual parts



  #align(center)[
    #show text: it => [
      #set align(center + horizon)
      #box(baseline: -0.2em)[#it]
    ]
    #{
      let emoji-node(pos, emoji, color, name) = node(
        pos,
        if emoji == "🚗" { box(baseline: -0.4em)[#emoji] } else { emoji },
        fill: color.base,
        stroke: color.accent + stroke-width,
        name: name,
      )

      let flow-edge(from, to, color) = edge(from, to, stroke: color.accent + arrow-width, "->")

      diagram(
        node-stroke: stroke-width,
        node-outset: node-outset,
        edge-stroke: arrow-width,
        spacing: (2em, 1em),
        {
          emoji-node((-2, 1), "🚗", colors.neutral, <vehicle>)
          flow-edge(<vehicle>, <video>, colors.neutral)
          flow-edge(<vehicle>, <audio>, colors.neutral)
          flow-edge(<vehicle>, <data>, colors.neutral)

          emoji-node((0, 2), "📹", colors.stream, <video>)
          flow-edge(<video>, <control>, colors.stream)

          emoji-node((0, 1), "🎵", colors.stream, <audio>)
          flow-edge(<audio>, <control>, colors.data)

          emoji-node((0, 0), "📊", colors.stream, <data>)
          flow-edge(<data>, <control>, colors.operator)

          emoji-node((3, 1), "🎛️", colors.state, <control>)
        },
      )
    }
  ]


]



#slide[

  === `Stream`s in Rust are not new


  #align(center)[
    #canvas(length: 1cm, {
      import draw: *

      let draw-timeline-entry(y, year, event, description, reference, ref-url, color) = {
        // Year label
        rect(
          (1, y - 0.3),
          (3, y + 0.3),
          fill: color,
          stroke: color.darken(stroke-darken) + stroke-width,
          radius: node-radius,
        )
        content((2, y), text(size: 8pt, weight: "bold", year), anchor: "center")

        // Event description
        content((3.5, y + 0.2), text(size: 9pt, weight: "bold", event), anchor: "west")
        content((3.5, y - 0.03), text(size: 7pt, description), anchor: "west")
        content(
          (3.5, y - 0.24),
          link(ref-url, text(size: 6pt, style: "italic", fill: colors.stream.accent, reference)),
          anchor: "west",
        )

        // Connection line from timeline to date box
        line((0.8, y), (1, y), stroke: colors.neutral.accent + stroke-width)
      }

      // Timeline entries (bottom to top = old to new)
      draw-timeline-entry(
        5.5,
        "2019",
        "async/await stabilized in Rust",
        "Stable async streams in std",
        "RFC 2394, Rust 1.39.0",
        "https://rust-lang.github.io/rfcs/2394-async_await.html",
        colors.stream.base.lighten(20%),
      )
      draw-timeline-entry(
        4.5,
        "2009",
        "Microsoft Reactive Extensions",
        "ReactiveX brings streams to mainstream",
        "Erik Meijer, Microsoft",
        "https://reactivex.io/",
        colors.operator.base.lighten(30%),
      )
      draw-timeline-entry(
        3.5,
        "1997",
        "Functional Reactive Programming",
        "Conal Elliott & Paul Hudak (Haskell)",
        "ICFP '97, pp. 263-273",
        "https://dl.acm.org/doi/10.1145/258948.258973",
        colors.state.base.lighten(25%),
      )
      draw-timeline-entry(
        2.5,
        "1978",
        "Communicating Sequential Processes",
        "Tony Hoare formalizes concurrent dataflow",
        "CACM 21(8):666-677",
        "https://dl.acm.org/doi/10.1145/359576.359585",
        colors.ui.base.lighten(35%),
      )
      draw-timeline-entry(
        1.5,
        "1973",
        "Unix Pipes",
        "Douglas McIlroy creates `|` operator",
        "Bell Labs, Unix v3-v4",
        "https://www.cs.dartmouth.edu/~doug/reader.pdf",
        colors.data.base.lighten(40%),
      )
      draw-timeline-entry(
        0.5,
        "1960s",
        "Dataflow Programming",
        "Hardware-level stream processing",
        "Early dataflow architectures",
        "https://en.wikipedia.org/wiki/Dataflow_programming",
        colors.error.base.lighten(20%),
      )

      // Main timeline line (positioned to the left, not overlapping with date boxes)
      line((0.8, 0.3), (0.8, 5.7), stroke: colors.neutral.accent + arrow-width)
    })
  ]


]





#slide[
  === Kinds of streams

  #align(center)[
    #fletcher.diagram(
      node-stroke: stroke-width,
      node-corner-radius: node-radius,
      node-outset: node-outset,
      edge-stroke: arrow-width,
      spacing: (1em, 2em),
      {
        let layer(pos, label, desc, fill, examples) = {
          node(pos, fill: fill, stroke: fill.darken(stroke-darken) + stroke-width, stack(
            dir: ttb,
            spacing: 0.3em,

            text(weight: "bold", size: 10pt, label),
            text(size: 8pt, style: "italic", desc),
            text(size: 7pt, examples.join(" • ")),
          ))
        }

        layer(
          (0, 2),
          "Derived streams",
          "Pure software transformations",
          colors.operator.base,
          ("map()", "filter()", ".double()", "fork()"),
        )

        layer(
          (0, 1),
          "Leaf streams",
          "OS/kernel constraints",
          colors.stream.base,
          ("tokio::fs::File", "TcpListener", "UnixStream", "Interval"),
        )

        layer(
          (0, 0),
          "Physical streams",
          "Electronic signals",
          colors.state.base,
          ("GPIO interrupts", "UART frames", "Network packets"),
        )

        edge((0, 0), (0, 1), "->", stroke: colors.operator.accent + arrow-width, label: "OS abstraction")
        edge((0, 1), (0, 2), "->", stroke: colors.stream.accent + arrow-width, label: "Stream operators")

        node(
          (-1, 1),
          [Requires an `async` runtime \ #text(size: 0.7em)[('leaf future' by _Carl Fredrik Samson_)]],
          stroke: none,
        )
        edge((-1, 1), (0, 1), "->", stroke: colors.neutral.accent + arrow-width)

        node((-1, 2), [In this presentation], stroke: none)
        edge((-1, 2), (0, 2), "->", stroke: colors.neutral.accent + arrow-width)
      },
    )
  ]



]


#slide[
  === Naive stream processing

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

#slide[
  === Complexity grows with each requirement

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

  *Problems:* testing, coordination, control flow jumping around
]



#slide[
  === Functional `Stream` usage preview

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



#slide[
  == Rust's `Stream` trait


]


#slide[
  === Moving from `Iterator` to `Stream`

  #align(center + horizon)[
    #{
      let title-node(pos, text) = node(pos, text, fill: none, stroke: none)
      let call-node(pos, text, color, name) = node(
        pos,
        [#text],
        fill: color.base,
        stroke: color.accent + stroke-width,
        name: name,
      )
      let result-node(pos, text, color, name) = node(
        pos,
        [#text],
        fill: color.base,
        stroke: color.accent + stroke-width,
        name: name,
      )
      let simple-edge(from, to) = edge(from, to, "->")

      set text(size: 7pt)
      diagram(
        node-corner-radius: node-radius,
        spacing: (1.2em, 0.8em),
        edge-stroke: stroke-width,
        node-outset: node-outset,

        // Iterator side - title
        title-node((0.5, 5), text(size: 11pt, weight: "bold")[Iterator (sync)]),

        // Iterator calls and results
        call-node((0, 4), "next()", colors.stream, <iter-call1>),
        simple-edge(<iter-call1>, <iter-result1>),
        call-node((0, 3), "next()", colors.stream, <iter-call2>),
        simple-edge(<iter-call2>, <iter-result4>),
        call-node((0, 2), "next()", colors.stream, <iter-call3>),
        simple-edge(<iter-call3>, <iter-result3>),
        call-node((0, 1), "next()", colors.stream, <iter-call4>),
        simple-edge(<iter-call4>, <iter-result2>),

        result-node((1, 4), "Some(1)", colors.data, <iter-result1>),
        result-node((1, 1), "Some(2)", colors.data, <iter-result2>),
        result-node((1, 2), "Some(3)", colors.data, <iter-result3>),
        result-node((1, 3), "None", colors.data, <iter-result4>),


        // Stream low-level side
        title-node((3.5, 5), text(size: 10pt, weight: "bold")[Stream (low-level)]),

        call-node((3, 4), "poll_next()", colors.stream, <stream-call1>),
        simple-edge(<stream-call1>, <stream-result1>),
        call-node((3, 3), "poll_next()", colors.stream, <stream-call2>),
        simple-edge(<stream-call2>, <stream-result2>),
        call-node((3, 2), "poll_next()", colors.stream, <stream-call3>),
        simple-edge(<stream-call3>, <stream-result3>),
        call-node((3, 1), "poll_next()", colors.stream, <stream-call4>),
        simple-edge(<stream-call4>, <stream-result4>),

        result-node((4, 4), "Pending", colors.state, <stream-result1>),
        result-node((4, 3), "Ready(Some(1))", colors.data, <stream-result2>),
        result-node((4, 2), "Pending", colors.state, <stream-result3>),
        result-node((4, 1), "Ready(Some(2))", colors.data, <stream-result4>),

        // Stream high-level side
        title-node((6.5, 5), text(size: 10pt, weight: "bold")[Stream (high-level)]),

        call-node((6, 4), "next().await", colors.ui, <async-call1>),
        simple-edge(<async-call1>, <async-result1>),
        call-node((6, 3), "next().await", colors.ui, <async-call2>),
        simple-edge(<async-call2>, <async-result4>),
        call-node((6, 2), "next().await", colors.ui, <async-call3>),
        simple-edge(<async-call3>, <async-result3>),
        call-node((6, 1), "next().await", colors.ui, <async-call4>),
        simple-edge(<async-call4>, <async-result2>),

        result-node((7, 4), "Some(1)", colors.data, <async-result1>),
        result-node((7, 1), "Some(2)", colors.data, <async-result2>),
        result-node((7, 2), "Some(3)", colors.data, <async-result3>),
        result-node((7, 3), "None", colors.data, <async-result4>),

        // Summary labels
        title-node((0.5, 0), text(size: 8pt)[✓ Always returns immediately]),
        title-node((3.5, 0), text(size: 8pt)[⚠️ May be Pending]),
        title-node((6.5, 0), text(size: 8pt)[✓ Hides polling complexity]),
      )
    }
  ]

]

#slide[
  === A lazy interface

  Similar to `Future`, but yields multiple items over time (when queried / *pulled*):



  ```rust
  trait Stream {
      type Item;

      fn poll_next(self: Pin<&mut Self>, cx: &mut Context<'_>)
          -> Poll<Option<Self::Item>>;
  }
  ```

  Returns `Poll` enum:

  1. `Poll::Pending`: not ready (like `Future`)
  2. `Poll::Ready(_)`:
    - `Ready(Some(item))`: new data is made available
    - `Ready(None)`: currently exhausted (not necessarily the end)
]







#slide[
  == Consumption of streams
]

#slide[
  === Building pipelines

  The basic stream operators of #link("https://docs.rs/futures/latest/futures/stream/trait.StreamExt.html")[`futures::StreamExt`]:

  #align(center)[
    #set text(size: 7pt)
    #diagram(
      node-corner-radius: node-radius,
      node-outset: node-outset,
      spacing: (2.0em, 1.5em),
      edge-stroke: arrow-width,

      // Top row: Rust operator names
      node(
        (0, 2),
        [`iter(0..10)`],
        fill: colors.stream.base,
        stroke: colors.stream.accent + stroke-width,
        shape: circle,
        name: <op-iter>,
      ),
      node(
        (1, 2),
        [`map(*2)`],
        fill: colors.operator.base,
        stroke: colors.operator.accent + stroke-width,
        shape: rect,
        name: <op-map>,
      ),
      node(
        (2, 2),
        [`filter(>4)`],
        fill: colors.operator.base,
        stroke: colors.operator.accent + stroke-width,
        shape: rect,
        name: <op-filter>,
      ),
      node(
        (3, 2),
        [`enumerate`],
        fill: colors.operator.base,
        stroke: colors.operator.accent + stroke-width,
        shape: rect,
        name: <op-enum>,
      ),
      node(
        (4, 2),
        [`take(3)`],
        fill: colors.operator.base,
        stroke: colors.operator.accent + stroke-width,
        shape: rect,
        name: <op-take>,
      ),
      node(
        (5, 2),
        [`skip_while(<1)`],
        fill: colors.operator.base,
        stroke: colors.operator.accent + stroke-width,
        name: <op-skip>,
      ),

      // Middle row: Data values
      node(
        (0, 1),
        [0,1,2,3...],
        fill: colors.data.base,
        stroke: colors.data.accent + stroke-width,
        shape: circle,
        name: <data-iter>,
      ),
      node(
        (1, 1),
        [0,2,4,6...],
        fill: colors.data.base,
        stroke: colors.data.accent + stroke-width,
        shape: rect,
        name: <data-map>,
      ),
      node(
        (2, 1),
        [6,8,10...],
        fill: colors.data.base,
        stroke: colors.data.accent + stroke-width,
        shape: rect,
        name: <data-filter>,
      ),
      node(
        (3, 1),
        [(0,6),(1,8)...],
        fill: colors.data.base,
        stroke: colors.data.accent + stroke-width,
        shape: rect,
        name: <data-enum>,
      ),
      node(
        (4, 1),
        [(0,6),(1,8),(2,10)],
        fill: colors.data.base,
        stroke: colors.data.accent + stroke-width,
        shape: rect,
        name: <data-take>,
      ),
      node(
        (5, 1),
        [(1,8),(2,10)],
        fill: colors.data.base,
        stroke: colors.data.accent + stroke-width,
        name: <data-skip>,
      ),


      // Bottom row: Textual descriptions
      node(
        (0, 0),
        [source],
        shape: circle,
        name: <desc-iter>,
      ),
      node(
        (1, 0),
        [multiply by 2],
        shape: rect,
        name: <desc-map>,
      ),
      node(
        (2, 0),
        [keep if > 4],
        shape: rect,
        name: <desc-filter>,
      ),
      node(
        (3, 0),
        [add index],
        shape: rect,
        name: <desc-enum>,
      ),
      node(
        (4, 0),
        [take first 3],
        shape: rect,
        name: <desc-take>,
      ),
      node((5, 0), [skip while < 1], name: <desc-skip>),

      // Linear flow edges (top row)
      edge(<op-iter>, <op-map>, "->"),
      edge(<op-map>, <op-filter>, "->"),
      edge(<op-filter>, <op-enum>, "->"),
      edge(<op-enum>, <op-take>, "->"),
      edge(<op-take>, <op-skip>, "->"),

      // // Data flow edges (middle row)
      // edge((0, 1), (1, 1), "->", stroke: (dash: "dashed")),
      // edge((1, 1), (2, 1), "->", stroke: (dash: "dashed")),
      // edge((2, 1), (3, 1), "->", stroke: (dash: "dashed")),
      // edge((3, 1), (4, 1), "->", stroke: (dash: "dashed")),
      // edge((4, 1), (5, 1), "->", stroke: (dash: "dashed")),

      // // Description flow edges (bottom row)
      // edge((0, 0), (1, 0), "->", stroke: (dash: "dotted")),
      // edge((1, 0), (2, 0), "->", stroke: (dash: "dotted")),
      // edge((2, 0), (3, 0), "->", stroke: (dash: "dotted")),
      // edge((3, 0), (4, 0), "->", stroke: (dash: "dotted")),
      // edge((4, 0), (5, 0), "->", stroke: (dash: "dotted")),

      // Vertical connections from operators to data
      edge(<op-iter>, <data-iter>, "-", stroke: (dash: "dashed")),
      edge(<op-map>, <data-map>, "-", stroke: (dash: "dashed")),
      edge(<op-filter>, <data-filter>, "-", stroke: (dash: "dashed")),
      edge(<op-enum>, <data-enum>, "-", stroke: (dash: "dashed")),
      edge(<op-take>, <data-take>, "-", stroke: (dash: "dashed")),
      edge(<op-skip>, <data-skip>, "-", stroke: (dash: "dashed")),

      // Vertical connections from data to descriptions
      edge(<data-iter>, <desc-iter>, "-", stroke: (dash: "dashed")),
      edge(<data-map>, <desc-map>, "-", stroke: (dash: "dashed")),
      edge(<data-filter>, <desc-filter>, "-", stroke: (dash: "dashed")),
      edge(<data-enum>, <desc-enum>, "-", stroke: (dash: "dashed")),
      edge(<data-take>, <desc-take>, "-", stroke: (dash: "dashed")),
      edge(<data-skip>, <desc-skip>, "-", stroke: (dash: "dashed")),
    )
  ]

  #align(center)[
    #text(size: 9pt)[
      ```rust
      stream::iter(0..10)
        .map(|x| x * 2)
        .filter(|&x| ready(x > 4))
        .enumerate().take(3).skip_while(|&(i, _)| i < 1)
      ```]

  ]]


#slide[
  === The lesser-known `futures::ready` function

  Filter needs an *async closure* (or closure returning `Future`):
  #text(size: 9pt)[
    #grid(
      columns: (1fr, 1fr),
      gutter: 1em,
      [

        *Option 1*: Async block
        ```rust
        stream.filter(|&x| async move {
          x % 2 == 0
        })
        ```

        *Option 2*: Async closure (Rust 2025+)
        ```rs
        stream.filter(async |&x| x % 2 == 0)
        ```
      ],
      [
        *Option 3*: Wrap sync output with `std::future::ready()`
        ```rust
        stream.filter(|&x| ready(x % 2 == 0))
        ```

        `ready(value)` creates a `Future` that immediately resolves to `value`.
      ],
    )]


  *Bonus*: `future::ready()` is `Unpin`, helping to keep the entire stream pipeline `Unpin` (if the input stream was `Unpin`)!
]




#slide[
  == Example 1: Doubling integer streams (1-1)

]


#slide[


  === Wrapping the original stream by value

  ```rust
  struct Double<InSt> { in_stream: InSt, }

  impl<InSt> Stream for Double<InSt> where Stream: Stream<Item = i32> {
    type Item = InSt::Item;
    fn poll_next(self: Pin<&mut Self>, cx: &mut Context<'_>)
        -> Poll<Option<Self::Item>> {
              Pin::new(self.in_stream) // ⚠️ Will not compile!
                  .poll_next(cx)
                  .map(|x| x * 2)
    }
  }
  ```
  1. `Pin<&mut Self>` blocks access to `self.in_stream`
  2. `Poll::new()` requires `InSt: Unpin`
]


#slide[
  === How to *project* to access `self.in_stream`?
  #text(size: 8pt)[
    #align(center + horizon)[

      #canvas(length: 1.2cm, {
        import draw: *

        // Left: Pin<&mut Self> with nested circles
        hexagon(
          draw,
          (1, 2),
          3,

          colors.pin.base,
          text(fill: colors.pin.accent, size: 8pt, weight: "bold")[`Pin<&mut Double>`],
          (1, 3.5),
        )
        circle((1, 2), radius: 0.8, fill: colors.operator.base, stroke: colors.operator.accent + stroke-width)
        content(
          (1, 3),
          text(size: 7pt, weight: "bold", [`&mut Double`], fill: colors.operator.accent),
          anchor: "center",
        )
        circle((1, 2), radius: 0.4, fill: colors.stream.base, stroke: colors.stream.accent + stroke-width)
        content((1, 2), text(size: 6pt, fill: colors.stream.accent, [`InSt`]), anchor: "center")

        // First arrow with .get_mut() label
        line((2.7, 2), (3.5, 2), mark: (end: "barbed"), stroke: colors.state.accent + arrow-width)
        content((3, 2.4), text(size: 7pt, fill: colors.stream.accent, [?]), anchor: "center")

        // Middle: Just InSt
        circle((4, 2), radius: 0.4, fill: colors.stream.base, stroke: colors.stream.accent + stroke-width)
        content((4, 2), text(size: 6pt, fill: colors.stream.accent, [`InSt`]), anchor: "center")

        // Second arrow with Pin::new() label
        line((4.5, 2), (5.3, 2), mark: (end: "barbed"), stroke: colors.state.accent + arrow-width)
        content((5, 2.4), text(size: 6pt, text(fill: colors.stream.accent)[?]), anchor: "center")

        // Right: Pin<&mut InSt>
        hexagon(draw, (6.5, 2), 2, colors.pin.base, text(fill: colors.pin.accent)[`Pin<&mut InSt>`], (6.5, 3.3))
        circle((6.5, 2), radius: 0.4, fill: colors.stream.base, stroke: colors.stream.accent + stroke-width)
        content((6.5, 2), text(size: 6pt, fill: colors.stream.accent)[`InSt`], anchor: "center")

        // Third arrow with next().await label
        line((7.5, 2), (8.5, 2), mark: (end: "barbed"), stroke: colors.stream.accent + arrow-width)
        content((8, 2.4), text(size: 6pt, fill: colors.stream.accent, [`Stream::poll_next()`]), anchor: "north-west")
      })

      #v(1em)

      // Color legend
      #grid(
        columns: (auto, auto, auto),
        column-gutter: 2em,
        row-gutter: 0.8em,

        // Pin colors
        rect(width: 1.2em, height: 0.8em, fill: colors.pin.base, stroke: colors.pin.accent + 0.8pt),
        text(size: 8pt)[Pin types],
        [],

        // Operator colors
        rect(width: 1.2em, height: 0.8em, fill: colors.operator.base, stroke: colors.operator.accent + 0.8pt),
        text(size: 8pt)[Operators/structs],
        [],

        // Stream colors
        rect(width: 1.2em, height: 0.8em, fill: colors.stream.base, stroke: colors.stream.accent + 0.8pt),
        text(size: 8pt)[Streams/inner types],
        [],
      )

    ]
  ]]



#slide[
  === `!Unpin` defends against unsafe moves

  #text(size: 9pt)[

    #align(center)[
      #grid(
        rows: (auto, auto),
        row-gutter: 1.5em,

        // Row 1: Unpin Bird example
        [
          #canvas(length: 1cm, {
            import draw: *

            // Left: Free bird (can move)
            content((1, 2.5), text(size: 2em, "🐦"), anchor: "center")
            content((1, 2.0), text(size: 8pt, weight: "bold", [`Unpin` Bird]), anchor: "center")
            content((1, 1.6), text(size: 6pt, "✅ Can move"), anchor: "center")

            // Pin::new() arrow (left to right)
            line((1.8, 2.7), (7.2, 2.7), mark: (end: "barbed"), stroke: colors.pin.base + arrow-width)
            content(
              (4.5, 3.0),
              text(size: 7pt, weight: "bold", fill: colors.pin.accent, [`Pin::new()`]),
              anchor: "center",
            )
            content((4.5, 2.4), text(size: 6pt, "Always safe"), anchor: "center")

            // Pin::get_mut() arrow (right to left)
            line((7.2, 1.7), (1.8, 1.7), mark: (end: "barbed"), stroke: colors.pin.base + arrow-width)
            content(
              (4.5, 2.0),
              text(size: 7pt, weight: "bold", fill: colors.pin.accent, [`Pin::get_mut()`]),
              anchor: "center",
            )
            content((4.5, 1.4), text(size: 6pt, [if `T: Unpin`]), anchor: "center")

            // Right: Pin<&mut Bird> with caged bird
            hexagon(
              draw,
              (8.5, 2.3),
              2.5,
              colors.pin.base,
              text(fill: colors.pin.accent)[`Pin<&mut Bird>`],
              (8.5, 3.7),
            )
            content((8.5, 2.6), text(size: 2em, "🐦"), anchor: "center")
            content((8.5, 2.0), text(size: 8pt, weight: "bold", [`Unpin` Bird]), anchor: "center")
            content((8.5, 1.6), text(size: 6pt, [Can be\ uncaged]), anchor: "center")
          })
        ],

        // Row 2: !Unpin Tiger example
        [
          #canvas(length: 1cm, {
            import draw: *

            // Left: Free tiger (!Unpin, dangerous to move)
            content((1, 2.8), text(size: 3em, "🐅"), anchor: "center")
            content((1, 2.0), text(size: 8pt, weight: "bold", [`!Unpin` Tiger]), anchor: "center")
            content((1, 1.6), text(size: 6pt, "⚠️ Dangerous to move"), anchor: "center")

            // Cross mark (blocked operation)
            line((2.5, 2.8), (6.5, 1.8), stroke: colors.error.accent + arrow-width)
            line((2.5, 1.8), (6.5, 2.8), stroke: colors.error.accent + arrow-width)

            content((4.5, 1.5), text(size: 6pt, fill: colors.error.accent, [❌ Not safe]), anchor: "center")

            content(
              (4.5, 2.5),
              text(size: 9pt, weight: "bold", [`Pin::get_mut()` \ `Pin::new()`]),
              anchor: "center",
            )

            // Right: Pin<&mut Tiger> with caged tiger (permanently caged)
            hexagon(
              draw,
              (8.5, 2.3),
              2.5,
              colors.pin.base,
              text(fill: colors.pin.accent)[`Pin<&mut Tiger>`],
              (8.5, 3.7),
            )
            content((8.5, 2.8), text(size: 3em, "🐅"), anchor: "center")
            content((8.5, 2.0), text(size: 8pt, weight: "bold", [`!Unpin` Tiger]), anchor: "center")
            content((8.5, 1.6), text(size: 6pt, [Can't be\ uncaged]), anchor: "center")
          })
        ],
      )
    ]


  ]
]


#slide[
  === Why `Box<T>: Unpin`?
  #text(size: 8pt)[
    #align(center)[
      #canvas(length: 1.2cm, {
        import draw: *

        // Stack - Box pointer
        rect(
          (1, 3),
          (4, 5),
          fill: colors.ui.base,
          stroke: colors.ui.accent + stroke-width,
          radius: node-radius,
        )
        content((2.5, 5.2), text(size: 9pt, weight: "bold", "Stack"), anchor: "center")
        content((2.5, 4.7), text(size: 8pt, [`Box<InSt>`]), anchor: "center")
        rect(
          (1.9, 3.5),
          (3, 4.5),
          fill: colors.neutral.base,
          stroke: colors.neutral.accent + stroke-width,
        )
        content((2.5, 4.), text(size: 8pt, [pointer \ `0X1234`]), anchor: "center")

        content((2.5, 3.3), text(size: 7pt, "✅ Safe to move"), anchor: "center")

        // Arrow to heap
        line((3.1, 4), (7.3, 3.7), mark: (end: "barbed"), stroke: colors.operator.accent + arrow-width)
        content((5.25, 4.3), text(size: 8pt, [dereferences to]), anchor: "center")

        // Tiger pointing into heap
        content((11.5, 5.0), text(size: 3em, "🐅"), anchor: "center")
        content((11.5, 4.0), text(size: 8pt, weight: "bold", [`!Unpin` Tiger]), anchor: "center")
        // Smooth curved arrow going into triangle center
        arc(
          (10.5, 5.2),
          start: 60deg,
          stop: 170deg,
          radius: 1.5,
          mark: (end: "barbed"),
          stroke: colors.error.accent + arrow-width,
        )

        // Heap - actual stream (triangle laying flat)
        line((6.0, 3), (10, 3), stroke: colors.operator.accent + stroke-width) // base
        line((6.0, 3), (8, 5), stroke: colors.operator.accent + stroke-width) // left side
        line((10, 3), (8, 5), stroke: colors.operator.accent + stroke-width) // right side

        content((8, 5.3), text(size: 9pt, weight: "bold", "Heap"), anchor: "center")
        content((8.4, 3.8), text(size: 6pt, [`0X1234`]), anchor: "center")
        content((8.4, 3.5), text(size: 8pt, [`InSt (!Unpin)`]), anchor: "center")
        content((8.3, 3.2), text(size: 7pt, "📌 Fixed address"), anchor: "center")
      })
    ]


    1. Put your `!Unpin` type on the heap with `Box::new()`\
      (Heap content stays at fixed address)
    2. The output of `Box::new(tiger)` is just a pointer \
      (Moving pointers is safe)
    3. `Box<X>: Deref<Target = X>`, so `Box<InSt>` *behaves like `InSt`*\
  ]
  ```rs
  struct Double {in_stream: Box<InSt>}: Unpin
  ```
]

#slide[



  === Putting it all together visually

  ... and wrapping it around the boxed stream:

  #align(center)[
    #canvas(length: 1.2cm, {
      import draw: *

      // Left: Pin<&mut Double> with large wrapper - simplified but clear
      hexagon(draw, (2, 4), 4.5, colors.pin.base, text(fill: colors.pin.accent)[`Pin<&mut Double>`], (2, 6.2))
      circle((2, 4), radius: 1.5, fill: colors.operator.base, stroke: colors.operator.accent + stroke-width)
      content((2, 5.7), text(size: 7pt, weight: "bold", fill: colors.operator.accent)[`&mut Double`], anchor: "center")
      content((2, 5.2), text(size: 6pt, weight: "bold")[`Box<InSt>`], anchor: "center")

      // Inner stream representation
      rect(
        (2 - 0.6, 4 - 0.6),
        (2 + 0.6, 4 + 0.6),
        fill: colors.neutral.base,
        stroke: colors.neutral.accent + stroke-width,
      )
      circle((2, 4), radius: 0.5, fill: colors.stream.base, stroke: colors.stream.accent + stroke-width)
      content((2, 4), text(size: 6pt, fill: colors.stream.accent)[`InSt:` \ `!Unpin`], anchor: "center")

      // Tiger warning
      content((4.8, 5.9), text(size: 3em, "🐅"), anchor: "center")
      arc(
        (4.0, 5.8),
        start: 80deg,
        stop: 170deg,
        radius: 1.5,
        mark: (end: "barbed"),
        stroke: colors.error.accent + arrow-width,
      )

      // Middle: &mut Double
      circle((6.5, 4), radius: 1, fill: colors.operator.base, stroke: colors.operator.accent + stroke-width)
      content(
        (6.5, 5.2),
        text(size: 7pt, weight: "bold", fill: colors.operator.accent)[`&mut Double`],
        anchor: "center",
      )
      content((6.5, 4.7), text(size: 7pt, weight: "bold")[`Box<InSt>`], anchor: "center")

      rect(
        (6.5 - 0.45, 4 - 0.45),
        (6.5 + 0.45, 4 + 0.45),
        fill: colors.neutral.base,
        stroke: colors.neutral.accent + stroke-width,
      )
      circle((6.5, 4), radius: 0.3, fill: colors.stream.base, stroke: colors.stream.accent + stroke-width)
      content((6.5, 4), text(size: 5pt, fill: colors.stream.accent)[`InSt`], anchor: "center")

      // Right: Pin<&mut InSt>
      hexagon(draw, (9.5, 4.0), 2.5, colors.pin.base, "", (9.5, 5.8))
      content((9.5, 5.5), text(size: 7pt, weight: "bold", fill: colors.pin.accent)[`Pin<&mut InSt>`], anchor: "center")
      content((9.5, 4.7), text(size: 7pt, weight: "bold")[`&mut Box<InSt>`], anchor: "center")

      rect(
        (9.5 - 0.45, 4 - 0.45),
        (9.5 + 0.45, 4 + 0.45),
        fill: colors.neutral.base,
        stroke: colors.neutral.accent + stroke-width,
      )
      circle((9.5, 4), radius: 0.3, fill: colors.stream.base, stroke: colors.stream.accent + stroke-width)
      content((9.5, 4), text(size: 5pt, fill: colors.stream.accent)[`InSt`], anchor: "center")

      // Operation arrows with labels
      line((4.4, 4), (5.4, 4), mark: (end: "barbed"), stroke: colors.state.accent + arrow-width)
      content(
        (4.9, 4.5),
        text(size: 6pt, weight: "bold", fill: colors.pin.accent)[`Pin::get_mut()`],
        anchor: "center",
      )
      content((4.9, 3.5), text(fill: colors.error.accent, size: 6pt)[if `Double:` \ `Unpin`], anchor: "center")

      line((7.1, 4), (8.9, 4), mark: (end: "barbed"), stroke: colors.state.accent + arrow-width)
      content((7.9, 4.5), text(size: 6pt, weight: "bold", fill: colors.pin.accent)[`Pin::new()`], anchor: "center")

      line((11.0, 4), (11.7, 4), mark: (end: "barbed"), stroke: colors.stream.accent + arrow-width)
      content(
        (11.5, 4.5),
        text(size: 6pt, weight: "bold", fill: colors.stream.accent)[`Stream::poll_next()`],
        anchor: "center",
      )
    })
  ]


]




#slide[
  === Complete `Stream` trait implementation


  #text(size: 9pt)[
    We can call `get_mut()` to get `&mut Double<InSt>` safely:



    ```rust
    impl<InSt> Stream for Double<InSt>
    where InSt: Stream<Item = i32>
    {
        fn poll_next(self: Pin<&mut Self>, cx: &mut Context<'_>)
            -> Poll<Option<Self::Item>>
        {
            // this: &mut Double<InSt>
            let this = self.get_mut(); // Safe because Double is Unpin
            match Pin::new(&mut this.in_stream).poll_next(cx) {
                Poll::Ready(r) => Poll::Ready(r.map(|x| x * 2)),
                Poll::Pending => Poll::Pending,
            }

        }
    }
    ```
  ]
]





#slide[
  === Distributing your operator

  Create an extension trait to add `.double()` method to any integer stream:

  ```rust
  trait DoubleStream: Stream {
      fn double(self) -> Double<Self>
      where Self: Sized + Stream<Item = i32>,
      { Double::new(self) }
  }
  ```

  Add a *blanket `impl`* that automatically implements `DoubleStream` for any `Stream<Item = i32>`:

  ```rs
  impl<S> DoubleStream for S where S: Stream<Item = i32> {}
  ```

  *Important*: A blanket implementation should be provided by you!

]

#slide[
  === Users just add dependency + import

  Super simple for users to adopt your custom operators:

  ```toml
  [dependencies]
  double-stream = "1.0"
  ```
  The `DoubleStream` trait must be in scope to use `.double()`:
  ```rust
  use double_stream::DoubleStream;  // Trait in scope

  let doubled = stream::iter(1..=5).double();  // Now works!
  ```
  *Compositionality of traits* (versus traditional OOP) shines!
]

#slide[

  == Example 2: Cloning streams at run-time (1-N)
]



#slide[
  === Problem: most streams aren't `Clone`


  #text(size: 9pt)[
    Latency may need to processed by different async tasks:


    ```rust
    let tcp_stream = TcpStream::connect("127.0.0.1:8080").await?;
    let latency = tcp_stream.latency(); // Stream<Item = Duration>
    let latency_clone = latency.clone(); // Error! Can't clone stream
    spawn(async move { process_for_alice(latency).await; });
    spawn(async move { process_for_bob(latency_clone).await; });
    ```



    *Solution*: Create a _*stream operator*_ that clones streams.

    (Requirement: `Stream<Item: Clone>`, so we can clone the items)

    Approach:

    1. Implement forking the input stream
    2. Implement cloning on forked streams
    3. Package as crate with blanket impl
  ]]

#slide[
  === Rough architecture of #link("https://crates.io/crates/clone-stream")[`clone-stream`]
  #set text(size: 9pt)
  #align(center + horizon)[
    #{
      let stream-node(pos, text, color, name) = node(
        pos,
        [#text],
        fill: color.base,
        stroke: color.accent + stroke-width,
        name: name,
      )
      let queue-item(pos, char, consumed, name) = node(
        pos,
        if consumed { [#strike[#char]] } else { [#char] },
        fill: if consumed { colors.neutral.base.lighten(90%) } else { colors.neutral.base.darken(10%) },
        stroke: colors.neutral.accent + stroke-width,
        shape: fletcher.shapes.rect,
        name: name,
      )
      let data-item(pos, char, name) = node(
        pos,
        [#char],
        fill: colors.data.base,
        stroke: colors.data.accent + stroke-width,
        shape: fletcher.shapes.circle,
        name: name,
      )
      let labeled-flow(from, to, label, color, ..args) = edge(
        from,
        to,
        [#label],
        "->",
        stroke: color.accent + arrow-width,
        ..args,
      )
      let simple-flow(from, to, color) = edge(from, to, "->", stroke: color.accent + stroke-width)
      let queue-link(from, to, label) = edge(
        from,
        to,
        text(fill: colors.neutral.accent)[#label],
        "--",
        stroke: colors.neutral.accent + stroke-width,
      )

      diagram(
        node-corner-radius: node-radius,
        edge-stroke: arrow-width,
        node-outset: node-outset,
        spacing: (6em, 1em),

        // Main flow
        stream-node((0, 1), [`InputStream`], colors.stream, <input-stream>),
        labeled-flow(<input-stream>, <fork>, [`.fork()`], colors.stream, label-pos: 0.4),

        stream-node((1, 1), [`Fork`], colors.operator, <fork>),
        labeled-flow(<fork>, <bob>, [`.clone()`], colors.ui, bend: -20deg),
        labeled-flow(<fork>, <alice>, [`.clone()`], colors.ui, bend: 20deg),
        queue-link(<fork>, <queue-a-consumed>, "queue"),

        stream-node((2, 2), "Bob", colors.state, <bob>),
        simple-flow(<bob>, <bob-a>, colors.operator),

        stream-node((2, 0), "Alice", colors.ui, <alice>),
        simple-flow(<alice>, <alice-a>, colors.operator),

        // Queue items
        queue-item((3, 1), "'a'", true, <queue-a-consumed>),
        queue-item((3.5, 1), "'b'", true, <queue-b-consumed>),
        queue-item((4, 1), "'c'", false, <queue-c>),
        queue-item((4.5, 1), "'d'", false, <queue-d>),

        // Data items
        data-item((3, 3), "'a'", <bob-a>),
        data-item((3.5, 3), "'b'", <bob-b>),
        data-item((4, 3), "'c'", <bob-c>),
        data-item((3, -1), "'a'", <alice-a>),
        data-item((3.5, -1), "'b'", <alice-b>),
      )
    }
  ]

  // Horizontal color legend
  #align(center)[
    #grid(
      columns: (auto, auto, auto, auto, auto, auto, auto, auto),
      column-gutter: 1.5em,

      rect(width: 1em, height: 0.6em, fill: colors.stream.base, stroke: colors.stream.accent + 0.5pt), [Streams],

      rect(width: 1em, height: 0.6em, fill: colors.operator.base, stroke: colors.operator.accent + 0.5pt), [Operators],

      rect(width: 1em, height: 0.6em, fill: colors.state.base, stroke: colors.state.accent + 0.5pt), [Consumers],

      rect(width: 1em, height: 0.6em, fill: colors.data.base, stroke: colors.data.accent + 0.5pt), [Data],
    )
  ]
]








#slide[

  === Polling and waking flow
  #set text(size: 7pt)
  #align(center)[
    #diagram(
      node-corner-radius: node-radius,
      node-outset: node-outset,
      edge-stroke: arrow-width,
      spacing: (3em, 2.5em),

      // Input stream at bottom
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

      // Alice - sleeping after first poll
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

      // Bob - actively polling
      node(
        (2, 3),
        [Bob\ 🔍 Polling],
        fill: colors.state.base,
        stroke: colors.stream.accent + stroke-width,
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
      edge(<poll-bob>, <poll-alice>, [5. `wake()` Alice], "->", stroke: colors.state.accent + arrow-width, bend: 40deg),

      // Data item that will be shared
      node((1, 1.5), [data 'x'], fill: colors.data.base, stroke: colors.data.accent + stroke-width, name: <poll-data>),
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

]


#slide[
  === Complexity grows with thousands of clones

  Careful state management:


  #grid(
    columns: (1fr, 1fr),
    column-gutter: 2em,
    [
      *Inherent async challenges:*
      - Dynamic clone lifecycle
      - Memory leaks from orphaned wakers
      - Cleanup when tasks abort
      - Task coordination complexity
    ],
    [
      *Stream-specific challenges:*
      - Ordering guarantees across clones
      - Backpressure with slow consumers
      - Sharing mutable state safely
      - Avoiding duplicate items
    ],
  )


  #align(center)[
    #canvas(length: 1cm, {
      import draw: *


      // Multiple clones at different positions
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


#slide[
  === Meaningful operator testing

  #text(size: 8pt)[




    #grid(
      columns: (1fr, 1fr),
      gutter: 1em,
      [
        When you build your own:

        1. Pick an async run-time.
        2. Define synchronization points with `Barrier`:
          ```rs
          let b1 = Arc::new(Barrier::new(3));
          let b2 = b1.clone(); // Second output
          let b3 = b1.clone(); // For input


          ```

        3. Apply your custom operator
          ```rs
          let stream1 = create_test_stream()
              .your_custom_operator();
          let stream2 = stream1.clone();
          ```

          Can be used for *benchmarks* too (use `criterion`).



      ],
      [
        Do not use `sleep(1ms)` in tests! (Use bariers!)

        ```rs
        try_join_all([
            spawn(async move {
                setup_task().await;
                b1.wait().await;
                stream1.collect().await;
            }),
            spawn(async move {
                setup_task().await;
                b2.wait().await;
                stream2.collect().await;
            }),
            spawn(async move {
                b3.wait().await;
                send_to_stream().await;
            })
        ]).await.unwrap();
        ```
      ],
    )


  ]
]


#slide[
  === State machines for physically-separated components

  #align(center + horizon)[
    #{
      let workflow-step(pos, num, title, items, color, name) = node(
        pos,
        align(left, text(size: 7pt, [
          *#num. #title*
          #for item in items [
            - #item
          ]
        ])),
        fill: color.base,
        stroke: color.accent + stroke-width,
        name: name,
      )

      let labeled-edge(from, to, label, ..args) = {
        if label != none {
          edge(from, to, text(size: 6pt)[#label], "->", ..args)
        } else {
          edge(from, to, "->", ..args)
        }
      }

      set text(size: 8pt)
      diagram(
        node-stroke: stroke-width,
        node-corner-radius: node-radius,
        node-outset: node-outset,
        edge-stroke: arrow-width,
        spacing: (3em, 2em),

        workflow-step(
          (1, 3),
          "1",
          "Write 'sleepless' tests",
          ("Order preservation", "All items received", "Use `Barrier`s, not `sleep()`"),
          colors.stream,
          <write-tests>,
        ),
        labeled-edge(<write-tests>, <analyze-states>, none),

        workflow-step(
          (3, 3),
          "2",
          "Analyze states",
          ("Minimal state set", "Clean transitions", "Avoid `Option`s in states"),
          colors.data,
          <analyze-states>,
        ),
        labeled-edge(<analyze-states>, <implement>, none, bend: -15deg),

        workflow-step(
          (2, 2),
          "3",
          "Implement",
          ("State machine", "Transitions", "Waker management"),
          colors.state,
          <implement>,
        ),
        labeled-edge(<implement>, <run-tests>, none, bend: -15deg),

        workflow-step((1, 1), "4", "Run tests", ("Tests pass?",), colors.ui, <run-tests>),
        labeled-edge(<run-tests>, <benchmarks>, "✓ pass"),
        labeled-edge(<run-tests>, <implement>, "✗ fail", stroke: colors.error.accent + stroke-width, bend: -30deg),

        workflow-step(
          (3, 1),
          "5",
          "Benchmarks",
          ("Use `criterion`", "Measure performance", "Optimize hotspots"),
          colors.operator,
          <benchmarks>,
        ),
      )
    }
  ]





]


#slide[

  === #link(
    "https://github.com/wvhulle/clone-stream/blob/main/src/states.rs",
  )[State machine of `clone-stream`]

  Each clone maintains its own #link("https://github.com/wvhulle/clone-stream/blob/main/src/states.rs")[state]:


  #align(center + horizon)[
    #{
      let state-node(pos, title, desc, color, name) = node(
        pos,
        stack(
          dir: ttb,
          spacing: 0.5em,
          text(size: 8pt, weight: "bold")[#title],
          text(size: 6pt, style: "italic")[#desc],
        ),
        fill: color.base,
        stroke: color.accent + stroke-width,
        name: name,
      )

      let transition(from, to, label, ..args) = edge(
        from,
        to,
        text(size: 6pt)[#label],
        "->",
        ..args,
      )

      diagram(
        node-stroke: stroke-width,
        node-corner-radius: node-radius,
        node-inset: 1em,
        edge-stroke: arrow-width,
        node-outset: node-outset,
        spacing: (4em, 2.5em),

        // Core states from actual implementation
        state-node((0, 1), "PollingBaseStream", "Actively polling input stream", colors.state, <polling-base-stream>),
        transition(
          <polling-base-stream>,
          <processing-queue>,
          [base ready,\ queue item],
          label-pos: 0.5,
          label-anchor: "north",
          label-sep: 0em,
        ),
        transition(
          <polling-base-stream>,
          <pending>,
          "base pending",
          bend: -15deg,
          label-pos: 0.5,
          label-sep: 0.5em,
          label-anchor: "west",
        ),

        state-node((2, 1), "ProcessingQueue", "Reading from shared buffer", colors.data, <processing-queue>),
        transition(<processing-queue>, <polling-base-stream>, [queue empty,\ poll base], bend: 40deg, label-pos: 0.3),

        state-node((1, 0), "Pending", "Waiting with stored waker", colors.ui, <pending>),
        transition(<pending>, <polling-base-stream>, "woken", bend: -15deg, label-pos: 0.7, label-sep: 1em),
        transition(<pending>, <processing-queue>, "queue ready", bend: 15deg, label-pos: 0.7),
      )
    }
  ]



]




#slide[
  == General principles
]



#slide[
  === Before building your own operators


  1. For simple state machines: `futures::stream::unfold` constructor
  2. Streams from scratch: `async-stream` crate with `yield`

  Otherwise, import an operator from:

  #grid(
    columns: (1fr, 1fr),
    inset: 0.5em,

    gutter: 2em,
    [
      *Standard*: #link("https://docs.rs/futures/latest/futures/stream/trait.StreamExt.html")[`futures::StreamExt`]

      - 5.7k ⭐, 342 contributors
      - Since 2016, actively maintained
      - Latest: v0.3.31 (Oct 2024)
    ],
    [
      *RxJs-style*: #link("https://crates.io/crates/futures-rx")[`futures-rx`]

      - Reactive operators & specialized cases
      - 8 ⭐, small project
      - Since Dec 2024, very new
      - Fills gaps in `futures::StreamExt`
    ],
  )

  Build custom operators *only when no existing operator fits*!
]


#slide[
  === Last recommendation


  #align(horizon)[
    #grid(
      columns: (1fr, 1fr, 1fr),
      gutter: 2em,
      [
        *Don't overuse streams:*
        - Keep pipelines short
        - Only _physical async data flow_
      ],
      [
        *Separation of concerns:*
        - Modular functions
        - Descriptive names
        - Split long functions
      ],
      [
        *Use objective targets:*
        - Correctness unit tests
        - Statistically relevant benchmarks
      ],
    )

    #v(2em)


    "When you have a hammer, everything looks like a nail." _— Abraham Maslow_

    "Perfection is achieved, not when there is nothing more to add, but when there is *nothing left to take away*." — _Antoine de Saint-Exupéry_

  ]]





#slide[


  #align(center)[

    #text(size: 1em)[Any questions?]



    #text(size: 2em)[Thank you!]


    #rect(fill: colors.operator.base, stroke: colors.operator.accent + stroke-width, radius: node-radius)[
      *Want to learn Rust in-depth?*

      Join my 7-week course _*"Creating Safe Systems in Rust"*_ in Ghent starting November 2025.

      Register at #link("https://willemvanhulle.tech")[willemvanhulle.tech] (link at bottom of page)
    ]
  ]

  #v(2em)

  - Contact me: #link("mailto:willemvanhulle@protonmail.com") \
  - These slides: #link("https://github.com/wvhulle/streams-eurorust-2025")[github.com/wvhulle/streams-eurorust-2025]
]


#slide[
  == Bonus slides
]


#slide[
  === The meaning of `Ready(None)`

  #align(horizon + center)[
    #grid(
      columns: (1fr, 1fr),
      gutter: 3em,
      [
        #align(center)[*Regular Stream*]

        "No items *right now*"

        (_Stream might yield more later_)
      ],
      [
        #align(center)[*Fused Stream*]

        "No items *ever again*"

        (_Stream is permanently done_)
      ],
    )
  ]]



#slide[

  === 'Fusing' streams and futures



  #align(center + horizon)[
    #let draw-arrow(multiple: false, fused: false, color) = {
      canvas(length: 0.8cm, {
        import draw: *

        if multiple {
          // Stream: arrow with multiple dashes
          if fused {
            line((-0.8, 0), (0.6, 0), stroke: color + arrow-width)
            line((0.8, -0.3), (0.8, 0.3), stroke: color + (arrow-width * 2))
          } else {
            line((-0.8, 0), (0.8, 0), stroke: color + arrow-width, mark: (end: "barbed"))
          }
          for i in range(if fused { 4 } else { 3 }) {
            let dash-x = -0.6 + i * 0.4
            line((dash-x, -0.15), (dash-x, 0.15), stroke: color + (arrow-width * 1.5))
          }
        } else {
          // Future: arrow with single dash
          line((-0.8, 0), (0.3, 0), stroke: color + arrow-width)
          line((0, -0.2), (0, 0.2), stroke: color + (arrow-width * 1.5))
          if fused {
            line((0.3, 0), (0.6, 0), stroke: color + arrow-width)
            line((0.8, -0.3), (0.8, 0.3), stroke: color + (arrow-width * 2))
          } else {
            line((0.3, 0), (0.8, 0), stroke: color + arrow-width, mark: (end: "barbed"))
          }
        }
      })
    }

    #grid(
      columns: (auto, 1fr, 1fr, 2fr),
      rows: (auto, auto, auto, auto, auto),
      gutter: 2em,
      [], [*`Future`*], [*`Stream`*], [*Meaning*],
      [*Regular*],
      [#draw-arrow(multiple: false, fused: false, blue)],
      [#draw-arrow(multiple: true, fused: false, green)],
      [May continue],

      [*Fused*], [*`FusedFuture`*], [*`FusedStream`*], [`is_terminated()` method],

      [*Fused*],
      [#draw-arrow(multiple: false, fused: true, blue)],
      [#draw-arrow(multiple: true, fused: true, green)],
      [Done permanently],

      [*Fused value*], [`Pending`], [`Ready(None)`], [Final value],
    )
  ]
]




#slide[
  === Flatten a *finite collection* of `Stream`s

  A finite collection of `Stream`s = `IntoIterator<Item: Stream>`


  ```rust
  let streams = vec![
      stream::iter(1..=3),
      stream::iter(4..=6),
      stream::iter(7..=9),
  ];

  let merged = stream::select_all(streams);
  ```

  1. Creates a `FuturesUnordered` of the streams
  2. Polls all streams concurrently
  3. Yields items as they arrive
]

#slide[
  === Flattening an infinite stream

  *Beware!*: `flatten()` on a stream of infinite streams will never complete!

  ```rs
  let infinite_streams = stream::unfold(0, |id| async move {
      Some((stream::iter(id..), id + 1))
  });
  let flat = infinite_streams.flatten();
  ```

  Instead, *buffer streams* concurrently with `flatten_unordered()`.

  ```rust
  let requests = stream::unfold(0, |id| async move {
      Some((fetch_stream(format!("/api/data/{}", id)), id + 1))
  });
  let flat = requests.flatten_unordered(Some(10));
  ```


]





#slide[
  === More `Stream` features to explore

  Many more advanced topics await:

  - *Boolean operations*: `any`, `all`
  - *Async operations*: `then`
  - *`Sink`s*: The write-side counterpart to `Stream`s

  #align(center)[
    #{
      let endpoint(pos, text, color, name) = node(
        pos,
        [#text],
        fill: color.base,
        stroke: color.accent + stroke-width,
        name: name,
      )
      let data-item(pos, char, name) = node(
        pos,
        [#char],
        fill: colors.data.base,
        stroke: colors.data.accent + stroke-width,
        shape: fletcher.shapes.circle,
        name: name,
      )
      let label(pos, text) = node(pos, [#text], fill: none, stroke: none)

      diagram(
        node-corner-radius: node-radius,
        node-stroke: stroke-width,
        node-outset: node-outset,
        edge-stroke: arrow-width,
        spacing: (6em, 2em),
        {
          endpoint((0, 1), "Stream", colors.stream, <stream>)
          data-item((1, 1), "'a'", <data-a>)
          data-item((1.5, 1), "'b'", <data-b>)
          data-item((2, 1), "'c'", <data-c>)
          endpoint((3, 1), "Sink", colors.ui, <sink>)

          edge(<stream>, <data-a>, "-")
          edge(<data-a>, <data-b>, "-")
          edge(<data-b>, <data-c>, "-")
          edge(<data-c>, <sink>, "->", label: [`.forward()`])

          label((0, 1.7), "Read side")
          label((3, 1.7), "Write side")
        },
      )
    }
  ]


]



#slide[
  === The `Stream` trait: a lazy query interface

  *The `Stream` trait is NOT the stream itself* - it's just a lazy frontend to query data.

  #v(1em)

  #grid(
    columns: (1fr, 1fr),
    column-gutter: 2em,
    [
      *What `Stream` trait does:*
      - Provides uniform `.poll_next()` interface
      - Lazy: only responds when asked
      - Doesn't drive or produce data itself
      - Just queries whatever backend exists
    ],
    [
      *What actually drives streams:*
      - TCP connections receiving packets
      - File I/O completing reads
      - Timers firing
      - Hardware signals
      - Channel senders pushing data
    ],
  )
]


#slide[

  === The _'real'_ stream drivers

  #align(center + horizon)[
    #canvas(length: 1cm, {
      import draw: *

      // Leaf streams (drivers) at bottom
      rect(
        (0.5, 0.5),
        (7.5, 2),
        fill: colors.operator.base,
        stroke: colors.operator.accent + stroke-width,
        radius: node-radius,
      )
      content((4, 1.6), text(size: 9pt, weight: "bold", "Leaf Streams (Real Drivers)"), anchor: "center")
      content((4, 1.1), text(size: 7pt, "TCP, Files, Timers, Hardware, Channels"), anchor: "center")

      // Data flow upward
      line((4, 2.2), (4, 2.8), stroke: colors.operator.accent + arrow-width, mark: (end: "barbed"))
      content((5.2, 2.5), text(size: 7pt, "Data pushed up"), anchor: "center")

      // Stream trait interface at top
      rect(
        (1, 3),
        (7, 4),
        fill: colors.stream.base,
        stroke: colors.stream.accent + stroke-width,
        radius: node-radius,
      )
      content((4, 3.7), text(size: 9pt, weight: "bold", "Stream Trait Interface"), anchor: "center")
      content((4, 3.3), text(size: 7pt, "Lazy: .poll_next() only responds when called"), anchor: "center")
    })
  ]

  `Stream` trait just provides a *uniform way to query* - it doesn't create or drive data flow.
]



#slide[

  === Possible inconsistency


  ```rs
  trait Stream {
      type Item;

      fn poll_next(self: Pin<&mut Self>, cx: &mut Context)
          -> Poll<Option<Self::Item>>
  }
  ```

  #rect(inset: 5mm, fill: colors.error.base, stroke: colors.error.accent + stroke-width, radius: node-radius)[
    What about Rust rule `self` needs to be `Deref<Target=Self>`?
  ]


  `Pin<&mut Self>` only implements `Deref<Target=Self>` for `Self: Unpin`.

  Problem? No, `Pin` is an exception in the compiler.
]



#slide[
  === Why does Rust bring to the table?

  Reactivity in garbage collected languages is *completely different* from Rust's ownership system

  #align(center)[
    #canvas(length: 1cm, {
      import draw: *

      // TypeScript side
      rect(
        (0.5, 1),
        (3.5, 4),
        fill: colors.operator.base,
        stroke: colors.operator.accent + stroke-width,
        radius: node-radius,
      )
      content((2, 3.5), text(size: 8pt, weight: "bold", "TypeScript"), anchor: "center")

      // GC cleanup
      circle((2, 2.8), radius: 0.4, fill: colors.state.base, stroke: colors.state.accent + stroke-width)
      content((2, 2.8), text(size: 6pt, "GC"), anchor: "center")


      // Data flowing freely - simplified dots
      for i in range(3) {
        let x = 1.4 + i * 0.3
        circle((x, 2.0), radius: 0.08, fill: colors.stream.accent)
      }
      content((2, 1.4), text(size: 6pt, "Put anything\nanywhere"), anchor: "center")

      // VS separator
      content((4.5, 2.5), text(size: 12pt, weight: "bold", "vs"), anchor: "center")

      // Rust side
      rect(
        (5.5, 1),
        (8.5, 4),
        fill: colors.ui.base,
        stroke: colors.ui.accent + stroke-width,
        radius: node-radius,
      )
      content((7, 3.5), text(size: 8pt, weight: "bold", "Rust"), anchor: "center")

      // Ownership constraints
      rect(
        (6.2, 2.6),
        (7.8, 3.2),
        fill: colors.ui.base,
        stroke: colors.ui.accent + stroke-width,
        radius: node-radius,
      )
      content((7, 2.9), text(size: 6pt, "Ownership\nRules"), anchor: "center")

      // Constrained data flow
      line((6.2, 2.2), (6.8, 2.2), stroke: colors.stream.accent + arrow-width)
      line((6.8, 2.2), (7.2, 1.8), stroke: colors.stream.accent + arrow-width, mark: (end: "barbed"))
      line((7.2, 1.8), (7.8, 1.8), stroke: colors.stream.accent + arrow-width)
      content((7, 1.3), text(size: 6pt, "Explicit design\nrequired"), anchor: "center")
    })
  ]

  This fundamental difference explains why stream patterns from other languages don't translate directly
]



#slide[
  === The end
]
