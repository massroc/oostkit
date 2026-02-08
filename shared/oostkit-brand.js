// OOSTKit Brand Colors
// Derived from Desirable Futures Group brand, remapped for OOSTKit product identity.
//
// Mapping from DF → OOSTKit:
//   DF Tertiary/Accent  →  OOSTKit Primary   (purple, magenta, gold, red)
//   DF Secondary         →  OOSTKit Secondary  (green-light, blue-light)
//   DF Primary           →  OOSTKit Tertiary   (blue, green)
//
// Each color includes a full Tailwind-compatible 50-950 scale generated
// from the brand base value. These plug directly into Petal Components
// and Tailwind utility classes (e.g. bg-ok-purple-500, text-ok-gold-300).

module.exports = {
  // ===================
  // OOSTKit Primary — Interactive, accent, high-emphasis
  // (from DF Tertiary/Accent)
  // ===================

  // Purple (base: #7245F4) — Primary interactive color
  'ok-purple': {
    50:  '#f5f3fb',
    100: '#ebe7f9',
    200: '#d7cdf3',
    300: '#b39fef',
    400: '#8d6cef',
    500: '#7245F4',  // brand base
    600: '#4a13f1',
    700: '#37159d',
    800: '#2e1773',
    900: '#241551',
    950: '#17102e',
  },

  // Magenta (base: #BC45F4) — Secondary accent, highlights
  'ok-magenta': {
    50:  '#f9f3fb',
    100: '#f3e7f9',
    200: '#e7cdf3',
    300: '#d69fef',
    400: '#c56cef',
    500: '#BC45F4',  // brand base
    600: '#ab13f1',
    700: '#72159d',
    800: '#561773',
    900: '#3e1551',
    950: '#24102e',
  },

  // Gold (base: #F4B945) — Attention, active states
  'ok-gold': {
    50:  '#fbf9f3',
    100: '#f9f3e7',
    200: '#f3e7cd',
    300: '#efd49f',
    400: '#efc36c',
    500: '#F4B945',  // brand base
    600: '#f1a713',
    700: '#9d7015',
    800: '#735417',
    900: '#513d15',
    950: '#2e2410',
  },

  // Red (base: #F44545) — Alerts, warnings
  'ok-red': {
    50:  '#fbf3f3',
    100: '#f9e7e7',
    200: '#f3cdcd',
    300: '#ef9f9f',
    400: '#ef6c6c',
    500: '#F44545',  // brand base
    600: '#f11313',
    700: '#9d1515',
    800: '#731717',
    900: '#511515',
    950: '#2e1010',
  },

  // ===================
  // OOSTKit Secondary — Supporting, softer tones
  // (from DF Secondary)
  // ===================
  'ok-secondary': {
    'green-light': '#B0E2AB',
    'blue-light': '#71C1FB',
  },

  // ===================
  // OOSTKit Tertiary — Background brand presence
  // (from DF Primary)
  // ===================

  // Blue (base: #0095FF)
  'ok-blue': {
    50:  '#f3f8fc',
    100: '#e6f1fa',
    200: '#cbe4f6',
    300: '#9acef4',
    400: '#64baf7',
    500: '#0095FF',  // brand base
    600: '#0077cc',
    700: '#0d66a5',
    800: '#114d78',
    900: '#123954',
    950: '#0e212f',
  },

  // Green (base: #42D235)
  'ok-green': {
    50:  '#f5faf4',
    100: '#eaf6e9',
    200: '#d5eed3',
    300: '#afe4aa',
    400: '#86dd7e',
    500: '#42D235',  // brand base
    600: '#32b027',
    700: '#318929',
    800: '#296624',
    900: '#21481e',
    950: '#162914',
  },

  // ===================
  // OOSTKit Gradients
  // ===================
  gradients: {
    // Primary gradient — buttons, CTAs, emphasis
    // 135deg purple → magenta
    primary: 'linear-gradient(135deg, #7245F4, #BC45F4)',

    // Header stripe — subtle directional accent
    // 90deg magenta → purple → transparent
    stripe: 'linear-gradient(90deg, #BC45F4, #7245F4 60%, transparent)',
  },
};
