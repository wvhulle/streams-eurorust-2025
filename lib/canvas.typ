#import "@preview/cetz:0.4.2": canvas, draw
#import "constants.typ": stroke-width as default-stroke-width
#import "colors.typ": accent

// ============================================================================
// Canvas Helpers
// ============================================================================

// Styled canvas primitives that apply darkening automatically
#let styled-circle(
  draw,
  center,
  color,
  radius: 0.5,
  label-size: 6pt,
  stroke-width: default-stroke-width,
  content,
) = {
  draw.circle(
    center,
    radius: radius,
    fill: color,
    stroke: accent(color) + stroke-width,
  )
  if label != none {
    let text-color = { accent(color) }
    draw.content(
      (center.at(0), center.at(1) + radius + 0.15),
      text(size: label-size, fill: text-color, weight: "bold")[#content],
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
  label-size: 9pt,
  content,
) = {
  draw.rect(
    from,
    to,
    fill: color,
    stroke: accent(color) + stroke-width,
    radius: radius,
  )
  if content != none {
    let text-color = { accent(color) }
    let center-x = (from.at(0) + to.at(0)) / 2
    let top-y = calc.max(from.at(1), to.at(1)) + 0.15
    draw.content((center-x, top-y), text(size: label-size, fill: text-color)[#content], anchor: "south")
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
    stroke: accent(color) + stroke-width,
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
  let text-color = accent(color)
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
  let stroke-color = accent(color)
  let radius = size / 2
  let (cx, cy) = center
  let radius = size / 2

  // Calculate hexagon vertices (6 points around circle)
  let vertices = ()
  for i in range(6) {
    let angle = i * 60deg
    let x = cx + radius * calc.cos(angle)
    let y = cy + radius * calc.sin(angle)
    vertices.push((x, y))
  }

  // Fill hexagon if color provided
  if color != none {
    draw.merge-path(fill: color, stroke: none, {
      for i in range(6) {
        let vertex = vertices.at(i)
        if i == 0 {
          draw.line(vertex, vertex)
        } else {
          draw.line((), vertex)
        }
      }
      draw.line((), vertices.at(0))
    })
  }

  // Draw hexagon outline using line() calls
  for i in range(6) {
    let start = vertices.at(i)
    let end = vertices.at(calc.rem(i + 1, 6))
    draw.circle(start, radius: 0.08, fill: stroke-color, stroke: none)
    draw.line(start, end, stroke: stroke-color + stroke-width)
  }
  if label != none {
    draw.content((center.at(0), center.at(1) + radius + 0.2), text(fill: stroke-color)[#label], anchor: "center")
  }
}
