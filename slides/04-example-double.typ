#import "../lib/constants.typ": *
#import "../lib/diagram-helpers.typ": *
#import "@preview/fletcher:0.5.8" as fletcher: diagram, edge, node
#import fletcher.shapes: pill
#import "@preview/cetz:0.4.2": canvas, draw

#let example-double-slides(slide) = {
  slide[
    == Example 1: One-to-One Operator
  ]

  slide(title: [Doubling stream operator])[
    #styled-diagram(
      spacing: 6em,

      stream-node((0, 0), <in>)[Input\ Stream],
      colored-node(
        (1, 0),
        color: colors.operator,
        name: <double>,
        shape: pill,
      )[`Double`],
      stream-node((2, 0), <out>)[Output\ Stream],

      styled-edge(<in>, <double>, label: [1, 2, 3, ...], "->", color: colors.data),
      styled-edge(<double>, <out>, label: [2, 4, 6, ...], "->", color: colors.data),
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
            color: colors.pin,
          )[`Pin<&mut Double>`]
          styled-circle(draw, (1, 2), colors.operator, radius: 0.8)
          content(
            (1, 3),
            text(size: 7pt, weight: "bold", [`&mut Double`], fill: colors.operator),
            anchor: "center",
          )
          styled-circle(draw, (1, 2), colors.stream, radius: 0.4, label: [`InSt`])

          styled-line(draw, (2.7, 2), (3.5, 2), colors.state, mark: (end: "barbed"))
          styled-content(draw, (3, 2.4), colors.pin, [?], size: 7pt)

          styled-circle(draw, (4, 2), colors.stream, radius: 0.4, label: [`InSt`])

          styled-line(draw, (4.5, 2), (5.3, 2), colors.state, mark: (end: "barbed"))
          styled-content(draw, (5, 2.4), colors.pin, [?], size: 6pt)

          hexagon(
            draw,
            (6.5, 2),
            2,
            color: colors.pin,
          )[`Pin<&mut InSt>`]
          styled-circle(draw, (6.5, 2), colors.stream, radius: 0.4, label: [`InSt`])

          styled-line(draw, (7.5, 2), (8.5, 2), colors.stream, mark: (end: "barbed"))
          styled-content(draw, (8, 2.4), colors.stream, [`Stream::poll_next()`], size: 6pt, anchor: "north-west")
        })

        #v(1em)

        #grid(
          columns: (auto, auto, auto),
          column-gutter: 2em,
          row-gutter: 0.8em,

          rect(width: 1.2em, height: 0.8em, fill: colors.pin, stroke: colors.pin.darken(70%) + 0.8pt),
          text(size: 8pt)[Pin types],
          [],

          rect(width: 1.2em, height: 0.8em, fill: colors.operator, stroke: colors.operator.darken(70%) + 0.8pt),
          text(size: 8pt)[Operators/structs],
          [],

          rect(width: 1.2em, height: 0.8em, fill: colors.stream, stroke: colors.stream.darken(70%) + 0.8pt),
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

            line((1.8, 2.7), (7.2, 2.7), mark: (end: "barbed"), stroke: colors.pin + arrow-width)
            content(
              (4.5, 3.0),
              text(size: 7pt, weight: "bold", fill: colors.pin, [`Pin::new()`]),
              anchor: "center",
            )
            content((4.5, 2.4), text(size: 6pt, "Always safe"), anchor: "center")

            line((7.2, 1.7), (1.8, 1.7), mark: (end: "barbed"), stroke: colors.pin + arrow-width)
            content(
              (4.5, 2.0),
              text(size: 7pt, weight: "bold", fill: colors.pin, [`Pin::get_mut()`]),
              anchor: "center",
            )
            content((4.5, 1.4), text(size: 6pt, [if `Bird: Unpin`]), anchor: "center")

            hexagon(
              draw,
              (8.5, 2.3),
              2.5,
              color: colors.pin,
            )[`Pin<&mut Bird>`]
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

            line((2.5, 2.8), (6.5, 1.8), stroke: colors.error + arrow-width)
            line((2.5, 1.8), (6.5, 2.8), stroke: colors.error + arrow-width)

            styled-content(draw, (4.5, 1.5), colors.error, [❌ Not safe], size: 6pt)
            content((4.5, 2.5), text(size: 9pt, weight: "bold", [`Pin::get_mut()` \ `Pin::new()`]), anchor: "center")

            hexagon(
              draw,
              (8.5, 2.3),
              2.5,
              color: colors.pin,
            )[`Pin<&mut Tiger>`]
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

        rect((1, 3), (4, 5), fill: colors.ui, stroke: colors.ui + stroke-width, radius: node-radius)
        content((2.5, 5.2), text(size: 9pt, weight: "bold", "Stack"), anchor: "center")
        content((2.5, 4.7), text(size: 8pt, [`Box::new(in_stream)`]), anchor: "center")
        rect((1.9, 3.5), (3, 4.5), fill: colors.neutral, stroke: colors.neutral + stroke-width)
        content((2.5, 4.), text(size: 8pt, [pointer \ `0X1234`]), anchor: "center")
        content((2.5, 3.3), text(size: 7pt, "✅ Safe to move"), anchor: "center")

        line((3.1, 4), (7.3, 3.7), mark: (end: "barbed"), stroke: colors.operator + arrow-width)
        content((5.25, 4.3), text(size: 8pt, [dereferences to]), anchor: "center")

        content((11.5, 5.0), text(size: 3em, "🐅"), anchor: "center")
        content((11.5, 4.0), text(size: 8pt, weight: "bold", [`!Unpin` Tiger]), anchor: "center")
        arc(
          (10.5, 5.2),
          start: 60deg,
          stop: 170deg,
          radius: 1.5,
          mark: (end: "barbed"),
          stroke: colors.error + arrow-width,
        )

        line((6.0, 3), (10, 3), stroke: colors.operator + stroke-width)
        line((6.0, 3), (8, 5), stroke: colors.operator + stroke-width)
        line((10, 3), (8, 5), stroke: colors.operator + stroke-width)

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
          color: colors.pin,
        )[`Pin<&mut Double>`]
        styled-circle(draw, (2, 4), colors.operator, radius: 1.5, label: [`&mut Double`])


        styled-rect(
          draw,
          (2 - 0.9, 4 - 0.9),
          (2 + 0.9, 4 + 0.9),
          colors.neutral,
          label: [`&mut Box<InSt>`],
        )
        styled-circle(draw, (2, 4), colors.stream, radius: 0.5, label: [`InSt: !Unpin`], label-size: 6pt)

        content((4.8, 5.9), text(size: 3em, "🐅"), anchor: "center")
        arc(
          (4.0, 5.8),
          start: 80deg,
          stop: 178deg,
          radius: 1.5,
          mark: (end: "barbed"),
          stroke: colors.error.saturate(50%) + arrow-width,
        )

        styled-circle(draw, (6.5, 4), colors.operator, radius: 1, label: [`&mut Double`])


        styled-rect(
          draw,
          (6.5 - 0.45, 4 - 0.45),
          (6.5 + 0.45, 4 + 0.45),
          colors.neutral,
          label: [`&mut Box<InSt>`],
        )
        styled-circle(draw, (6.5, 4), colors.stream, radius: 0.3, label-size: 5pt)

        hexagon(draw, (9.5, 4.0), 2.5, color: colors.pin)[`Pin<&mut InSt>`]

        styled-content(draw, (9.5, 4.7), colors.neutral)[`&mut Box<InSt>`]

        styled-rect(
          draw,
          (9.5 - 0.45, 4 - 0.45),
          (9.5 + 0.45, 4 + 0.45),
          colors.neutral,
        )
        styled-circle(draw, (9.5, 4), colors.stream, radius: 0.3, label-size: 5pt)

        styled-line(draw, (4.4, 4), (5.4, 4), colors.state, mark: (end: "barbed"))
        styled-content(
          draw,
          (4.9, 4.5),
          colors.pin,

          size: 6pt,
          weight: "bold",
        )[`Pin::get_mut()`]
        styled-content(draw, (4.9, 3.5), colors.error, size: 6pt)[if `Double:` \ `Unpin`]

        styled-line(draw, (7.1, 4), (8.9, 4), colors.state, mark: (end: "barbed"))
        styled-content(draw, (7.9, 4.5), colors.pin, weight: "bold")[`Pin::new()`]

        styled-line(draw, (11.0, 4), (11.7, 4), colors.stream, mark: (end: "barbed"))
        styled-content(
          draw,
          (11.5, 4.5),
          colors.stream,
          size: 6pt,
          weight: "bold",
        )[`Stream::poll_next()`]
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
