#import "@preview/fletcher:0.5.8" as fletcher: diagram, edge, node
#import "constants.typ": (
  arrow-width as default-arrow-width, node-outset as default-node-outset, node-radius as default-node-radius,
  stroke-width as default-stroke-width,
)
#import "colors.typ": accent, colors

// =======================
// Main Wrapper Function
// ============================================================================

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

// ============================================================================
// Basic Node Creators
// ============================================================================

#let colored-node(
  pos,
  color: none,
  name: none,
  stroke-width: default-stroke-width,
  outset: default-node-outset,
  shape: auto,
  content,
) = node(
  pos,
  content,
  fill: if color == none { none } else { color },
  stroke: if color == none { none } else { accent(color) + stroke-width },
  outset: outset,
  shape: shape,
  name: name,
)

#let stream-node(
  pos,
  name,
  color: colors.stream,
  stroke-width: default-stroke-width,
  outset: default-node-outset,
  body,
) = colored-node(pos, color: color, name: name, stroke-width: stroke-width, outset: outset, body)

#let emoji-node(
  pos,
  color,
  name,
  stroke-width: default-stroke-width,
  outset: default-node-outset,
  content,
) = colored-node(pos, color: color, name: name, stroke-width: stroke-width, outset: outset, text(size: 1.5em, content))

#let title-node(
  pos,
  fill: none,
  stroke: none,
  outset: default-node-outset,
  content,
) = node(
  pos,
  content,
  outset: outset,
  fill: fill,
  stroke: stroke,
)

// ============================================================================
// Specialized Node Creators
// ============================================================================

#let call-node(
  pos,
  color,
  name,
  stroke-width: default-stroke-width,
  outset: default-node-outset,
  content,
) = colored-node(pos, color: color, name: name, stroke-width: stroke-width, outset: outset, content)

#let result-node(
  pos,
  color,
  name,
  stroke-width: default-stroke-width,
  outset: default-node-outset,
  content,
) = colored-node(pos, color: color, name: name, stroke-width: stroke-width, outset: outset, content)

#let state-node(
  pos,
  title,
  desc,
  color,
  name,
  stroke-width: default-stroke-width,
  title-size: 8pt,
  desc-size: 6pt,
  outset: default-node-outset,
) = node(
  pos,
  stack(
    dir: ttb,
    spacing: 0.5em,
    text(size: title-size, weight: "bold")[#title],
    text(size: desc-size, style: "italic")[#desc],
  ),
  fill: color,
  stroke: accent(color) + stroke-width,
  outset: outset,
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
  outset: default-node-outset,
) = node(
  pos,
  align(left, text(size: text-size, [
    *#num. #title*
    #for item in items [
      - #item
    ]
  ])),
  fill: color,
  stroke: accent(color) + stroke-width,
  outset: outset,
  name: name,
)

#let layer(
  pos,
  name,
  label,
  desc,
  examples,
  color: colors.operator,
  stroke-width: default-stroke-width,
  label-size: 10pt,
  desc-size: 8pt,
  examples-size: 7pt,
  outset: default-node-outset,
) = {
  node(
    pos,
    name: name,
    fill: color,
    stroke: accent(color) + stroke-width,
    outset: outset,
    stack(
      dir: ttb,
      spacing: 0.6em,
      text(weight: "bold", size: label-size, label),
      text(size: desc-size, style: "italic", desc),
      text(size: examples-size, examples.join(" • ")),
    ),
  )
}

// ============================================================================
// Data Item Nodes
// ============================================================================

#let queue-item(
  pos,
  consumed,
  name,
  color: colors.neutral,
  stroke-width: default-stroke-width,
  outset: default-node-outset,
  content,
) = node(
  pos,
  if consumed { [#strike[#content]] } else { content },
  outset: outset,
  fill: if consumed { color.lighten(90%) } else { color },
  stroke: accent(colors.neutral) + stroke-width,
  shape: fletcher.shapes.rect,
  name: name,
)

#let data-item(
  pos,
  name,
  color: colors.data,
  stroke-width: default-stroke-width,
  outset: default-node-outset,
  content,
) = node(
  pos,
  content,
  outset: outset,
  fill: color,
  stroke: accent(color) + stroke-width,
  shape: fletcher.shapes.circle,
  name: name,
)

// ============================================================================
// Edge Creators
// ============================================================================

// Unified styled edge with optional color and label
#let styled-edge(
  from,
  to,
  ..args,
  label: none,
  color: none,
  stroke-width: default-stroke-width,
  label-size: 7pt,
) = {
  let positional-args = args.pos()
  let named-args = args.named()

  // Default to "->" if no mark is provided in positional args
  let mark = if positional-args.len() > 0 { positional-args.at(0) } else { "->" }

  edge(
    from,
    to,
    if label != none { text(size: label-size)[#label] },
    mark,
    stroke: if color != none { accent(color) + default-arrow-width } else { stroke-width },
    ..named-args,
  )
}

// Specialized: dashed link for queue connections
#let queue-link(
  from,
  to,
  label,
  color,
  stroke-width: default-stroke-width,
  ..args,
) = edge(
  from,
  to,
  text(size: 6pt)[#label],
  "--",
  stroke: accent(color) + stroke-width,
  ..args,
)
