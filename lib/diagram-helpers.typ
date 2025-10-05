
#import "@preview/fletcher:0.5.8" as fletcher: diagram, edge, node
#import "@preview/cetz:0.4.2": canvas, draw
#import "constants.typ": (
  arrow-width as default-arrow-width, colors, node-outset as default-node-outset, node-radius as default-node-radius,
  stroke-width as default-stroke-width,
)

// =====================================

#let styled-content(
  draw,
  pos,
  color,
  size: 6pt,
  weight: none,
  anchor: "center",
  content,
) = {
  let text-color = color.darken(70%)
  draw.content(
    pos,
    text(size: size, weight: if weight != none { weight } else { "bold" }, fill: text-color)[#content],
    anchor: anchor,
  )
}

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
  color: blue,
  name: none,
  stroke-width: default-stroke-width,
  outset: default-node-outset,
  shape: auto,
  content,
) = node(
  pos,
  content,
  fill: color,
  stroke: color.saturate(50%).darken(20%) + stroke-width,
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
) = colored-node(pos, color: color, name: name, stroke-width: stroke-width, outset: outset, content)

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
  stroke: color.darken(70%) + stroke-width,
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
  stroke: color.darken(70%) + stroke-width,
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
    stroke: color.darken(70%) + stroke-width,
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
  colors,
  stroke-width: default-stroke-width,
  outset: default-node-outset,
  content,
) = node(
  pos,
  if consumed { [#strike[#content]] } else { content },
  outset: outset,
  fill: if consumed { colors.neutral.lighten(90%) } else { colors.neutral.darken(10%) },
  stroke: colors.neutral.darken(70%) + stroke-width,
  shape: fletcher.shapes.rect,
  name: name,
)

#let data-item(
  pos,
  name,
  colors,
  stroke-width: default-stroke-width,
  outset: default-node-outset,
  content,
) = node(
  pos,
  content,
  outset: outset,
  fill: colors.data,
  stroke: colors.data.darken(70%) + stroke-width,
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
  label-size: 6pt,
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
    stroke: if color != none { color.saturate(50%).darken(10%) + stroke-width } else { stroke-width },
    ..named-args,
  )
}

// Specialized: dashed link for queue connections
#let queue-link(
  from,
  to,
  label,
  colors,
  stroke-width: default-stroke-width,
  ..args,
) = edge(
  from,
  to,
  text(fill: colors.neutral.darken(70%), size: 6pt)[#label],
  "--",
  stroke: colors.neutral.darken(70%) + stroke-width,
  ..args,
)

// ============================================================================
// Canvas Helpers
// ============================================================================

// Styled canvas primitives that apply darkening automatically
#let styled-circle(
  draw,
  center,
  color,
  radius: 0.5,
  label: none,
  label-size: 6pt,
  stroke-width: default-stroke-width,
) = {
  draw.circle(
    center,
    radius: radius,
    fill: color,
    stroke: color.darken(70%) + stroke-width,
  )
  if label != none {
    let text-color = { color.saturate(100%).darken(70%) }
    draw.content(
      (center.at(0), center.at(1) + radius + 0.15),
      text(size: label-size, fill: text-color)[#label],
      anchor: "center",
    )
  }
}

#let styled-rect(
  draw,
  from,
  to,
  color,
  stroke-width: default-stroke-width,
  radius: none,
  label: none,
  label-size: 7pt,
) = {
  draw.rect(
    from,
    to,
    fill: color,
    stroke: color.darken(70%) + stroke-width,
    radius: radius,
  )
  if label != none {
    let text-color = { color.darken(70%) }
    let center-x = (from.at(0) + to.at(0)) / 2
    let top-y = calc.max(from.at(1), to.at(1)) + 0.15
    draw.content((center-x, top-y), text(size: label-size, fill: text-color)[#label], anchor: "south")
  }
}

#let styled-line(
  draw,
  from,
  to,
  color,
  stroke-width: default-stroke-width,
  mark: none,
) = {
  draw.line(
    from,
    to,
    stroke: color.darken(70%) + stroke-width,
    mark: mark,
  )
}

#let styled-content(
  draw,
  pos,
  color,
  size: 6pt,
  weight: none,
  anchor: "center",
  content,
) = {
  let text-color = color.saturate(100%).darken(20%)
  draw.content(
    pos,
    text(size: size, weight: if weight != none { weight } else { "bold" }, fill: text-color)[#content],
    anchor: anchor,
  )
}

#let hexagon(
  draw,
  center,
  size,
  color: white,
  stroke-width: default-stroke-width,
  label,
) = {
  let stroke-color = color.saturate(50%).darken(10%)
  let radius = size / 2
  draw.circle(
    center,
    radius: radius,
    stroke: stroke-color + stroke-width,
    fill: color,
  )
  if label != none {
    draw.content((center.at(0), center.at(1) + radius + 0.2), text(fill: stroke-color)[#label], anchor: "center")
  }
}
