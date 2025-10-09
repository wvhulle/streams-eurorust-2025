#import "template.typ": *
#import "lib/constants.typ": *
#import "@preview/cetz:0.4.2": canvas, draw
#import "@preview/fletcher:0.5.8" as fletcher: diagram, edge, node
#import fletcher.shapes: pill

#import "slides/01-motivation.typ": motivation-slides
#import "slides/02-stream-trait.typ": stream-trait-slides
#import "slides/03-stream-api.typ": stream-api-slides
#import "slides/04-example-double.typ": example-double-slides
#import "slides/05-example-fork.typ": example-fork-slides
#import "slides/06-principles.typ": principles-slides
#import "slides/07-outro.typ": outro-slides

#show: presentation-template.with(
  title: "Make Your Own Stream Operators",
  subtitle: "Transforming asynchronous data streams in Rust",
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

#motivation-slides(slide)
#stream-trait-slides(slide)
#stream-api-slides(slide)
#example-double-slides(slide)
#example-fork-slides(slide)
#principles-slides(slide)
#outro-slides(slide)

