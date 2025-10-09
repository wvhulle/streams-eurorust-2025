#import "colors.typ": accent, colors
#import "constants.typ": stroke-width as default-stroke-width

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
