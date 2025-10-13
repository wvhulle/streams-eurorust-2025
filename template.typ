#import "lib/theme.typ": accent, colors, stroke-width, node-radius

// ============================================================================
// Title slide
// ============================================================================

#let render-title-slide(
  title: none,
  subtitle: none,
  author: none,
  event: none,
  location: none,
  duration: none,
  repository: none,
) = {
  if title == none { return }

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
      text(size: 0.9em)[#duration]
    }

    #if repository != none {
      v(2em)
      text(size: 0.8em)[
        Version with clickable links:\
        #link(repository)[#repository.replace("https://", "")]
      ]
    }
  ]
}

// ============================================================================
// Chapter heading styling (level 2)
// ============================================================================

#let style-chapter(heading-content) = {
  v(4em)
  set text(fill: accent(colors.title), size: 1.3em)
  place(
    top + left,
    dx: -1.5cm,
    dy: -1.5cm,
    rect(width: 1.5cm, height: 100% + 3cm, fill: colors.title),
  )
  place(
    top + left,
    dx: 0cm,
    dy: -1.5cm,
    line(start: (0pt, 0pt), end: (0pt, 100% + 3cm), stroke: 2pt + accent(colors.title)),
  )
  pad(left: 1.5em, align(center + horizon, heading-content))
}

// ============================================================================
// Slide heading styling (level 3)
// ============================================================================

#let style-slide-heading(heading-content) = {
  set text(style: "italic", size: 1.2em)
  underline(stroke: 1.5pt, offset: 0.2em, heading-content)
  v(0.5em)
}

// ============================================================================
// Code block styling
// ============================================================================

#let style-code-block(raw-content) = block(
  fill: colors.code,
  inset: 1em,
  stroke: stroke-width + accent(colors.code),
  radius: node-radius,
  raw-content,
)

// ============================================================================
// Page background (title and end slides)
// ============================================================================

#let page-background() = context {
  let page-num = counter(page).get().first()
  let total-pages = counter(page).final().first()

  if page-num == 1 or page-num == total-pages {
    rect(width: 100%, height: 100%, fill: colors.title)
  }
}

// ============================================================================
// Main presentation template
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
  // Base text and page settings
  set text(font: "Fira Sans", size: 0.9em)
  set page(width: 16cm, height: 9cm, margin: 1cm)
  set par(justify: true)

  // Quote styling
  set quote(block: true, quotes: true)

  // Code font settings
  show raw: set text(
    font: ("FiraCode Nerd Font Mono", "JetBrains Mono", "Cascadia Mono"),
    weight: 400,
    size: 1.0em,
  )

  // Code block styling
  show raw.where(block: true): style-code-block
  show raw.where(block: false): it => text(size: 1.15em, weight: 500, it)

  // Page background for title and end slides
  set page(background: page-background())

  // Heading styling
  show heading.where(level: 1): align.with(center + horizon)
  show heading.where(level: 2): style-chapter
  show heading.where(level: 3): style-slide-heading

  // Link styling
  show link: underline.with(stroke: 1pt, offset: 0.15em)

  // Table styling
  show table: set table(fill: colors.action, stroke: 0.5pt + accent(colors.action))
  show table.cell: set text(size: 10pt)
  show table.header: set text(weight: "bold")

  // Render title slide if title is provided
  render-title-slide(
    title: title,
    subtitle: subtitle,
    author: author,
    event: event,
    location: location,
    duration: duration,
    repository: repository,
  )

  body
}

// ============================================================================
// Slide layout
// ============================================================================

#let slide(title: none, content) = {
  pagebreak(weak: true)

  if title != none {
    heading(level: 3, title)
    v(0.1em)
  }

  content

  place(
    bottom + right,
    dx: -1em,
    dy: -1em,
    context text(size: 10pt, fill: gray, counter(page).display()),
  )
}
