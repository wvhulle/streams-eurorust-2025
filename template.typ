// Color scheme (willemvanhulle.tech blog)
#let colors = (
  accent: rgb("#05004E"),
  code-bg: rgb("#fcfcf5"),
  prose-bg: white,
  bg-accent: rgb("#b2edd7"),
  gray: gray,
)

// Template function that applies all styling
#let presentation-template(body) = {
  // Typography
  set text(font: "Fira Sans")
  show raw: set text(font: ("Fira Code", "JetBrains Mono", "Liberation Mono"))

  // Color section pages, first and last pages
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
    // Color the left margin extending to full page height
    place(top + left, dx: -1.5cm, dy: -1.5cm, rect(width: 1.5cm, height: 100% + 3cm, fill: colors.bg-accent))
    align(center + horizon, it)
  }
  show heading.where(level: 3): it => {
    set text(style: "italic")
    underline(stroke: 1.5pt + colors.accent, offset: 0.2em, it)
  }

  // Links
  show link: underline.with(stroke: 1pt + colors.accent, offset: 0.15em)

  // Code styling
  show raw.where(block: false): set text(weight: "black", size: 1.15em)
  show raw.where(block: true): it => block(
    fill: colors.code-bg,
    inset: 1em,
    stroke: 0.5pt + colors.accent,
    radius: 0pt,
    text(weight: "black", it),
  )

  // Tables
  show table: set table(fill: colors.code-bg, stroke: 0.5pt + colors.accent)
  show table.cell: set text(size: 10pt)
  show table.header: set text(weight: "bold")

  // Apply styling to body
  body
}

// Slide function
#let slide(title: none, content) = {
  pagebreak(weak: true)
  if title != none {
    heading(level: 3, title)
    v(0.5em)
  }
  content
  place(bottom + right, dx: -1em, dy: -1em, context text(size: 10pt, fill: colors.gray, counter(page).display()))
}

