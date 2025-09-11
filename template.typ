#let colors = (
  accent: rgb("#05004E"),
  code-bg: rgb("#fcfcf5"),
  bg-accent: rgb("#b2edd7"),
)

#let presentation-template(
  title: none,
  subtitle: none,
  author: none,
  event: none,
  location: none,
  duration: none,
  body,
) = {
  // Typography
  set text(font: "Fira Sans")
  set page(width: 16cm, height: 9cm, margin: 1.5cm)
  set par(justify: true)

  // Raw text (code) styling
  show raw: set text(
    font: ("FiraCode Nerd Font Mono", "JetBrains Mono", "Cascadia Mono"),
    weight: 400,
    size: 1.0em,
  )
  show raw.where(block: true): it => block(
    fill: colors.code-bg,
    inset: 1em,
    stroke: 0.5pt + colors.accent,
    radius: 0pt,
    it,
  )
  show raw.where(block: false): it => text(size: 1.15em, weight: 500, it)
  // Page backgrounds
  set page(background: context {
    let page-num = counter(page).get().first()
    let total-pages = counter(page).final().first()

    if page-num == 1 or page-num == total-pages {
      rect(width: 100%, height: 100%, fill: colors.bg-accent)
    }
  })

  // Headings
  show heading.where(level: 1): align.with(center + horizon)
  show heading.where(level: 2): it => {
    place(
      top + left,
      dx: -1.5cm,
      dy: -1.5cm,
      rect(width: 1.5cm, height: 100% + 3cm, fill: colors.bg-accent),
    )
    place(
      top + left,
      dx: 0cm,
      dy: -1.5cm,
      line(start: (0pt, 0pt), end: (0pt, 100% + 3cm), stroke: 2pt + colors.accent),
    )
    pad(left: 1.5em, align(center + horizon, it))
  }
  show heading.where(level: 3): it => {
    set text(style: "italic")
    underline(stroke: 1.5pt + colors.accent, offset: 0.2em, it)
  }

  // Content styling
  show link: underline.with(stroke: 1pt + colors.accent, offset: 0.15em)
  show table: set table(fill: colors.code-bg, stroke: 0.5pt + colors.accent)
  show table.cell: set text(size: 10pt)
  show table.header: set text(weight: "bold")

  // Generate title slide if metadata provided
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
        v(2.5em)
        text(size: 0.9em, fill: gray)[#duration]
      }
    ]
  }

  body
}

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

