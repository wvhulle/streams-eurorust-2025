#import "theme.typ": accent, colors, stroke-width as default-stroke-width

#let conclusion(
  color: colors.operator,
  stroke-width: default-stroke-width,
  inset: 0.7em,
  radius: 4pt,
  content,
) = rect(
  fill: color,
  stroke: accent(color) + stroke-width,
  inset: inset,
  radius: radius,
  content,
)

#let legend(items) = {
  align(center)[
    #grid(
      columns: items.len(),
      column-gutter: 2em,
      ..items
        .map(item => {
          (
            align(center)[
              #rect(width: 2em, height: 0.8em, fill: item.color, stroke: accent(item.color) + 0.8pt)
              #v(0.3em)
              #text(size: 8pt)[#item.label]
            ],
          )
        })
        .flatten()
    )]
}

#let callout(
  title,
  body,
  color: colors.stream,
  stroke-width: default-stroke-width,
  icon: none,
  radius: 4pt,
) = rect(
  fill: color.lighten(95%),
  stroke: accent(color) + stroke-width,
  radius: radius,
  inset: 1em,
  stack(
    dir: ttb,
    spacing: 0.5em,
    if icon != none {
      grid(
        columns: (auto, 1fr),
        column-gutter: 0.5em,
        text(size: 1.2em)[#icon],
        text(weight: "bold", size: 10pt)[#title]
      )
    } else {
      text(weight: "bold", size: 10pt)[#title]
    },
    text(size: 9pt)[#body]
  )
)

#let info-box(
  content,
  color: colors.stream,
  stroke-width: default-stroke-width,
  radius: 4pt,
  inset: 0.8em,
) = rect(
  fill: color,
  stroke: accent(color) + stroke-width,
  radius: radius,
  inset: inset,
  content
)

#let warning-box(
  content,
  stroke-width: default-stroke-width,
  radius: 4pt,
  inset: 0.8em,
) = rect(
  fill: colors.action,
  stroke: accent(colors.action) + stroke-width,
  radius: radius,
  inset: inset,
  stack(
    dir: ltr,
    spacing: 0.5em,
    text(size: 1.2em)[⚠],
    content
  )
)

#let error-box(
  content,
  stroke-width: default-stroke-width,
  radius: 4pt,
  inset: 0.8em,
) = rect(
  fill: colors.error,
  stroke: accent(colors.error) + stroke-width,
  radius: radius,
  inset: inset,
  stack(
    dir: ltr,
    spacing: 0.5em,
    text(size: 1.2em)[❌],
    content
  )
)

#let success-box(
  content,
  stroke-width: default-stroke-width,
  radius: 4pt,
  inset: 0.8em,
) = rect(
  fill: colors.state,
  stroke: accent(colors.state) + stroke-width,
  radius: radius,
  inset: inset,
  stack(
    dir: ltr,
    spacing: 0.5em,
    text(size: 1.2em)[✅],
    content
  )
)

#let code-block(
  code,
  language: none,
  color: colors.code,
  stroke-width: default-stroke-width,
  radius: 4pt,
  inset: 1em,
) = rect(
  fill: color,
  stroke: accent(color) + stroke-width,
  radius: radius,
  inset: inset,
  raw(code, lang: language)
)

