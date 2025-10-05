
#import "@preview/fletcher:0.5.8" as fletcher: diagram, edge, node
#import "@preview/cetz:0.4.2": canvas, draw
#import "constants.typ": (
  arrow-width as default-arrow-width, colors, node-outset as default-node-outset, node-radius as default-node-radius,
  stroke-width as default-stroke-width,
)

#let styled-diagram(
  stroke-width: default-stroke-width,
  node-radius: default-node-radius,
  arrow-width: default-arrow-width,
  node-outset: default-node-outset,
  ..args,
  body,
) = align(center + horizon)[
  #diagram(
    node-stroke: stroke-width,
    node-corner-radius: node-radius,
    edge-stroke: arrow-width,
    node-outset: node-outset,
    ..args,
    body,
  )
]

#let emoji-node(
  pos,
  emoji,
  color,
  name,
  stroke-width: default-stroke-width,
  node-outset: default-node-outset,
) = node(
  pos,
  emoji,
  fill: color.base,
  stroke: color.accent + stroke-width,
  name: name,
)

#let stream-node(
  pos,
  text,
  name,
  stroke-width: default-stroke-width,
  outset: default-node-outset,
  color: colors.stream,
) = node(
  pos,
  [#text],
  fill: color.base,
  stroke: color.accent + stroke-width,
  outset: outset,
  name: name,
)

#let call-node(
  pos,
  text,
  color,
  name,
  stroke-width: default-stroke-width,
  outset: default-node-outset,
) = node(
  pos,
  [#text],
  fill: color.base,
  stroke: color.accent + stroke-width,
  outset: outset,
  name: name,
)

#let result-node(
  pos,
  text,
  color,
  name,
  stroke-width: default-stroke-width,
  outset: default-node-outset,
) = node(
  pos,
  [#text],
  fill: color.base,
  stroke: color.accent + stroke-width,
  outset: outset,
  name: name,
)

#let title-node(pos, text, fill: none, stroke: none, node-outset: default-node-outset) = node(
  outset: node-outset,
  pos,
  text,
  fill: fill,
  stroke: stroke,
)

#let queue-item(
  pos,
  char,
  consumed,
  name,
  stroke-width: default-stroke-width,
  colors,
  node-outset: default-node-outset,
) = node(
  outset: node-outset,
  pos,
  if consumed { [#strike[#char]] } else { [#char] },
  fill: if consumed { colors.neutral.base.lighten(90%) } else { colors.neutral.base.darken(10%) },
  stroke: colors.neutral.accent + stroke-width,
  shape: fletcher.shapes.rect,
  name: name,
)

#let data-item(
  pos,
  char,
  name,
  stroke-width: default-stroke-width,
  colors,
  node-outset: default-node-outset,
) = node(
  outset: node-outset,
  pos,
  [#char],
  fill: colors.data.base,
  stroke: colors.data.accent + stroke-width,
  shape: fletcher.shapes.circle,
  name: name,
)

#let layer(
  pos,
  name,
  label,
  desc,
  color: colors.operator,
  examples,
  stroke-width: default-stroke-width,
  label-size: 10pt,
  desc-size: 8pt,
  examples-size: 7pt,
  node-outset: default-node-outset,
) = {
  node(pos, name: name, fill: color.base, stroke: color.accent + stroke-width, outset: node-outset, stack(
    dir: ttb,
    spacing: 0.6em,
    text(weight: "bold", size: label-size, label),
    text(size: desc-size, style: "italic", desc),
    text(size: examples-size, examples.join(" • ")),
  ))
}

#let flow-edge(
  from,
  to,
  color,
  arrow-width: default-arrow-width,
  label: none,
  ..args,
) = edge(
  from,
  to,
  if label != none { [#label] },
  "->",
  stroke: color.accent + arrow-width,
  ..args,
)

#let simple-edge(from, to, ..args) = edge(from, to, "->", ..args)

#let labeled-flow(
  from,
  to,
  label,
  color,
  arrow-width: default-arrow-width,
  ..args,
) = edge(
  from,
  to,
  [#label],
  "->",
  stroke: color.accent + arrow-width,
  ..args,
)

#let simple-flow(
  from,
  to,
  color,
  stroke-width: default-stroke-width,
  ..args,
) = edge(
  from,
  to,
  "->",
  stroke: color.accent + stroke-width,
  ..args,
)

#let queue-link(
  from,
  to,
  label,
  stroke-width: default-stroke-width,
  colors,
  ..args,
) = edge(
  from,
  to,
  text(fill: colors.neutral.accent)[#label],
  "--",
  stroke: colors.neutral.accent + stroke-width,
  ..args,
)

#let hexagon(
  draw,
  center,
  size,
  stroke-color,
  label,
  label-pos,
  fill-color: white,
  stroke-width: default-stroke-width,
) = {
  draw.circle(
    center,
    radius: size / 2,
    stroke: stroke-color + stroke-width,
    fill: fill-color,
  )
  if label != "" {
    draw.content(label-pos, label, anchor: "center")
  }
}

#let state-node(
  pos,
  title,
  desc,
  color,
  name,
  stroke-width: default-stroke-width,
  title-size: 8pt,
  desc-size: 6pt,
) = node(
  pos,
  stack(
    dir: ttb,
    spacing: 0.5em,
    text(size: title-size, weight: "bold")[#title],
    text(size: desc-size, style: "italic")[#desc],
  ),
  fill: color.base,
  stroke: color.accent + stroke-width,
  name: name,
)

#let workflow-step(
  pos,
  num,
  title,
  items,
  color,
  name,
  stroke-width: default-stroke-width,
  text-size: 7pt,
) = node(
  pos,
  align(left, text(size: text-size, [
    *#num. #title*
    #for item in items [
      - #item
    ]
  ])),
  fill: color.base,
  stroke: color.accent + stroke-width,
  name: name,
)

#let labeled-edge(
  from,
  to,
  label: none,
  label-size: 6pt,
  ..args,
) = {
  if label != none {
    edge(from, to, text(size: label-size)[#label], "->", ..args)
  } else {
    edge(from, to, "->", ..args)
  }
}

#let transition(
  from,
  to,
  label,
  label-size: 6pt,
  ..args,
) = edge(
  from,
  to,
  text(size: label-size)[#label],
  "->",
  ..args,
)
