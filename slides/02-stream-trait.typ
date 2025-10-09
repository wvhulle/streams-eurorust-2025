#import "../lib/constants.typ": *
#import "../lib/diagram-helpers.typ": *
#import "@preview/fletcher:0.5.8" as fletcher: diagram, edge, node

#let stream-trait-slides(slide) = {
  slide[
    == Rust's `Stream` trait
  ]

  slide(title: [The `Stream` trait: async iterator])[
    #set text(size: 9pt)
    Like `Future`, but yields *multiple items* over time when polled:

    ```rust
    trait Stream {
        type Item;

        fn poll_next(self: Pin<&mut Self>, cx: &mut Context<'_>)
            -> Poll<Option<Self::Item>>;
    }
    ```

    The `Poll<Option<Item>>` return type:

    - `Poll::Pending` - not ready yet, try again later
    - `Poll::Ready(Some(item))` - here's the next item
    - `Poll::Ready(None)` - stream is exhausted (no more items *right now*)
  ]

  slide(title: [Moving from `Iterator` to `Stream`])[
    #{
      set text(size: 7pt)
      styled-diagram(
        spacing: (1.2em, 0.8em),

        title-node((0.5, 5), text(size: 11pt, weight: "bold")[Iterator (sync)]),

        colored-node((0, 4), color: colors.action, name: <iter-call1>)[`next()`],
        styled-edge(<iter-call1>, <iter-result1>),
        colored-node((0, 3), color: colors.action, name: <iter-call2>)[`next()`],
        styled-edge(<iter-call2>, <iter-result4>),
        colored-node((0, 2), color: colors.action, name: <iter-call3>)[`next()`],
        styled-edge(<iter-call3>, <iter-result3>),
        colored-node((0, 1), color: colors.action, name: <iter-call4>)[`next()`],
        styled-edge(<iter-call4>, <iter-result2>),

        colored-node((1, 4), color: colors.data, name: <iter-result1>)[`Some(2)`],
        colored-node((1, 1), color: colors.data, name: <iter-result2>)[`Some(3)`],
        colored-node((1, 2), color: colors.data, name: <iter-result3>)[`Some(1)`],
        colored-node((1, 3), color: colors.data, name: <iter-result4>)[`None`],

        title-node((3.5, 5), text(size: 10pt, weight: "bold")[Stream (low-level)]),

        colored-node((3, 4), color: colors.action, name: <stream-call1>)[`poll_next()`],
        styled-edge(<stream-call1>, <stream-result1>),
        colored-node((3, 3), color: colors.action, name: <stream-call2>)[`poll_next()`],
        styled-edge(<stream-call2>, <stream-result2>),
        colored-node((3, 2), color: colors.action, name: <stream-call3>)[`poll_next()`],
        styled-edge(<stream-call3>, <stream-result3>),
        colored-node((3, 1), color: colors.action, name: <stream-call4>)[`poll_next()`],
        styled-edge(<stream-call4>, <stream-result4>),

        colored-node((4, 4), color: colors.state, name: <stream-result1>)[`Pending`],
        colored-node((4, 3), color: colors.data, name: <stream-result2>)[`Ready(Some(1))`],
        colored-node((4, 2), color: colors.state, name: <stream-result3>)[`Pending`],
        colored-node((4, 1), color: colors.data, name: <stream-result4>)[`Ready(Some(2))`],

        node(
          stroke: stroke-width + accent(colors.stream),
          fill: colors.stream,

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

        colored-node((6, 4), color: colors.action, name: <async-call1>)[`next().await`],
        styled-edge(<async-call1>, <async-result1>),
        colored-node((6, 3), color: colors.action, name: <async-call2>)[`next().await`],
        styled-edge(<async-call2>, <async-result4>),
        colored-node((6, 2), color: colors.action, name: <async-call3>)[`next().await`],
        styled-edge(<async-call3>, <async-result3>),
        colored-node((6, 1), color: colors.action, name: <async-call4>)[`next().await`],
        styled-edge(<async-call4>, <async-result2>),

        colored-node((7, 4), color: colors.data, name: <async-result1>)[`Some(2)`],
        colored-node((7, 1), color: colors.data, name: <async-result2>)[`Some(3)`],
        colored-node((7, 2), color: colors.data, name: <async-result3>)[`Some(1)`],
        colored-node((7, 3), color: colors.data, name: <async-result4>)[`None`],

        title-node((0.5, 0), text(size: 8pt)[✓ Always returns immediately]),
        title-node((3.5, 0), text(size: 8pt)[⚠️ May be Pending]),
        title-node((6.5, 0), text(size: 8pt)[✓ Hides polling complexity]),
      )

      v(1em)

      legend((
        (color: colors.action, label: [Actions]),
        (color: colors.data, label: [Data values]),
        (color: colors.state, label: [State]),
        (color: colors.stream, label: [Stream]),
      ))
    }
  ]
}
