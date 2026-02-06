// Desirable Futures Workshop Design System
// Shared Tailwind preset for all workshop apps
// See /docs/design-system.md for full documentation
//
// Reference mockup: /apps/workgroup_pulse/docs/mockups/facilitator-scoring-v8.html

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
        // UI Chrome Colors
        // ===================
        'ui': {
          'text': '#333333',         // Primary UI text
          'text-muted': '#888888',   // Secondary UI text
          'border': '#E0E0E0',       // Light borders
          'header-bg': '#FAFAFA',    // Header and strip background
        },

        // ===================
        // Surface Colors (Light Theme)
        // ===================
        'surface': {
          'wall': '#E8E4DF',         // Virtual Wall background (warm taupe)
          'sheet': '#FEFDFB',        // Primary sheet surface (cream/paper)
          'sheet-secondary': '#F5F3F0', // Secondary/receded sheets
          'card': '#222222',         // Card background (dark contexts)
          'card-border': '#3F3F3F',  // Card borders (dark contexts)
        },

        // ===================
        // Ink Colors (On-sheet content)
        // ===================
        'ink': {
          'blue': '#1a3a6b',                    // Primary handwritten text
          'blue-light': 'rgba(26, 58, 107, 0.06)', // Subtle backgrounds
        },

        // ===================
        // Accent Colors (Tertiary - Workshop Apps)
        // ===================
        'accent': {
          'purple': '#7245F4',       // Primary accent, interactive elements
          'purple-light': 'rgba(114, 69, 244, 0.08)', // Subtle purple background
          'purple-border': 'rgba(114, 69, 244, 0.25)', // Purple borders
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
      spacing: {
        'sheet-padding': '1.5rem',   // 24px - internal sheet padding
        'sheet-padding-sm': '1.25rem', // 20px - compact sheet padding
        'section-gap': '2rem',       // 32px - between major sections
        'strip-gap': '0.375rem',     // 6px - between sheet thumbnails
      },

      // ===================
      // Font Families
      // ===================
      fontFamily: {
        'brand': ['"DM Sans"', 'system-ui', 'sans-serif'],  // UI chrome, branding
        'workshop': ['Caveat', 'cursive'],                   // Handwritten/marker style
        'body': ['"DM Sans"', 'system-ui', 'sans-serif'],   // Clean body text
      },

      // ===================
      // Font Sizes (Type Scale)
      // ===================
      fontSize: {
        // Scores
        'score-lg': ['3rem', { lineHeight: '1', fontWeight: '700' }],      // 48px - Large scores
        'score-md': ['1.5rem', { lineHeight: '1', fontWeight: '700' }],    // 24px - Grid scores
        'score-sm': ['1.25rem', { lineHeight: '1', fontWeight: '700' }],   // 20px - Small/empty scores
        // On-sheet content
        'participant': ['1.125rem', { lineHeight: '1.2', fontWeight: '600' }], // 18px - Participant names
        'criterion': ['1.0625rem', { lineHeight: '1.2', fontWeight: '600' }],  // 17px - Criterion names
        'criterion-parent': ['0.6875rem', { lineHeight: '1.2', fontWeight: '500' }], // 11px - Parent labels
        'sheet-title': ['1.25rem', { lineHeight: '1.3', fontWeight: '700' }],  // 20px - Notes title
        'sheet-content': ['1rem', { lineHeight: '1.55', fontWeight: '400' }],  // 16px - Notes content
        // UI chrome
        'scale-label': ['0.5625rem', { lineHeight: '1.4', fontWeight: '400' }], // 9px - Scale labels
      },

      // ===================
      // Box Shadows
      // ===================
      boxShadow: {
        'sheet':
          '0 1px 1px rgba(0,0,0,0.03), ' +
          '0 2px 4px rgba(0,0,0,0.04), ' +
          '0 4px 8px rgba(0,0,0,0.05), ' +
          '0 8px 16px rgba(0,0,0,0.05)',
        'sheet-lifted':
          '0 2px 2px rgba(0,0,0,0.03), ' +
          '0 4px 8px rgba(0,0,0,0.05), ' +
          '0 8px 16px rgba(0,0,0,0.06), ' +
          '0 16px 32px rgba(0,0,0,0.07)',
        'sheet-receded':
          '0 10px 15px -3px rgba(0,0,0,0.15), ' +
          '0 4px 6px -4px rgba(0,0,0,0.1)',
        'side-sheet': '-4px 0 6px -1px rgba(0,0,0,0.1)',
      },

      // ===================
      // Border Radius
      // ===================
      borderRadius: {
        'sheet': '2px',              // Minimal rounding (paper-like)
        'button': '8px',             // Buttons
        'icon': '7px',               // App icon
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
        'sheet-secondary': '1',      // Behind main sheet
        'sheet-current': '2',        // Main sheet (in front)
        'sheet-strip': '10',
        'floating': '20',            // Floating buttons
        'modal': '50',
      },

      // ===================
      // Custom Properties (Sheet Dimensions)
      // ===================
      // Reference: Post-it Easel Pad 635mm × 775mm = 0.819 ratio (W:H)
      aspectRatio: {
        'sheet': '0.819',            // Width ÷ Height
      },

      // Chrome heights
      height: {
        'header': '52px',
        'strip': '44px',
        'strip-thumb': '34px',
      },
      width: {
        'strip-thumb': '28px',       // 34px × 0.819
      },
    },
  },
}
