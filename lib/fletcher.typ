#import "@preview/fletcher:0.5.8" as fletcher: diagram, edge, node
#import "theme.typ": (
  arrow-width as default-arrow-width, node-outset as default-node-outset, node-radius as default-node-radius,
  stroke-width as default-stroke-width, accent, colors
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
  inset: -1pt,
  content,
) = node(
  pos,
  text(size: 2.5em, content),
  fill: if color == none { none } else { color },
  stroke: if color == none { none } else { accent(color) + stroke-width },
  outset: outset,
  inset: inset,
  shape: fletcher.shapes.circle,
  name: name,
)

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

#let conditional-node(
  pos,
  condition,
  true-content,
  false-content,
  color: colors.action,
  name,
  stroke-width: default-stroke-width,
  outset: default-node-outset,
) = node(
  pos,
  stack(
    dir: ttb,
    spacing: 0.3em,
    text(size: 7pt, weight: "bold")[#condition],
    grid(
      columns: 2,
      column-gutter: 0.5em,
      text(size: 6pt, fill: colors.success)[✓ #true-content],
      text(size: 6pt, fill: colors.error)[✗ #false-content],
    ),
  ),
  fill: color,
  stroke: accent(color) + stroke-width,
  outset: outset,
  shape: fletcher.shapes.diamond,
  name: name,
)

#let process-node(
  pos,
  name,
  process-name,
  inputs,
  outputs,
  color: colors.operator,
  stroke-width: default-stroke-width,
  outset: default-node-outset,
) = node(
  pos,
  stack(
    dir: ttb,
    spacing: 0.4em,
    text(size: 8pt, weight: "bold")[#process-name],
    text(size: 6pt)[In: #inputs.join(", ")],
    text(size: 6pt)[Out: #outputs.join(", ")],
  ),
  fill: color,
  stroke: accent(color) + stroke-width,
  outset: outset,
  shape: fletcher.shapes.rect,
  name: name,
)

#let timeline-node(
  pos,
  timestamp,
  event,
  details,
  color: colors.state,
  name,
  stroke-width: default-stroke-width,
  outset: default-node-outset,
) = node(
  pos,
  stack(
    dir: ttb,
    spacing: 0.3em,
    text(size: 7pt, weight: "bold", fill: accent(color))[#timestamp],
    text(size: 8pt)[#event],
    text(size: 6pt, style: "italic")[#details],
  ),
  fill: color,
  stroke: accent(color) + stroke-width,
  outset: outset,
  name: name,
)

#let metric-node(
  pos,
  metric-name,
  value,
  unit,
  trend: none,
  color: colors.data,
  name,
  stroke-width: default-stroke-width,
  outset: default-node-outset,
) = node(
  pos,
  stack(
    dir: ttb,
    spacing: 0.2em,
    text(size: 6pt)[#metric-name],
    text(size: 10pt, weight: "bold")[#value #unit],
    if trend != none {
      text(size: 5pt, fill: if trend > 0 { colors.success } else if trend < 0 { colors.error } else { colors.neutral })[
        #if trend > 0 { "↗" } else if trend < 0 { "↘" } else { "→" }
      ]
    },
  ),
  fill: color,
  stroke: accent(color) + stroke-width,
  outset: outset,
  shape: fletcher.shapes.circle,
  name: name,
)

#let group-node(
  pos,
  group-name,
  members,
  color: colors.neutral,
  name,
  stroke-width: default-stroke-width,
  outset: default-node-outset,
) = node(
  pos,
  stack(
    dir: ttb,
    spacing: 0.3em,
    text(size: 8pt, weight: "bold")[#group-name],
    text(size: 6pt)[#members.len() members],
    for member in members.slice(0, calc.min(3, members.len())) {
      text(size: 5pt)[• #member]
    },
    if members.len() > 3 {
      text(size: 5pt, style: "italic")[...and #(members.len() - 3) more]
    }
  ),
  fill: color,
  stroke: accent(color) + stroke-width,
  outset: outset,
  name: name,
)

#let annotation-edge(
  from,
  to,
  annotation,
  color: colors.neutral,
  stroke-width: default-stroke-width,
  ..args,
) = edge(
  from,
  to,
  text(size: 6pt, fill: accent(color))[#annotation],
  "-.->",
  stroke: accent(color) + stroke-width,
  ..args,
)

#let bidirectional-edge(
  from,
  to,
  forward-label: none,
  backward-label: none,
  color: none,
  stroke-width: default-stroke-width,
  ..args,
) = {
  edge(
    from,
    to,
    if forward-label != none { text(size: 6pt)[#forward-label] },
    "<->",
    stroke: if color != none { accent(color) + stroke-width } else { stroke-width },
    ..args,
  )
}

#let parallel-edges(
  from,
  to,
  labels,
  colors-list: none,
  offset: 0.1,
  stroke-width: default-stroke-width,
  ..args,
) = {
  for (i, label) in labels.enumerate() {
    let y-offset = (i - (labels.len() - 1) / 2) * offset
    let edge-color = if colors-list != none { colors-list.at(calc.rem(i, colors-list.len())) } else { none }
    edge(
      (from, (0, y-offset)),
      (to, (0, y-offset)),
      text(size: 6pt)[#label],
      "->",
      stroke: if edge-color != none { accent(edge-color) + stroke-width } else { stroke-width },
      ..args,
    )
  }
}