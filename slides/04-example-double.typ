#import "../lib/constants.typ": *
#import "../lib/diagram-helpers.typ": *
#import "@preview/fletcher:0.5.8" as fletcher: diagram, edge, node
#import fletcher.shapes: pill
#import "@preview/cetz:0.4.2": canvas, draw

#let example-double-slides(slide) = {
  slide[
    == Example 1: One-to-One Operator
  ]

  slide(title: "Doubling stream operator")[
    #styled-diagram(
      spacing: 6em,

      node((0, 0), [Input\ Stream], fill: colors.stream.base, stroke: colors.stream.accent + stroke-width),
      node(
        (1, 0),
        [`Double`],
        fill: colors.operator.base,
        stroke: colors.operator.accent + stroke-width,
        shape: pill,
      ),
      node((2, 0), [Output\ Stream], fill: colors.stream.base, stroke: colors.stream.accent + stroke-width),

      edge((0, 0), (1, 0), [1, 2, 3, ...], "-}>", stroke: colors.data.accent + arrow-width),
      edge((1, 0), (2, 0), [2, 4, 6, ...], "-}>", stroke: colors.data.accent + arrow-width),
    )
  ]

  slide(title: "Wrapping the original stream")[
    #set text(size: 8pt)

    All stream operators start by:

    - *wrapping input stream by value*
    - and being *generic over stream type*

    (No trait bounds yet ):

    ```rust
    struct Double<InSt> { in_stream: InSt, }
    ```
    And implementing the `Stream` trait for it (*with trait bounds*):

    ```rs
    impl<InSt> Stream for Double<InSt> where InSt: Stream<Item = i32> {
      type Item = InSt::Item;

      fn poll_next(self: Pin<&mut Self>, cx: &mut Context<'_>) ->  Poll<Option<Self::Item>> {
                ...
      }
    }
    ```
  ]

  slide(title: "Naive implementation of `poll_next`")[
    Focus on the implementation of the `poll_next` method

    (Remember that `Self = Double<InSt>` with field `in_stream: InSt`):

    ```rust
    fn poll_next(self: Pin<&mut Self>, cx: &mut Context<'_>)
        -> Poll<Option<Self::Item>> {
              // Access field `self.in_stream`
              //  `self.in_stream` is of type `InSt`
              Pin::new(&mut self.in_stream) // Not possible!
                  .poll_next(cx) // Unreachable ...
                  .map(|x| x * 2)
    }
    ```
    `Pin<&mut Self>` *blocks access to `self.in_stream`*!
  ]

  slide(title: "How to access `self.in_stream`?")[
    #text(size: 8pt)[
      #align(center + horizon)[

        #canvas(length: 1.2cm, {
          import draw: *

          hexagon(
            draw,
            (1, 2),
            3,
            colors.pin.accent,
            text(fill: colors.pin.accent, size: 8pt, weight: "bold")[`Pin<&mut Double>`],
            (1, 3.5),
            fill-color: colors.pin.base,
          )
          circle((1, 2), radius: 0.8, fill: colors.operator.base, stroke: colors.operator.accent + stroke-width)
          content(
            (1, 3),
            text(size: 7pt, weight: "bold", [`&mut Double`], fill: colors.operator.accent),
            anchor: "center",
          )
          circle((1, 2), radius: 0.4, fill: colors.stream.base, stroke: colors.stream.accent + stroke-width)
          content((1, 2), text(size: 6pt, fill: colors.stream.accent, [`InSt`]), anchor: "center")

          line((2.7, 2), (3.5, 2), mark: (end: "barbed"), stroke: colors.state.accent + arrow-width)
          content((3, 2.4), text(size: 7pt, fill: colors.pin.accent, [?]), anchor: "center")

          circle((4, 2), radius: 0.4, fill: colors.stream.base, stroke: colors.stream.accent + stroke-width)
          content((4, 2), text(size: 6pt, fill: colors.stream.accent, [`InSt`]), anchor: "center")

          line((4.5, 2), (5.3, 2), mark: (end: "barbed"), stroke: colors.state.accent + arrow-width)
          content((5, 2.4), text(size: 6pt, text(fill: colors.pin.accent)[?]), anchor: "center")

          hexagon(
            draw,
            (6.5, 2),
            2,
            colors.pin.accent,
            text(fill: colors.pin.accent)[`Pin<&mut InSt>`],
            (6.5, 3.3),
            fill-color: colors.pin.base,
          )
          circle((6.5, 2), radius: 0.4, fill: colors.stream.base, stroke: colors.stream.accent + stroke-width)
          content((6.5, 2), text(size: 6pt, fill: colors.stream.accent)[`InSt`], anchor: "center")

          line((7.5, 2), (8.5, 2), mark: (end: "barbed"), stroke: colors.stream.accent + arrow-width)
          content((8, 2.4), text(size: 6pt, fill: colors.stream.accent, [`Stream::poll_next()`]), anchor: "north-west")
        })

        #v(1em)

        #grid(
          columns: (auto, auto, auto),
          column-gutter: 2em,
          row-gutter: 0.8em,

          rect(width: 1.2em, height: 0.8em, fill: colors.pin.base, stroke: colors.pin.accent + 0.8pt),
          text(size: 8pt)[Pin types],
          [],

          rect(width: 1.2em, height: 0.8em, fill: colors.operator.base, stroke: colors.operator.accent + 0.8pt),
          text(size: 8pt)[Operators/structs],
          [],

          rect(width: 1.2em, height: 0.8em, fill: colors.stream.base, stroke: colors.stream.accent + 0.8pt),
          text(size: 8pt)[Streams/inner types],
          [],
        )
      ]
    ]
  ]

  slide(title: [`!Unpin` defends against unsafe moves])[
    #set text(size: 8pt)
    #align(center)[
      #grid(
        rows: (auto, auto),
        row-gutter: 1.5em,

        [
          #canvas(length: 1cm, {
            import draw: *

            content((1, 2.5), text(size: 2em, "🐦"), anchor: "center")
            content((1, 2.0), text(size: 8pt, weight: "bold", [`Unpin` Bird]), anchor: "center")
            content((1, 1.6), text(size: 6pt, "✅ Safe to move"), anchor: "center")

            line((1.8, 2.7), (7.2, 2.7), mark: (end: "barbed"), stroke: colors.pin.accent + arrow-width)
            content(
              (4.5, 3.0),
              text(size: 7pt, weight: "bold", fill: colors.pin.accent, [`Pin::new()`]),
              anchor: "center",
            )
            content((4.5, 2.4), text(size: 6pt, "Always safe"), anchor: "center")

            line((7.2, 1.7), (1.8, 1.7), mark: (end: "barbed"), stroke: colors.pin.accent + arrow-width)
            content(
              (4.5, 2.0),
              text(size: 7pt, weight: "bold", fill: colors.pin.accent, [`Pin::get_mut()`]),
              anchor: "center",
            )
            content((4.5, 1.4), text(size: 6pt, [if `Bird: Unpin`]), anchor: "center")

            hexagon(
              draw,
              (8.5, 2.3),
              2.5,
              colors.pin.accent,
              text(fill: colors.pin.accent)[`Pin<&mut Bird>`],
              (8.5, 3.7),
              fill-color: colors.pin.base,
            )
            content((8.5, 2.6), text(size: 2em, "🐦"), anchor: "center")
            content((8.5, 2.0), text(size: 8pt, weight: "bold", [`Unpin` Bird]), anchor: "center")
            content((8.5, 1.6), text(size: 6pt, [Can be\ uncaged]), anchor: "center")
          })
        ],

        [
          #canvas(length: 1cm, {
            import draw: *

            content((1, 2.8), text(size: 3em, "🐅"), anchor: "center")
            content((1, 2.0), text(size: 8pt, weight: "bold", [`!Unpin` Tiger]), anchor: "center")
            content((1, 1.6), text(size: 6pt, "⚠️ Dangerous to move"), anchor: "center")

            line((2.5, 2.8), (6.5, 1.8), stroke: colors.error.accent + arrow-width)
            line((2.5, 1.8), (6.5, 2.8), stroke: colors.error.accent + arrow-width)

            content((4.5, 1.5), text(size: 6pt, fill: colors.error.accent, [❌ Not safe]), anchor: "center")
            content((4.5, 2.5), text(size: 9pt, weight: "bold", [`Pin::get_mut()` \ `Pin::new()`]), anchor: "center")

            hexagon(
              draw,
              (8.5, 2.3),
              2.5,
              colors.pin.accent,
              text(fill: colors.pin.accent)[`Pin<&mut Tiger>`],
              (8.5, 3.7),
              fill-color: colors.pin.base,
            )
            content((8.5, 2.8), text(size: 3em, "🐅"), anchor: "center")
            content((8.5, 2.0), text(size: 8pt, weight: "bold", [`!Unpin` Tiger]), anchor: "center")
            content((8.5, 1.6), text(size: 6pt, [Can't be\ uncaged]), anchor: "center")
          })
        ],
      )
    ]
  ]


  slide(title: [Put your `!Unpin` type on the heap])[
    #set text(size: 8pt)
    #align(center)[
      #canvas(length: 1.2cm, {
        import draw: *

        rect((1, 3), (4, 5), fill: colors.ui.base, stroke: colors.ui.accent + stroke-width, radius: node-radius)
        content((2.5, 5.2), text(size: 9pt, weight: "bold", "Stack"), anchor: "center")
        content((2.5, 4.7), text(size: 8pt, [`Box::new(in_stream)`]), anchor: "center")
        rect((1.9, 3.5), (3, 4.5), fill: colors.neutral.base, stroke: colors.neutral.accent + stroke-width)
        content((2.5, 4.), text(size: 8pt, [pointer \ `0X1234`]), anchor: "center")
        content((2.5, 3.3), text(size: 7pt, "✅ Safe to move"), anchor: "center")

        line((3.1, 4), (7.3, 3.7), mark: (end: "barbed"), stroke: colors.operator.accent + arrow-width)
        content((5.25, 4.3), text(size: 8pt, [dereferences to]), anchor: "center")

        content((11.5, 5.0), text(size: 3em, "🐅"), anchor: "center")
        content((11.5, 4.0), text(size: 8pt, weight: "bold", [`!Unpin` Tiger]), anchor: "center")
        arc(
          (10.5, 5.2),
          start: 60deg,
          stop: 170deg,
          radius: 1.5,
          mark: (end: "barbed"),
          stroke: colors.error.accent + arrow-width,
        )

        line((6.0, 3), (10, 3), stroke: colors.operator.accent + stroke-width)
        line((6.0, 3), (8, 5), stroke: colors.operator.accent + stroke-width)
        line((10, 3), (8, 5), stroke: colors.operator.accent + stroke-width)

        content((8, 5.3), text(size: 9pt, weight: "bold", "Heap"), anchor: "center")
        content((8.4, 3.8), text(size: 6pt, [`0X1234`]), anchor: "center")
        content((8.4, 3.5), text(size: 8pt, [`InSt (!Unpin)`]), anchor: "center")
        content((8.3, 3.2), text(size: 7pt, "📌 Fixed address"), anchor: "center")
      })
    ]

    1. The output of `Box::new(tiger)` is just a pointer \
      Moving pointers is safe, so *`Box: Unpin`*
    2. Box behaves like what it contains: *`Box<X>: Deref<Target = X>`*


    Result:
    ```rs
    struct Double {in_stream: Box<InSt>}: Unpin
    ```
  ]

  slide(title: "Putting it all together visually")[
    #set text(size: 8pt)
    Mapping from `Pin<&mut Double>` to `&mut InSt` is called *projection*

    #align(center)[
      #canvas(length: 1.2cm, {
        import draw: *

        hexagon(
          draw,
          (2, 4),
          4.5,
          colors.pin.accent,
          text(fill: colors.pin.accent)[`Pin<&mut Double>`],
          (2, 6.2),
          fill-color: colors.pin.base,
        )
        circle((2, 4), radius: 1.5, fill: colors.operator.base, stroke: colors.operator.accent + stroke-width)
        content(
          (2, 5.7),
          text(size: 7pt, weight: "bold", fill: colors.operator.accent)[`&mut Double`],
          anchor: "center",
        )
        content((2, 5.2), text(size: 6pt, weight: "bold")[`&mut Box<InSt>`], anchor: "center")

        rect(
          (2 - 0.6, 4 - 0.6),
          (2 + 0.6, 4 + 0.6),
          fill: colors.neutral.base,
          stroke: colors.neutral.accent + stroke-width,
        )
        circle((2, 4), radius: 0.5, fill: colors.stream.base, stroke: colors.stream.accent + stroke-width)
        content((2, 4), text(size: 6pt, fill: colors.stream.accent)[`InSt:` \ `!Unpin`], anchor: "center")

        content((4.8, 5.9), text(size: 3em, "🐅"), anchor: "center")
        arc(
          (4.0, 5.8),
          start: 80deg,
          stop: 178deg,
          radius: 1.5,
          mark: (end: "barbed"),
          stroke: colors.error.accent + arrow-width,
        )

        circle((6.5, 4), radius: 1, fill: colors.operator.base, stroke: colors.operator.accent + stroke-width)
        content(
          (6.5, 5.2),
          text(size: 7pt, weight: "bold", fill: colors.operator.accent)[`&mut Double`],
          anchor: "center",
        )
        content((6.5, 4.7), text(size: 7pt, weight: "bold")[`&mut Box<InSt>`], anchor: "center")

        rect(
          (6.5 - 0.45, 4 - 0.45),
          (6.5 + 0.45, 4 + 0.45),
          fill: colors.neutral.base,
          stroke: colors.neutral.accent + stroke-width,
        )
        circle((6.5, 4), radius: 0.3, fill: colors.stream.base, stroke: colors.stream.accent + stroke-width)
        content((6.5, 4), text(size: 5pt, fill: colors.stream.accent)[`InSt`], anchor: "center")

        hexagon(draw, (9.5, 4.0), 2.5, colors.pin.accent, "", (9.5, 5.8), fill-color: colors.pin.base)
        content(
          (9.5, 5.4),
          text(size: 7pt, weight: "bold", fill: colors.pin.accent)[`Pin<&mut InSt>`],
          anchor: "center",
        )
        content((9.5, 4.7), text(size: 7pt, weight: "bold")[`&mut Box<InSt>`], anchor: "center")

        rect(
          (9.5 - 0.45, 4 - 0.45),
          (9.5 + 0.45, 4 + 0.45),
          fill: colors.neutral.base,
          stroke: colors.neutral.accent + stroke-width,
        )
        circle((9.5, 4), radius: 0.3, fill: colors.stream.base, stroke: colors.stream.accent + stroke-width)
        content((9.5, 4), text(size: 5pt, fill: colors.stream.accent)[`InSt`], anchor: "center")

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

  slide(title: [Complete `Stream` trait implementation])[
    #text(size: 9pt)[
      We can call `get_mut()` to get `&mut Double<InSt>` safely:

      ```rust
      impl<InSt> Stream for Double<InSt>
      where InSt: Stream<Item = i32>
      {
          fn poll_next(self: Pin<&mut Self>, cx: &mut Context<'_>)
              -> Poll<Option<Self::Item>>
          {
              // We can project because `Self: Unpin`
              let this: &mut Double<InSt> = self.get_mut();
              // `this` is a conventional name for projection
              Pin::new(&mut this.in_stream)
                  .poll_next(cx)
                  .map(|r| r.map(|x| x * 2))
          }
      }
      ```
    ]
  ]

  slide(title: "Distributing your operator")[
    Define a constructor and turn it into a method of an *extension trait*:

    ```rust
    trait DoubleStream: Stream {
        fn double(self) -> Double<Self>
        where Self: Sized + Stream<Item = i32>,
        { Double::new(self) }
    }
    // A blanket implementation should be provided by you!
    impl<S> DoubleStream for S where S: Stream<Item = i32> {}
    ```

    Now, users *don't need to know how* `Double` is implemented, just

    1. import your extension trait: `DoubleStream`
    2. call `.double()` on any compatible stream
  ]
}
