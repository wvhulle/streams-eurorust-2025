#import "../lib/constants.typ": *
#import "../lib/diagram-helpers.typ": *
#import "@preview/fletcher:0.5.8" as fletcher: diagram, edge, node
#import fletcher.shapes: pill
#import "@preview/cetz:0.4.2": canvas, draw

#let example-double-slides(slide) = {
  slide[
    == Example 1: $1 -> 1$ Operator
  ]

  slide(title: [Doubling stream operator])[

    #align(center + horizon)[
      Very simple `Stream` operator that *doubles every item* in an input stream:


      #styled-diagram(
        spacing: (6em, 0em),

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

      Input stream *needs to yield integers*.
    ]]

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
          styled-content(draw, (3, 2.4), colors.pin)[?]

          styled-circle(draw, (4, 2), colors.stream, radius: 0.4)[`InSt`]

          styled-line(draw, (4.5, 2), (5.3, 2), colors.pin, mark: (end: "barbed"))
          styled-content(draw, (5, 2.4), colors.pin, [?])

          hexagon(draw, (6.5, 2), 2, color: colors.pin)[`Pin<&mut InSt>`]
          styled-circle(draw, (6.5, 2), colors.stream, radius: 0.4)[`InSt`]

          styled-line(draw, (7.7, 2), (8.5, 2), colors.action, mark: (end: "barbed"))
          styled-content(draw, (8, 2.4), colors.action, anchor: "north-west")[`Stream::poll_next()`]
        })

        #v(1em)

        #legend((
          (color: colors.pin, label: [Pin types]),
          (color: colors.operator, label: [Operators]),
          (color: colors.stream, label: [Streams]),
          (color: colors.action, label: [Actions]),
        ))
      ]
    ]
  ]

  slide(title: [Marking types `!Unpin` defends against unsafe moves])[
    #set text(size: 7pt)

    A _pointer type_ can only be wrapped in `Pin` if it is *not `!Unpin`*.

    Once a pointer type `P` appears inside `Pin<P>`, *target will never move again*.

    #v(-1em)

    #show "🐦": it => text(size: 3em)[#it]
    #show "🐅": it => text(size: 3em)[#it]
    #align(center)[
      #grid(
        rows: (auto, auto),
        row-gutter: 0.5em,

        [
          #canvas(length: 1cm, {
            import draw: *
            let bird-color = colors.data.darken(100%)
            styled-content(draw, (1, 2.5), bird-color)[🐦]
            styled-content(draw, (1, 2.0), bird-color)[`Unpin` Bird]
            styled-content(draw, (1, 1.6), bird-color)[Safe to move]

            styled-line(draw, (1.8, 2.7), (7.2, 2.7), colors.pin, mark: (end: "barbed"))
            styled-content(draw, (4.5, 3.0), colors.pin)[`Pin::new()`]
            styled-content(draw, (4.5, 2.4), colors.pin)[Always safe if `Bird: Unpin`]

            styled-line(draw, (7.2, 1.7), (1.8, 1.7), colors.pin, mark: (end: "barbed"))
            styled-content(draw, (4.5, 2.0), colors.pin)[`Pin::get_mut()`]

            hexagon(
              draw,
              (8.5, 2.3),
              2.5,
              color: colors.pin,
            )[`Pin<&mut Bird>`]
            styled-content(draw, (8.5, 2.8), bird-color)[🐦]
            styled-content(draw, (8.5, 2.2), bird-color)[`Unpin` Bird]
            styled-content(draw, (8.5, 1.6), bird-color)[Can be\ uncaged]
          })
        ],

        [
          #canvas(length: 1cm, {
            import draw: *
            let tiger-color = colors.neutral.darken(100%)
            styled-content(draw, (1, 2.8), tiger-color)[🐅]
            styled-content(draw, (1, 2.0), tiger-color)[`!Unpin` Tiger]
            styled-content(draw, (1, 1.6), tiger-color)[Dangerous to move]

            styled-line(draw, (2.5, 2.8), (6.5, 1.8), colors.error)
            styled-line(draw, (2.5, 1.8), (6.5, 2.8), colors.error)

            styled-content(draw, (4.5, 1.5), colors.error)[Not always safe \ (use `unsafe`)]
            styled-content(draw, (4.5, 2.5), colors.pin)[`Pin::get_mut()` \ `Pin::new()`]

            hexagon(
              draw,
              (8.5, 2.3),
              2.5,
              color: colors.pin,
            )[`Pin<&mut Tiger>`]
            styled-content(draw, (8.5, 2.8), tiger-color)[🐅]
            styled-content(draw, (8.5, 2.2), tiger-color)[`!Unpin` Tiger]
            styled-content(draw, (8.5, 1.6), tiger-color)[Can't be\ uncaged]
          })
        ],
      )
    ]
  ]


  slide(title: [Doing what the compiler wants you to do])[
    #set text(size: 8pt)
    The compiler will push you to add `Self: Unpin` which implies `InSt: Unpin`:

    ```rs
    impl<InSt> Stream for Double<InSt> where InSt: Stream<Item = i32> + Unpin {
      type Item = InSt::Item;

      fn poll_next(self: Pin<&mut Self>, cx: &mut Context<'_>) ->  Poll<Option<Self::Item>> {
        // `this` = a conventional name for `get_mut` output
        let mut this = self.get_mut();
        let mut pinned_in = Pin::new(&mut this.in_stream) // Not possible!
        pinned_in
          .poll_next(cx)
          .map(|x| x * 2)
      }
    }
    ```


    We *don't want to impose `InSt: Unpin` on users* of `Double`!

    How to enable users to `Double` streams of type `InSt: !Unpin`? ...

  ]


  slide(title: [Turning `!Unpin` into `Unpin` with boxing])[
    #set text(size: 7pt)
    #align(center)[
      #canvas(length: 1.2cm, {
        import draw: *

        styled-rect(draw, (1, 3), (4, 5), colors.neutral, radius: node-radius)[#text(
          size: 9pt,
          weight: "bold",
          [Stack],
        )]
        styled-rect(draw, (1.9, 3.5), (3, 4.5), colors.data)[pointer `0X1234` \ (memory address)]
        content((2.5, 3.3), text(size: 7pt, [`Unpin` = Safe to move]), anchor: "center")


        content((5.25, 4.3), text(size: 7pt, [`Box::new(in_stream)` \ dereferences to]), anchor: "center")


        styled-triangle(draw, (6.0, 3), (10, 3), (8, 5), colors.neutral)[]

        content((8, 5.3), text(size: 9pt, weight: "bold", [Heap]), anchor: "center")


        styled-circle(draw, (8., 3.7), colors.stream, radius: 0.5)[`[0X1234]`: `InSt`]

        content((11.5, 5.0), text(size: 3em, "🐅"), anchor: "center")
        content((11.5, 4.0), text(size: 8pt, weight: "bold", [`!Unpin` Tiger]), anchor: "center")
        arc(
          (10.5, 5.2),
          start: 60deg,
          stop: 160deg,
          radius: 1.5,
          mark: (end: "barbed"),
          stroke: accent(colors.error) + arrow-width,
        )

        styled-line(draw, (3.1, 4), (7.3, 3.7), colors.neutral, mark: (end: "barbed"))
      })
    ]



    #grid(
      columns: (1fr, 1fr),
      column-gutter: 1em,
      [

        *Nice to have*:

        1. `Box::new(tiger)` produces just a pointer on the stack
          - Moving pointers is always safe
          - Therefore: *`Box<Tiger>: Unpin`*

        2. Box dereferences to its contents
          - *`Box<X>: Deref<Target = X>`*

      ],

      [
        *Problem:* We need `Pin<&mut InSt>`, not `&mut InSt`
        - Without `Pin<Box<_>>`, we'd need `InSt: Unpin` to create `Pin<&mut InSt>` (`Pin::new()` requires `Unpin`)
        - This would force an `Unpin` constraint on `InSt`!

        *Solution:* Add a `Pin` layer around `Box`
        - Use `Pin<Box<InSt>>` instead of `Box<InSt>`
        - Enables to go directly from `Pin<&mut Double>` to `Pin<&mut InSt>` with  `Pin::as_mut()`
      ],
    )




  ]


  slide(title: [Projecting the `Double`d stream])[
    #set text(size: 8pt)


    1. `Box` the input stream to make it `Unpin`
    2. `Pin` the input stream (works with `!Unpin` streams!)
    3. Put the pinned box in `Double`d stream
      ```rs
      let double = Double {
          in_stream: Pin::new(Box::new(in_stream)) // Box::pin()
      };
      ```
      Inside `poll_next`, project to `Pin<&mut InSt>`:

      ```rs
      let in_stream: Pin<&mut InSt> = double
        .get_mut() // Pin<&mut Double<InSt>> -> &mut Double<InSt>
        .in_stream // &mut Double<InSt> -> Pin<Box<InSt>>
        .as_mut(); // Pin<Box<InSt>> -> Pin<&mut InSt>
      ```
    This `Stream` impl *works without `InSt: Unpin`*!


  ]

  slide(title: [Projecting visually])[
    From `Pin<&mut Double>` to `Pin<&mut InSt>` in a few *safe steps*:
    #text(size: 6pt)[




      #align(center)[
        #align(center)[
          #canvas(length: 1.2cm, {
            import draw: *
            let center1 = (1, 4)
            // Step 0: Starting point - Pin<&mut Double>
            hexagon(
              draw,
              center1,
              3.5,
              color: colors.pin,
            )[`Pin<&mut Double>`]
            styled-circle(draw, center1, colors.operator, radius: 1.2)[`&mut Double`]

            hexagon(
              draw,
              center1,
              2,
              color: colors.pin,
            )[`Pin<Box<Inst>>`]

            styled-rect(
              draw,
              (center1.at(0) - 0.4, center1.at(1) - 0.4),
              (center1.at(0) + 0.4, center1.at(1) + 0.4),
              colors.neutral,
            )[`Box<InSt>`]
            styled-circle(draw, center1, colors.stream, radius: 0.25)[]

            content((3, 5.3), text(size: 3em, "🐅"), anchor: "center")
            arc(
              (2.5, 5.3),
              start: 80deg,
              stop: 178deg,
              radius: 1.2,
              mark: (end: "barbed"),
              stroke: accent(colors.error) + arrow-width,
            )

            // Step 1: After .get_mut() - &mut Double

            let center2 = (4.5, 4)
            styled-circle(draw, center2, colors.operator, radius: 1.2)[`&mut Double`]
            hexagon(
              draw,
              center2,
              2,
              color: colors.pin,
            )[`Pin<Box<Inst>>`]

            draw.content((center2.at(0), center2.at(1) - 1.4))[`&mut Self` \ mutable ref to operator]

            styled-rect(
              draw,
              (center2.at(0) - 0.4, center2.at(1) - 0.4),
              (center2.at(0) + 0.4, center2.at(1) + 0.4),
              colors.neutral,
            )[`Box<InSt>`]
            styled-circle(draw, center2, colors.stream, radius: 0.25)[]

            // Step 2: After .in_stream - Pin<Box<InSt>>
            let center3 = (7.5, 4)
            hexagon(
              draw,
              center3,
              2,
              color: colors.pin,
            )[`Pin<Box<Inst>>`]

            styled-rect(
              draw,
              (center3.at(0) - 0.4, center3.at(1) - 0.4),
              (center3.at(0) + 0.4, center3.at(1) + 0.4),
              colors.neutral,
            )[`Box<InSt>`]
            styled-circle(draw, center3, colors.stream, radius: 0.25)[]


            styled-circle(draw, (7.5, 4), colors.stream, radius: 0.25)[]

            draw.content((center3.at(0), center3.at(1) - 1.4))[_pinned and boxed \ inner input stream field_]

            // Step 3: After .as_mut() - Pin<&mut InSt>
            let center4 = (10.5, 4)

            hexagon(draw, center4, 2, color: colors.pin)[`Pin<&mut InSt>`]

            styled-circle(draw, center4, colors.stream, radius: 0.25)[`InSt`]

            draw.content((center4.at(0), center4.at(1) - 1.4))[_pinned unboxed inner \ input stream_]

            // Arrow 1: .get_mut()
            styled-line(draw, (2.9, 4), (3.3, 4), colors.pin, mark: (end: "barbed"))
            styled-content(
              draw,
              (3.1, 4.5),
              colors.pin,
            )[`.get_mut()`]
            styled-content(draw, (3.1, 3.2), colors.neutral)[Safe \ because \ `Double:` \ `Unpin`]

            // Arrow 2: .in_stream (field access)
            styled-line(draw, (5.8, 4), (6.3, 4), colors.neutral, mark: (end: "barbed"))
            styled-content(draw, (5.9, 4.5), colors.neutral)[`.in_stream`]
            styled-content(draw, (6.1, 3.5), colors.neutral)[simple \ field \ access]

            // Arrow 3: .as_mut() (pin projection)
            styled-line(draw, (8.7, 4), (9.3, 4), colors.pin, mark: (end: "barbed"))
            styled-content(draw, (9.0, 4.5), colors.pin)[`.as_mut()`]
            styled-content(draw, (9.0, 3.4), colors.neutral)[always safe \ because `Pin` \ contract]

            // Arrow 4: .poll_next()
            styled-line(draw, (11.7, 4), (12.4, 4), colors.action, mark: (end: "barbed"))
            styled-content(
              draw,
              (12.2, 4.5),
              colors.stream,
            )[`.poll_next()`]
          })
        ]]


    ]

    *Reminder*: `Pin` does not take up space, it functions more like a gatekeeper that guarantees *pointee will never move again*.
  ]

  slide(title: [Complete boxed `Stream` implementation])[
    #text(size: 9pt)[
      We can call `Pin::get_mut()` to get `&mut Double<InSt>` safely from `Pin<&mut Double<InSt>>`

      ```rust
      impl<InSt> Stream for Double<InSt>
      where InSt: Stream<Item = i32>
      {
          fn poll_next(self: Pin<&mut Self>, cx: &mut Context<'_>)
              -> Poll<Option<Self::Item>>
          {
              // We can project because `Self: Unpin`
              let this: &mut Double<InSt> = self.get_mut();
              this.in_stream.as_mut()
                  .poll_next(cx)
                  .map(|r| r.map(|x| x * 2))
          }
      }
      ```
    ]
  ]

  slide(title: [Two ways to handle `!Unpin` fields])[
    #grid(
      columns: (1fr, 1fr),
      rows: auto,
      gutter: 2em,

      [
        *Approach 1: Use `Box<_>`*
        ```rust
        struct Double<InSt> {
          in_stream: Pin<Box<InSt>>
        }

        impl<InSt> Stream for Double<InSt>
          where InSt: Stream
        ```
        ✓ Works with any `InSt`, also `!Unpin`
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
        ✗ Imposes `Unpin` constraint on users
      ],
    )
    #v(1em)
    ... or, use `pin-project` crate

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
