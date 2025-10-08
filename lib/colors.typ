// =====================================
// Color Helper Functions
// =====================================

// Create accent color from base color with saturation and darkening
#let accent(color, sat: 90%, dark: 10%) = rgb(color).saturate(sat).darken(dark)


#let colors = (
  neutral: color.hsl(142.67deg, 100%, 91.18%), //  concepts in Rust that are not specific to streams
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
