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
    draw.content(
      (center.at(0), center.at(1) + radius + 0.15),
      text(size: label-size, weight: "bold")[#content],
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
  label-size: 6pt,
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
    let center-x = (from.at(0) + to.at(0)) / 2
    let top-y = calc.max(from.at(1), to.at(1)) + 0.15
    draw.content((center-x, top-y), text(size: label-size)[#content], anchor: "south")
  }
}

#let styled-triangle(
  draw,
  p1,
  p2,
  p3,
  color,
  stroke-width: default-stroke-width,
  label-size: 9pt,
  content,
) = {
  draw.merge-path(fill: color, stroke: accent(color) + stroke-width, {
    draw.line(p1, p2)
    draw.line((), p3)
    draw.line((), p1)
  })
  if content != none {
    let center-x = (p1.at(0) + p2.at(0) + p3.at(0)) / 3
    let center-y = (p1.at(1) + p2.at(1) + p3.at(1)) / 3
    draw.content((center-x, center-y), text(size: label-size)[#content], anchor: "center")
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
  background: none,
  padding: 0.2,
  content,
) = {
  if background != none {
    draw.content(
      pos,
      box(
        fill: background,
        inset: padding * 1em,
        radius: 0.2em,
        text(size: size, weight: if weight != none { weight } else { "bold" })[#content],
      ),
      anchor: anchor,
    )
  } else {
    draw.content(
      pos,
      text(size: size, weight: if weight != none { weight } else { "bold" })[#content],
      anchor: anchor,
    )
  }
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
    draw.content((center.at(0), center.at(1) + radius + 0.2), text[#label], anchor: "center")
  }
}
