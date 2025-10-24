#import "@preview/touying:0.6.1": (
  config-colors, config-common, config-info, config-methods, config-page, config-store, meanwhile, only, pause,
  touying-slides, uncover, utils,
)
#import "@preview/codly:1.3.0": codly, codly-init, codly-reset

// Import all theme components
#import "theme/colors.typ": primary-color, secondary-color, tertiary-color, text-color
#import "theme/slides.typ": new-section-slide, slide

/// Touying university theme.
///
/// Example:
///
/// ```typst
/// #show: university-theme.with(aspect-ratio: "16-9", config-colors(primary: blue))`
/// ```
///
/// - `aspect-ratio` is the aspect ratio of the slides. Default is `16-9`.
///
/// - `progress-bar` is whether to show the progress bar. Default is `true`.
///
/// - `header` is the header of the slides. Default is `utils.display-current-heading(level: 2)`.
///
/// - `header-right` is the right part of the header. Default is `self.info.logo`.
///
/// - `footer-columns` is the columns of the footer. Default is `(25%, 1fr, 25%)`.
///
/// - `footer-a` is the left part of the footer. Default is `self.info.author`.
///
/// - `footer-b` is the middle part of the footer. Default is `self.info.short-title` or `self.info.title`.
///
/// - `footer-c` is the right part of the footer. Default is `self => h(1fr) + utils.display-info-date(self) + h(1fr) + context utils.slide-counter.display() + " / " + utils.last-slide-number + h(1fr)`.
///
/// ----------------------------------------
///
/// The default colors:
///
/// ```typ
/// config-colors(
///   primary: rgb("#04364A"),
///   secondary: rgb("#176B87"),
///   tertiary: rgb("#448C95"),
///   neutral-lightest: rgb("#ffffff"),
///   neutral-darkest: rgb("#000000"),
/// )
/// ```
#let conference-theme(
  aspect-ratio: "16-9",
  progress-bar: true,
  header: utils.display-current-heading(level: 2),
  header-right: self => utils.display-current-heading(level: 1) + h(.3em) + self.info.logo,
  footer-columns: (25%, 1fr, 25%),
  footer-a: self => self.info.author,
  footer-b: self => if self.info.short-title == auto {
    self.info.title
  } else {
    self.info.short-title
  },
  footer-c: self => {
    h(1fr)
    utils.display-info-date(self)
    h(1fr)
    context utils.slide-counter.display() + " / " + utils.last-slide-number
    h(1fr)
  },
  ..args,
  body,
) = {
  show: codly-init.with()

  // Default codly setup for presentations
  codly(
    languages: (
      rs: (name: "Rust", icon: "🦀", color: rgb("#CE412B")),
      rust: (name: "Rust", icon: "🦀", color: rgb("#CE412B")),
      python: (name: "Python", icon: "🐍", color: rgb("#3572A5")),
      typst: (name: "Typst", icon: "📘", color: primary-color),
      javascript: (name: "JavaScript", icon: "JS", color: rgb("#F7DF1E")),
      bash: (name: "Bash", icon: "$", color: rgb("#4EAA25")),
    ),
    zebra-fill: rgb("#f5f5f5"),
    radius: 0.5em,
  )

  // Default heading numbering for presentations
  set heading(numbering: "1.")

  show: touying-slides.with(
    config-page(
      paper: "presentation-" + aspect-ratio,
      header-ascent: 0em,
      footer-descent: 0em,
      margin: (top: 2em, bottom: 1.25em, x: 2em),
    ),
    config-common(
      slide-fn: slide,
      new-section-slide-fn: new-section-slide,
    ),
    config-methods(
      init: (self: none, body) => {
        set text(fill: self.colors.neutral-darkest, size: 22pt)
        show heading: set text(fill: self.colors.primary)
        body
      },
      alert: utils.alert-with-primary-color,
    ),
    config-colors(
      primary: primary-color,
      secondary: secondary-color,
      tertiary: tertiary-color,
      neutral-lightest: rgb("#ffffff"),
      neutral-darkest: text-color,
    ),
    // save the variables for later use
    config-store(
      progress-bar: progress-bar,
      header: header,
      header-right: header-right,
      footer-columns: footer-columns,
      footer-a: footer-a,
      footer-b: footer-b,
      footer-c: footer-c,
    ),
    ..args,
  )

  body
}

// Re-export commonly used functions for convenience
#import "theme/slides.typ": focus-slide, matrix-slide, new-section-slide, slide, title-slide
#import "theme/components.typ": error, info, large-center-text, legend, todo, warning
#import "theme/diagram-helpers.typ": *
#import "theme/colors.typ": accent, arrow-width, colors, node-outset, node-radius, stroke-width
