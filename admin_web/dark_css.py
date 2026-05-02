import re

with open('css/style.css', 'r', encoding='utf-8') as f:
    css = f.read()

# Replace the variables block entirely
vars_block_old = r':root \{.*?\n\}'
vars_block_new = """:root {
  /* Brand */
  --brand-1: #2563eb;   /* Strong Primary Blue */
  --brand-2: #1d4ed8;   /* Darker Blue */
  --brand-3: #3b82f6;   /* Light Blue Accent */
  --primary: var(--brand-1);

  /* Surface */
  --bg:       #09090b;  /* Pure Black / Darkest Slate */
  --surface:  #18181b;  /* Very dark gray cards */
  --surface-2:#27272a;  /* Hover / Input */
  --surface-3:#3f3f46;  /* Active / Light Border */
  --border:   #27272a;  /* Subtle divider */
  --border-2: #3f3f46;  /* Stronger divider */

  /* Text */
  --text-1: #f8fafc;    /* Crisp White */
  --text-2: #a1a1aa;    /* Muted Gray */
  --text-3: #71717a;    /* Placeholder */

  /* Semantic */
  --success: #10b981;
  --warning: #f59e0b;
  --danger:  #ef4444;
  --info:    #0ea5e9;

  /* Radius */
  --r-sm:  4px;
  --r-md:  6px;
  --r-lg:  8px;
  --r-xl:  12px;
  --r-2xl: 16px;
  --r-full:9999px;

  /* Shadows - Minimalist */
  --shadow-sm: 0 1px 2px 0 rgba(0, 0, 0, 0.5);
  --shadow-md: 0 4px 6px -1px rgba(0, 0, 0, 0.5), 0 2px 4px -1px rgba(0, 0, 0, 0.3);
  --shadow-lg: 0 10px 15px -3px rgba(0, 0, 0, 0.5), 0 4px 6px -2px rgba(0, 0, 0, 0.3);
  --shadow-brand: 0 4px 14px 0 rgba(37, 99, 235, 0.39);
  --shadow-card: 0 1px 3px 0 rgba(0, 0, 0, 0.5);

  /* Glow - Removed for professional look */
  --glow-brand: none;
  --glow-success: none;
  --glow-danger: none;

  /* Sidebar */
  --sidebar-w: 260px;

  /* Transitions */
  --t: 150ms ease;
  --t-slow: 300ms ease;
}"""

css = re.sub(vars_block_old, vars_block_new, css, flags=re.DOTALL)

# Also fix the topbar background to match the dark theme
css = re.sub(r'background: rgba\(255,255,255,\.9\);', 'background: rgba(9, 9, 11, 0.85);', css)

with open('css/style.css', 'w', encoding='utf-8') as f:
    f.write(css)

print("CSS converted to Black & Blue Theme successfully!")