#let quote-block(
  quote,
  author: none,
  color: colors.neutral,
  stroke-width: default-stroke-width,
  radius: 4pt,
  inset: 1em,
) = rect(
  fill: color.lighten(90%),
  stroke: (left: accent(color) + stroke-width * 3),
  radius: radius,
  inset: inset,
  stack(
    dir: ttb,
    spacing: 0.5em,
    text(style: "italic", size: 9pt)[#quote],
    if author != none {
      align(right, text(size: 8pt, weight: "bold")[— #author])
    }
  )
)

#let highlight-box(
  content,
  color: colors.data,
  stroke-width: default-stroke-width,
  radius: 4pt,
  inset: 0.6em,
) = box(
  fill: color,
  stroke: accent(color) + stroke-width,
  radius: radius,
  inset: inset,
  content
)

#let step-indicator(
  current-step,
  total-steps,
  color: colors.operator,
  size: 0.8em,
) = {
  let indicators = ()
  for i in range(1, total-steps + 1) {
    if i == current-step {
      indicators.push(circle(radius: size, fill: color, stroke: accent(color) + 1pt))
    } else if i < current-step {
      indicators.push(circle(radius: size, fill: accent(color), stroke: accent(color) + 1pt))
    } else {
      indicators.push(circle(radius: size, fill: color.lighten(90%), stroke: accent(color) + 1pt))
    }
  }
  stack(dir: ltr, spacing: 1em, ..indicators)
}

#let progress-bar(
  progress,
  total: 100,
  color: colors.state,
  bg-color: colors.neutral,
  height: 0.5em,
  width: 10em,
  radius: 2pt,
) = {
  let fill-width = width * progress / total
  stack(
    dir: ltr,
    spacing: 0pt,
    rect(width: fill-width, height: height, fill: color, radius: radius),
    rect(width: width - fill-width, height: height, fill: bg-color, radius: radius)
  )
}

#let badge(
  content,
  color: colors.stream,
  text-color: white,
  radius: 3pt,
  inset: (x: 0.5em, y: 0.2em),
) = box(
  fill: color,
  radius: radius,
  inset: inset,
  text(fill: text-color, size: 7pt, weight: "bold")[#content]
)

#let tag(
  content,
  color: colors.neutral,
  radius: 2pt,
  inset: (x: 0.4em, y: 0.1em),
) = box(
  fill: color,
  stroke: accent(color) + 0.5pt,
  radius: radius,
  inset: inset,
  text(size: 6pt)[#content]
)

#let separator(
  color: colors.neutral,
  thickness: 1pt,
  style: "solid",
) = {
  let stroke-style = if style == "dashed" {
    (dash: "dashed")
  } else if style == "dotted" {
    (dash: "dotted")
  } else {
    none
  }

  line(
    length: 100%,
    stroke: color + thickness + if stroke-style != none { stroke-style } else { () }
  )
}

#let icon-text(
  icon,
  text-content,
  spacing: 0.3em,
  icon-size: 1em,
  text-size: 9pt,
) = stack(
  dir: ltr,
  spacing: spacing,
  text(size: icon-size)[#icon],
  text(size: text-size)[#text-content]
)

#let tooltip(
  content,
  tooltip-text,
  color: colors.stream,
  radius: 3pt,
  inset: 0.3em,
) = box(
  baseline: 0.2em,
  stack(
    dir: ttb,
    spacing: 0.1em,
    content,
    text(size: 6pt, fill: accent(color))[#tooltip-text]
  )
)

#let accordion-item(
  title,
  content,
  expanded: false,
  color: colors.neutral,
  stroke-width: default-stroke-width,
  radius: 4pt,
) = {
  let header = rect(
    fill: color,
    stroke: accent(color) + stroke-width,
    radius: (top: radius),
    inset: 0.8em,
    stack(
      dir: ltr,
      spacing: 0.5em,
      text(size: 1.2em)[#if expanded { "▼" } else { "▶" }],
      text(weight: "bold", size: 9pt)[#title]
    )
  )

  if expanded {
    stack(
      dir: ttb,
      spacing: 0pt,
      header,
      rect(
        fill: color.lighten(95%),
        stroke: (
          left: accent(color) + stroke-width,
          right: accent(color) + stroke-width,
          bottom: accent(color) + stroke-width
        ),
        radius: (bottom: radius),
        inset: 0.8em,
        content
      )
    )
  } else {
    header
  }
}

#let timeline-item(
  time,
  title,
  description,
  color: colors.state,
  stroke-width: default-stroke-width,
) = grid(
  columns: (auto, 1fr),
  column-gutter: 1em,
  row-gutter: 0.5em,
  stack(
    dir: ttb,
    spacing: 0.2em,
    align: center,
    circle(radius: 0.3em, fill: color, stroke: accent(color) + stroke-width),
    text(size: 7pt, weight: "bold")[#time]
  ),
  stack(
    dir: ttb,
    spacing: 0.3em,
    text(size: 9pt, weight: "bold")[#title],
    text(size: 8pt)[#description]
  )
)