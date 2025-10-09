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
}
