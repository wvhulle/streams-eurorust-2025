#let stroke-width = 0.5pt
#let arrow-width = 1pt
#let node-radius = 5pt
#let node-outset = 2pt

#let accent(color, sat: 90%, dark: 25%) = {
  let rgb_color = rgb(color)
  let comps = rgb_color.components()
  let r = comps.at(0)
  let g = comps.at(1)
  let b = comps.at(2)

  if calc.abs(r - g) < 5% and calc.abs(g - b) < 5% {
    rgb_color.darken(dark)
  } else {
    rgb_color.saturate(sat).darken(dark)
  }
}

#let colors = (
  title: color.rgb("#b2edd7"),
  code: color.rgb("#fcfcf5"),
  neutral: color.hsl(0deg, 0%, 90.98%),
  stream: color.hsl(200deg, 65%, 92%),
  operator: color.hsl(45.16deg, 100%, 88.76%),
  data: color.hsl(330.91deg, 57.89%, 95%),
  state: color.hsl(140deg, 34.88%, 84.71%),
  action: color.hsl(21.25deg, 68.57%, 86.27%),
  pin: color.hsl(240deg, 100%, 93.92%),
  error: color.hsl(0deg, 65%, 85%),
)

#let theme-variants = (
  light: (
    bg: white,
    text: black,
    accent-multiplier: 1.0,
  ),
  dark: (
    bg: rgb("#1e1e1e"),
    text: white,
    accent-multiplier: 0.7,
  ),
  high-contrast: (
    bg: white,
    text: black,
    accent-multiplier: 1.3,
  ),
)

#let current-theme = theme-variants.light

#let themed-color(color-name) = {
  let base-color = colors.at(color-name)
  if current-theme.accent-multiplier != 1.0 {
    if current-theme.accent-multiplier > 1.0 {
      base-color.saturate((current-theme.accent-multiplier - 1.0) * 50%)
    } else {
      base-color.desaturate((1.0 - current-theme.accent-multiplier) * 50%)
    }
  } else {
    base-color
  }
}

#let color-palette(colors-list, columns: 4) = {
  grid(
    columns: columns,
    column-gutter: 1em,
    row-gutter: 1em,
    ..colors-list.map(item => {
      stack(
        dir: ttb,
        spacing: 0.3em,
        rect(width: 3em, height: 2em, fill: item.color, stroke: accent(item.color) + stroke-width),
        align(center, text(size: 7pt, item.name))
      )
    })
  )
}

#let gradient-color(from-color, to-color, steps: 5) = {
  let colors = ()
  for i in range(steps) {
    let ratio = i / (steps - 1)
    let mixed = from-color.mix(to-color, ratio * 100%)
    colors.push(mixed)
  }
  colors
}

#let complementary-color(base-color) = {
  let rgb_color = rgb(base-color)
  let comps = rgb_color.components()
  let r = 255 - comps.at(0) * 255
  let g = 255 - comps.at(1) * 255
  let b = 255 - comps.at(2) * 255
  rgb(r, g, b)
}

#let analogous-colors(base-color, count: 3, shift: 30deg) = {
  let colors = (base-color,)
  for i in range(1, count) {
    let shifted = base-color.rotate(shift * i)
    colors.push(shifted)
  }
  colors
}

#let color-tints(base-color, levels: 5) = {
  let tints = ()
  for i in range(levels) {
    let lightness = 20% + (i * 60% / (levels - 1))
    tints.push(base-color.lighten(lightness))
  }
  tints
}

#let color-shades(base-color, levels: 5) = {
  let shades = ()
  for i in range(levels) {
    let darkness = 20% + (i * 60% / (levels - 1))
    shades.push(base-color.darken(darkness))
  }
  shades
}

#let semantic-colors = (
  success: color.hsl(120deg, 50%, 75%),
  warning: color.hsl(45deg, 80%, 75%),
  danger: color.hsl(0deg, 60%, 75%),
  info: color.hsl(210deg, 60%, 75%),
)

#let apply-theme-variant(variant-name) = {
  current-theme = theme-variants.at(variant-name)
}

#let spacing = (
  xs: 0.25em,
  sm: 0.5em,
  md: 1em,
  lg: 1.5em,
  xl: 2em,
  xxl: 3em,
)

#let typography = (
  sizes: (
    tiny: 6pt,
    small: 7pt,
    normal: 8pt,
    medium: 9pt,
    large: 10pt,
    huge: 12pt,
  ),
  weights: (
    light: "light",
    normal: "regular",
    medium: "medium",
    bold: "bold",
    black: "black",
  ),
)

#let border-radius = (
  flat: 0pt,
  sm: 2pt,
  md: 4pt,
  lg: 8pt,
  round: 50%,
)

#let shadows = (
  flat: none,
  sm: (offset: (0pt, 1pt), blur: 2pt, color: black.transparentize(80%)),
  md: (offset: (0pt, 2pt), blur: 4pt, color: black.transparentize(75%)),
  lg: (offset: (0pt, 4pt), blur: 8pt, color: black.transparentize(70%)),
)

#let apply-shadow(element, shadow-level) = {
  let shadow = shadows.at(shadow-level)
  if shadow != none {
    box(element, shadow: shadow)
  } else {
    element
  }
}

#let stroke-styles = (
  solid: (),
  dashed: (dash: "dashed"),
  dotted: (dash: "dotted"),
  thick: stroke-width * 2,
  thin: stroke-width * 0.5,
)

#let get-stroke-style(style-name, color: black) = {
  let style = stroke-styles.at(style-name)
  if type(style) == "length" {
    color + style
  } else if style == () {
    color + stroke-width
  } else {
    color + stroke-width + style
  }
}