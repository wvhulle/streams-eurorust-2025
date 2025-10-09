// =====================================
// Color Helper Functions
// =====================================

// Create accent color from base color with saturation and darkening
#let accent(color, sat: 90%, dark: 25%) = {
  let rgb_color = rgb(color)
  let comps = rgb_color.components()
  let r = comps.at(0)
  let g = comps.at(1)
  let b = comps.at(2)

  // Check if grayscale (all components within 5% of each other)
  if calc.abs(r - g) < 5% and calc.abs(g - b) < 5% {
    rgb_color.darken(dark)
  } else {
    rgb_color.saturate(sat).darken(dark)
  }
}

#let colors = (
  title: color.rgb("#b2edd7"),
  code: color.rgb("#fcfcf5"),
  neutral: color.hsl(0deg, 0%, 90.98%), //  concepts in Rust that are not specific to streams
  stream: color.hsl(200deg, 65%, 92%), //  all `Stream`s, flowing, continuous
  operator: color.hsl(45.16deg, 100%, 88.76%), // stream transformation with stream operators or combinators
  data: color.hsl(330.91deg, 57.89%, 95%), //  values, allocations, fundamental data types
  state: color.hsl(140deg, 34.88%, 84.71%), //  low-level state of stream
  action: color.hsl(21.25deg, 68.57%, 86.27%), //  primitive operation on a stream
  pin: color.hsl(240deg, 100%, 93.92%), //  pinning, methods of Pin type, `Unpin`, stability
  error: color.hsl(0deg, 65%, 85%), //  errors, warnings
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
