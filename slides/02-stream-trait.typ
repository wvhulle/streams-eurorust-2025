#import "../lib/constants.typ": *
#import "../lib/diagram-helpers.typ": *
#import "@preview/fletcher:0.5.8" as fletcher: diagram, edge, node

#let stream-trait-slides(slide) = {
  slide[
    == Rust's `Stream` trait
  ]

  slide(title: "A lazy interface")[
    #set text(size: 9pt)
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

  slide(title: "Moving from `Iterator` to `Stream`")[
    #{
      set text(size: 7pt)
      styled-diagram(
        spacing: (1.2em, 0.8em),

        title-node((0.5, 5), text(size: 11pt, weight: "bold")[Iterator (sync)]),

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

        node(
          stroke: 1pt + colors.stream.accent,
          fill: colors.stream.base.lighten(70%),
          inset: 1em,
          shape: rect,
          radius: 8pt,
          enclose: (
            <stream-call1>,
            <stream-call2>,
            <stream-call3>,
            <stream-call4>,
            <stream-result1>,
            <stream-result2>,
            <stream-result3>,
            <stream-result4>,
            <async-call1>,
            <async-call2>,
            <async-call3>,
            <async-call4>,
            <async-result1>,
            <async-result2>,
            <async-result3>,
            <async-result4>,
          ),
        ),

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

        title-node((0.5, 0), text(size: 8pt)[✓ Always returns immediately]),
        title-node((3.5, 0), text(size: 8pt)[⚠️ May be Pending]),
        title-node((6.5, 0), text(size: 8pt)[✓ Hides polling complexity]),
      )
    }
  ]
}
