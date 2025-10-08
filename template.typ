// ============================================================================
// Diagram styling constants
// ============================================================================

#let node-radius = 5pt
#let stroke-width = 1pt
#let arrow-width = 1pt
#let node-outset = 3pt
#let stroke-darken = 20%

// ============================================================================
// Color palette
// ============================================================================

#let colors = (
  title: (
    base: rgb("#b2edd7"),
    accent: rgb("#b2edd7").saturate(50%).darken(50%),
  ),
  stream: (
    base: rgb("#ebfdfd"),
    accent: rgb("#ebfdfd").saturate(50%).darken(50%),
  ),
  code: (
    base: rgb("#fcfcf5"),
    accent: rgb("#fcfcf5").darken(30%),
  ),
  operator: (
    base: rgb(255, 240, 230, 255),
    accent: rgb(255, 240, 230, 255).saturate(40%).darken(50%),
  ),
  data: (
    base: rgb(255, 243, 205, 255),
    accent: rgb(255, 243, 205, 255).darken(40%),
  ),
  pin: (
    base: rgb("#dde8ff"),
    accent: rgb("#386bd2"),
  ),
  state: (
    base: rgb(240, 255, 230, 255),
    accent: rgb(240, 255, 230, 255).darken(40%),
  ),
  ui: (
    base: rgb(240, 230, 255, 255),
    accent: rgb(240, 230, 255, 255).darken(40%),
  ),
  error: (
    base: rgb("#ffdede"),
    accent: rgb("#f4b4b4").saturate(50%),
  ),
  neutral: (
    base: rgb(240, 240, 240, 255),
    accent: rgb("#5c5c5c"),
  ),
)

// ============================================================================
// Diagram helper functions
// ============================================================================

#let styled-diagram(..args, body) = {
  import "@preview/fletcher:0.5.8": diagram
  diagram(
    node-stroke: stroke-width,
    node-corner-radius: node-radius,
    node-outset: node-outset,
    edge-stroke: arrow-width,
    ..args,
    body,
  )
}

#let hexagon(draw, center, size, stroke-color, label, label-pos, fill-color: none) = {
  let (cx, cy) = center
  let radius = size / 2

  let vertices = ()
  for i in range(6) {
    let angle = i * 60deg
    let x = cx + radius * calc.cos(angle)
    let y = cy + radius * calc.sin(angle)
    vertices.push((x, y))
  }

  if fill-color != none {
    draw.merge-path(fill: fill-color, stroke: none, {
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

  for i in range(6) {
    let start = vertices.at(i)
    let end = vertices.at(calc.rem(i + 1, 6))
    draw.circle(start, radius: 0.08, fill: stroke-color, stroke: none)
    draw.line(start, end, stroke: stroke-color + stroke-width)
  }

  draw.content(label-pos, text(size: 8pt, weight: "bold", label), anchor: "center")
}

// ============================================================================
// Presentation template
// ============================================================================

#let presentation-template(
  title: none,
  subtitle: none,
  author: none,
  event: none,
  location: none,
  duration: none,
  repository: none,
  body,
) = {
  set text(font: "Fira Sans", size: 0.9em)
  set page(width: 16cm, height: 9cm, margin: 1cm)
  set par(justify: true)

  show raw: set text(
    font: ("FiraCode Nerd Font Mono", "JetBrains Mono", "Cascadia Mono"),
    weight: 400,
    size: 1.0em,
  )
  show raw.where(block: true): it => block(
    fill: colors.code.base,
    inset: 1em,
    stroke: stroke-width + colors.code.accent,
    radius: node-radius,
    it,
  )
  show raw.where(block: false): it => text(size: 1.15em, weight: 500, it)

  set page(background: context {
    let page-num = counter(page).get().first()
    let total-pages = counter(page).final().first()

    if page-num == 1 or page-num == total-pages {
      rect(width: 100%, height: 100%, fill: colors.title.base)
    }
  })

  show heading.where(level: 1): align.with(center + horizon)
  show heading.where(level: 2): it => {
    v(4em)
    set text(fill: colors.title.accent, size: 1.3em)
    place(
      top + left,
      dx: -1.5cm,
      dy: -1.5cm,
      rect(width: 1.5cm, height: 100% + 3cm, fill: colors.title.base),
    )
    place(
      top + left,
      dx: 0cm,
      dy: -1.5cm,
      line(start: (0pt, 0pt), end: (0pt, 100% + 3cm), stroke: 2pt + colors.title.accent),
    )
    pad(left: 1.5em, align(center + horizon, it))
  }
  show heading.where(level: 3): it => {
    set text(style: "italic", size: 1.2em)
    underline(stroke: 1.5pt + colors.title.accent, offset: 0.2em, it)
    v(0.5em)
  }

  show link: underline.with(stroke: 1pt + colors.code.accent, offset: 0.15em)
  show table: set table(fill: colors.code.base, stroke: 0.5pt + colors.code.accent)
  show table.cell: set text(size: 10pt)
  show table.header: set text(weight: "bold")

  if title != none {
    pagebreak(weak: true)
    align(center + horizon)[
      #text(size: 2.2em, weight: "bold")[#title]

      #if subtitle != none {
        v(0.8em)
        text(size: 1.3em, style: "italic")[#subtitle]
      }

      #if author != none or event != none or location != none {
        v(3em)
        text(size: 1.1em)[
          #if author != none [*#author*]
          #if event != none and author != none [\ ]
          #if event != none [#event]
          #if location != none and (event != none or author != none) [ • ]
          #if location != none [#location]
        ]
      }

      #if duration != none {
        text(size: 0.9em, fill: colors.neutral.accent)[#duration]
      }

      #if repository != none {
        v(2em)
        text(size: 0.8em, fill: colors.neutral.accent)[
          Version with clickable links:\
          #link(repository)[#repository.replace("https://", "")]
        ]
      }
    ]
  }

  body
}

// ============================================================================
// Slide layout
// ============================================================================

#let slide(title: none, content) = {
  pagebreak(weak: true)

  if title != none {
    heading(level: 3, title)
    v(0.5em)
  }

  content

  place(
    bottom + right,
    dx: -1em,
    dy: -1em,
    context text(size: 10pt, fill: gray, counter(page).display()),
  )
}
