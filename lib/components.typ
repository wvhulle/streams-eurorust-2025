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