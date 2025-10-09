#import "../lib/constants.typ": *
#import "../lib/diagram-helpers.typ": *
#import "@preview/fletcher:0.5.8" as fletcher: diagram, edge, node

#let principles-slides(slide) = {
  slide[
    == General principles
  ]


  slide(title: "Rules of thumb")[
    #align(horizon)[
      #grid(
        columns: (1fr, 1fr),
        rows: auto,
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
          *Meaningful objective targets:*
          - Simple, clear unit tests
          - Relevant benchmarks (`criterion`)
        ],
        [
          *Simple state machines:*
          1. Fewer `Option`s
          2. More states

        ],
      )




    ]
  ]
}
