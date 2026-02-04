// Desirable Futures Workshop Design System
// Shared Tailwind preset for all workshop apps
// See /docs/design-system.md for full documentation

module.exports = {
  theme: {
    extend: {
      colors: {
        // ===================
        // Primary Brand Colors
        // ===================
        'df-blue': '#0095FF',
        'df-green': '#42D235',

        // ===================
        // Text Colors
        // ===================
        'text-dark': '#151515',      // H1 on light backgrounds
        'text-light': '#FAFAFA',     // H1 on dark backgrounds
        'text-body': '#A3A3A3',      // Body copy

        // ===================
        // Surface Colors (Light Theme)
        // ===================
        'surface': {
          'wall': '#FAFAFA',         // Virtual Wall background
          'sheet': '#FFFFFF',        // Sheet surface (current)
          'sheet-alt': '#FEFDFB',    // Sheet surface (cream/paper tint)
          'card': '#222222',         // Card background (dark contexts)
          'card-border': '#3F3F3F',  // Card borders (dark contexts)
        },

        // ===================
        // Accent Colors (Tertiary - Workshop Apps)
        // ===================
        'accent': {
          'purple': '#7245F4',       // Primary accent, interactive elements
          'magenta': '#BC45F4',      // Secondary accent, highlights
          'gold': '#F4B945',         // Attention, active states, high scores
          'red': '#F44545',          // Alerts, warnings, low scores
        },

        // ===================
        // Secondary Brand Colors
        // ===================
        'secondary': {
          'green-light': '#B0E2AB',
          'blue-light': '#71C1FB',
        },

        // ===================
        // Traffic Light (Score Indicators)
        // ===================
        'traffic': {
          'green': '#22c55e',        // Good (7-10)
          'amber': '#f59e0b',        // Neutral (4-6)
          'red': '#ef4444',          // Needs attention (0-3)
        },

        // ===================
        // Semantic Aliases
        // ===================
        'interactive': '#7245F4',    // Buttons, links, clickable elements
        'highlight': '#BC45F4',      // Hover states, emphasis
        'score-high': '#F4B945',     // High scores
        'score-low': '#F44545',      // Low scores
      },

      // ===================
      // Spacing Scale
      // ===================
      // Base: 4px increments (Tailwind default is close, we're adding semantic names)
      spacing: {
        'sheet-padding': '1.5rem',   // 24px - internal sheet padding
        'section-gap': '2rem',       // 32px - between major sections
        'strip-gap': '0.5rem',       // 8px - between sheet thumbnails
      },

      // ===================
      // Font Families
      // ===================
      // Placeholder names - replace with actual fonts when selected
      fontFamily: {
        'brand': ['Inter', 'system-ui', 'sans-serif'],           // Elegant branding font
        'workshop': ['Caveat', 'cursive'],                        // Handwritten/marker style
        'body': ['Inter', 'system-ui', 'sans-serif'],            // Clean body text
      },

      // ===================
      // Font Sizes (Type Scale)
      // ===================
      fontSize: {
        'score-lg': ['3rem', { lineHeight: '1', fontWeight: '700' }],      // 48px - Large scores
        'score-md': ['1.5rem', { lineHeight: '1', fontWeight: '600' }],    // 24px - Grid scores
        'score-sm': ['1.25rem', { lineHeight: '1', fontWeight: '600' }],   // 20px - Small scores
      },

      // ===================
      // Box Shadows
      // ===================
      boxShadow: {
        'sheet': '0 4px 6px -1px rgb(0 0 0 / 0.1), 0 2px 4px -2px rgb(0 0 0 / 0.1)',
        'sheet-receded': '0 10px 15px -3px rgb(0 0 0 / 0.15), 0 4px 6px -4px rgb(0 0 0 / 0.1)',
        'side-sheet': '-4px 0 6px -1px rgb(0 0 0 / 0.1)',
      },

      // ===================
      // Border Radius
      // ===================
      borderRadius: {
        'sheet': '0.5rem',           // Slightly rounded sheets
      },

      // ===================
      // Transitions
      // ===================
      transitionDuration: {
        'sheet': '300ms',            // Sheet transitions
      },

      // ===================
      // Z-Index Scale
      // ===================
      zIndex: {
        'wall': '0',
        'sheet-previous': '10',
        'sheet-current': '20',
        'sheet-strip': '30',
        'side-sheet': '40',
        'modal': '50',
      },
    },
  },
}
