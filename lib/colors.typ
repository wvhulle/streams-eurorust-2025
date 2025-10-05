// =====================================
// Color Helper Functions
// =====================================

// Create accent color from base color with saturation and darkening
#let accent(color, sat: 90%, dark: 40%) = rgb(color).saturate(sat).darken(dark)


#let colors = (
  neutral: color.hsl(162deg, 50%, 85%), // Soft mint - neutral, calm
  stream: color.hsl(207deg, 55%, 87%), // Light blue - flowing, continuous
  operator: color.hsl(48deg, 85%, 90%), // Warm yellow - transformation, processing
  data: color.hsl(282deg, 40%, 87%), // Soft purple - values, information
  state: color.hsl(146deg, 52%, 88%), // Light green - status, condition
  ui: color.hsl(10deg, 80%, 90%), // Soft coral - interface, interaction
  pin: color.hsl(288deg, 42%, 90%), // Lavender - pinning, stability
  error: color.hsl(6deg, 78%, 91%), // Light rose - errors, warnings
)
