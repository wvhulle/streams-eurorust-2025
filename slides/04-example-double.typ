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

  slide(title: [Naive implementation of `poll_next`])[
    Focus on the implementation of the `poll_next` method

    (Remember that `Self = Double<InSt>` with field `in_stream: InSt`):

    ```rust
    fn poll_next(self: Pin<&mut Self>, cx: &mut Context<'_>)
        -> Poll<Option<Self::Item>> {
              // Cannot access self.in_stream!
              Pin::new(&mut self.in_stream) // Not possible!
                  .poll_next(cx)
                  .map(|x| x * 2)
    }
    ```
    `Pin<&mut Self>` *blocks access to `self.in_stream`* (when `Self: !Unpin`)!
  ]

  slide(title: [How to access `self.in_stream`?])[
    #text(size: 8pt)[
      #align(center + horizon)[

        #canvas(length: 1.2cm, {
          import draw: *

          hexagon(draw, (1, 2), 3, color: colors.pin)[`Pin<&mut Double>`]
          styled-circle(draw, (1, 2), colors.operator, radius: 0.8)[`&mut Double`]

          styled-circle(draw, (1, 2), colors.stream, radius: 0.4)[`InSt`]

          styled-line(draw, (2.7, 2), (3.5, 2), colors.pin, mark: (end: "barbed"))
          styled-content(draw, (3, 2.4), colors.pin, [?], size: 7pt)

          styled-circle(draw, (4, 2), colors.stream, radius: 0.4)[`InSt`]

          styled-line(draw, (4.5, 2), (5.3, 2), colors.pin, mark: (end: "barbed"))
          styled-content(draw, (5, 2.4), colors.pin, [?], size: 6pt)

          hexagon(draw, (6.5, 2), 2, color: colors.pin)[`Pin<&mut InSt>`]
          styled-circle(draw, (6.5, 2), colors.stream, radius: 0.4)[`InSt`]

          styled-line(draw, (7.5, 2), (8.5, 2), colors.action, mark: (end: "barbed"))
          styled-content(draw, (8, 2.4), colors.action, size: 6pt, anchor: "north-west")[`Stream::poll_next()`]
        })

        #v(1em)

        #legend((
          (color: colors.pin, label: [Pin types]),
          (color: colors.operator, label: [Operators/structs]),
          (color: colors.stream, label: [Streams/inner types]),
          (color: colors.action, label: [Actions]),
        ))
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
            let bird-color = colors.data.darken(100%)
            styled-content(draw, (1, 2.5), bird-color, size: 2em)[🐦]
            styled-content(draw, (1, 2.0), bird-color, size: 8pt, weight: "bold")[`Unpin` Bird]
            styled-content(draw, (1, 1.6), bird-color, size: 6pt)[Safe to move]

            styled-line(draw, (1.8, 2.7), (7.2, 2.7), colors.pin, mark: (end: "barbed"))
            styled-content(draw, (4.5, 3.0), colors.pin, size: 7pt, weight: "bold")[`Pin::new()`]
            styled-content(draw, (4.5, 2.4), colors.pin, size: 6pt)[Always safe if `Bird: Unpin`]

            styled-line(draw, (7.2, 1.7), (1.8, 1.7), colors.pin, mark: (end: "barbed"))
            styled-content(draw, (4.5, 2.0), colors.pin, size: 7pt, weight: "bold")[`Pin::get_mut()`]

            hexagon(
              draw,
              (8.5, 2.3),
              2.5,
              color: colors.pin,
            )[`Pin<&mut Bird>`]
            styled-content(draw, (8.5, 2.6), bird-color, size: 2em)[🐦]
            styled-content(draw, (8.5, 2.0), bird-color, size: 8pt, weight: "bold")[`Unpin` Bird]
            styled-content(draw, (8.5, 1.6), bird-color, size: 6pt)[Can be\ uncaged]
          })
        ],

        [
          #canvas(length: 1cm, {
            import draw: *
            let tiger-color = colors.neutral.darken(100%)
            styled-content(draw, (1, 2.8), tiger-color, size: 3em)[🐅]
            styled-content(draw, (1, 2.0), tiger-color, size: 8pt, weight: "bold")[`!Unpin` Tiger]
            styled-content(draw, (1, 1.6), tiger-color, size: 6pt)[Dangerous to move]

            styled-line(draw, (2.5, 2.8), (6.5, 1.8), colors.error)
            styled-line(draw, (2.5, 1.8), (6.5, 2.8), colors.error)

            styled-content(draw, (4.5, 1.5), colors.error, size: 6pt)[Not always safe \ (use `unsafe`)]
            styled-content(draw, (4.5, 2.5), colors.pin, size: 9pt, weight: "bold")[`Pin::get_mut()` \ `Pin::new()`]

            hexagon(
              draw,
              (8.5, 2.3),
              2.5,
              color: colors.pin,
            )[`Pin<&mut Tiger>`]
            styled-content(draw, (8.5, 2.8), tiger-color, size: 3em)[🐅]
            styled-content(draw, (8.5, 2.0), tiger-color, size: 8pt, weight: "bold")[`!Unpin` Tiger]
            styled-content(draw, (8.5, 1.6), tiger-color, size: 6pt)[Can't be\ uncaged]
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

        styled-rect(draw, (1, 3), (4, 5), colors.neutral, radius: node-radius)[#text(
          size: 9pt,
          weight: "bold",
          [Stack],
        )]
        styled-rect(draw, (1.9, 3.5), (3, 4.5), colors.data)[pointer `0X1234`]
        content((2.5, 3.3), text(size: 7pt, [`Unpin` = Safe to move]), anchor: "center")


        content((5.25, 4.3), text(size: 7pt, [`Box::new(in_stream)` \ dereferences to]), anchor: "center")


        styled-triangle(draw, (6.0, 3), (10, 3), (8, 5), colors.neutral)[]

        content((8, 5.3), text(size: 9pt, weight: "bold", [Heap]), anchor: "center")
        styled-content(
          draw,
          (8.4, 3.5),
          black,
          size: 7pt,
        )[`0X1234`\ `InSt (!Unpin)`\ Not safe to move]

        content((11.5, 5.0), text(size: 3em, "🐅"), anchor: "center")
        content((11.5, 4.0), text(size: 8pt, weight: "bold", [`!Unpin` Tiger]), anchor: "center")
        arc(
          (10.5, 5.2),
          start: 60deg,
          stop: 170deg,
          radius: 1.5,
          mark: (end: "barbed"),
          stroke: accent(colors.error) + arrow-width,
        )

        styled-line(draw, (3.1, 4), (7.3, 3.7), colors.neutral, mark: (end: "barbed"))
      })
    ]

    1. The output of `Box::new(tiger)` is just a pointer \
      Moving pointers is safe, so *`Box<Tiger>: Unpin`*
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
        styled-circle(draw, (2, 4), colors.operator, radius: 1.5)[`&mut Double`]


        styled-rect(
          draw,
          (2 - 0.9, 4 - 0.9),
          (2 + 0.9, 4 + 0.9),
          colors.neutral,
        )[`&mut Box<InSt>`]
        styled-circle(draw, (2, 4), colors.stream, radius: 0.5, label-size: 6pt)[`InSt: !Unpin`]

        content((4.8, 5.9), text(size: 3em, "🐅"), anchor: "center")
        arc(
          (4.0, 5.8),
          start: 80deg,
          stop: 178deg,
          radius: 1.5,
          mark: (end: "barbed"),
          stroke: accent(colors.error) + arrow-width,
        )

        styled-circle(draw, (6.5, 4), colors.operator, radius: 1)[`&mut Double`]


        styled-rect(
          draw,
          (6.5 - 0.45, 4 - 0.45),
          (6.5 + 0.45, 4 + 0.45),
          colors.neutral,
        )[`&mut Box<InSt>`]
        styled-circle(draw, (6.5, 4), colors.stream, radius: 0.3, label-size: 5pt)[]

        hexagon(draw, (9.5, 4.0), 2.5, color: colors.pin)[`Pin<&mut InSt>`]

        styled-content(draw, (9.5, 4.7), colors.neutral)[`&mut Box<InSt>`]

        styled-rect(
          draw,
          (9.5 - 0.45, 4 - 0.45),
          (9.5 + 0.45, 4 + 0.45),
          colors.neutral,
        )[]
        styled-circle(draw, (9.5, 4), colors.stream, radius: 0.3, label-size: 5pt)[]

        styled-line(draw, (4.4, 4), (5.4, 4), colors.pin, mark: (end: "barbed"))
        styled-content(
          draw,
          (4.9, 4.5),
          colors.pin,

          size: 6pt,
          weight: "bold",
        )[`Pin::get_mut()`]
        styled-content(draw, (4.9, 3.5), colors.error, size: 6pt)[if `Double:` \ `Unpin`]

        styled-line(draw, (7.1, 4), (8.9, 4), colors.pin, mark: (end: "barbed"))
        styled-content(draw, (7.9, 4.5), colors.pin, weight: "bold")[`Pin::new()`]

        styled-content(draw, (7.9, 3.5), colors.error, size: 6pt)[if `Double:` \ `Unpin`]

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
      where InSt: Stream<Item = i32> + Unpin
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

  slide(title: "Two ways to handle `!Unpin` fields")[
    #set text(size: 7pt)
    #grid(
      columns: (1fr, 1fr),
      rows: auto,
      gutter: 2em,

      [
        *Approach 1: Use `Box<_>`*
        ```rust
        struct Double<InSt> {
          in_stream: Box<InSt>
        }

        impl<InSt> Stream for Double<InSt>
        where InSt: Stream
        ```
        ✓ Works with `InSt`
      ],
      [
        *Approach 2: Require `Unpin`*
        ```rust
        struct Double<InSt> {
          in_stream: InSt
        }

        impl<InSt> Stream for Double<InSt>
        where InSt: Stream + Unpin
        ```
        ✗ Imposes `Unpin` constraint
      ],

      [ *Approach 3: Use `pin-project`*

        ```rust
        #[pin_project]
        struct Double<InSt> {
            #[pin]
            in_stream: InSt,
        }
        ```
        Used by popular crates (Tokio, etc.)
      ],
    )

  ]

  slide(title: [Example usage of `pin-project`])[
    #set text(size: 8pt)
    Projects like Tokio use the `pin-project` crate:

    ```rust
    #[pin_project]
    struct Double<InSt> {
        #[pin]
        in_stream: InSt,
    }

    impl<InSt: Stream> Stream for Double<InSt> {
        fn poll_next(self: Pin<&mut Self>, cx: &mut Context<'_>)
            -> Poll<Option<Self::Item>>
        {
            // pin-project generates safe projection code
            self.project().in_stream.poll_next(cx)
                .map(|r| r.map(|x| x * 2))
        }
    }
    ```
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
