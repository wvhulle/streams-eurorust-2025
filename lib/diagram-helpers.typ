// ============================================================================
// Main diagram helpers file - re-exports all helper functions
// ============================================================================

// Re-export color helpers
#import "colors.typ": *

// Re-export node helpers (Fletcher diagrams)
#import "nodes.typ": *

// Re-export canvas helpers (CeTZ primitives)
#import "canvas.typ": *

// ============================================================================
// Legend Helper
// ============================================================================

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
