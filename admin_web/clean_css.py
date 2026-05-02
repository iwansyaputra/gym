import re

with open('css/style.css', 'r', encoding='utf-8') as f:
    css = f.read()

# Replace hardcoded dark-mode RGBAs with variables or light-mode equivalents
replacements = [
    (r'rgba\(255,255,255,\.07\)', 'var(--border)'),
    (r'rgba\(255,255,255,\.12\)', 'var(--border-2)'),
    (r'rgba\(255,255,255,\.15\)', 'var(--border-2)'),
    (r'rgba\(255,255,255,\.1\)', 'var(--border)'),
    (r'rgba\(255,255,255,\.2\)', 'var(--border-2)'),
    (r'rgba\(255,255,255,\.3\)', 'var(--border-2)'),
    
    # Topbar background
    (r'rgba\(14,20,32,\.8\)', 'rgba(255,255,255,.9)'),
    
    # Remove AI glows and heavy gradients
    (r'radial-gradient\(circle, rgba\(99,102,241,\.12\) 0%, transparent 70%\)', 'transparent'),
    (r'linear-gradient\(135deg, var\(--brand-1\), var\(--brand-2\)\)', 'var(--brand-1)'),
    (r'linear-gradient\(135deg, var\(--brand-1\), var\(--brand-3\)\)', 'var(--brand-1)'),
    (r'linear-gradient\(to bottom, var\(--brand-1\), var\(--brand-2\)\)', 'var(--brand-1)'),
    (r'linear-gradient\(135deg, rgba\(99,102,241,\.18\), rgba\(139,92,246,\.1\)\)', 'var(--surface-2)'),
    (r'linear-gradient\(135deg, rgba\(99,102,241,\.2\), rgba\(139,92,246,\.1\)\)', 'var(--surface-2)'),
    
    # Shadows
    (r'box-shadow: 0 4px 16px rgba\(99,102,241,\.3\);', 'box-shadow: var(--shadow-sm);'),
    (r'box-shadow: 0 6px 24px rgba\(99,102,241,\.45\);', 'box-shadow: var(--shadow-md);'),
    
    # Specific colors to generic
    (r'#f87171', 'var(--danger)'),
    (r'#818cf8', 'var(--brand-2)'),
    (r'#4ade80', 'var(--success)'),
    (r'#fbbf24', 'var(--warning)'),
    (r'#22d3ee', 'var(--info)'),
    
    # Text colors that were white in dark mode but should be dark in light mode
    (r'-webkit-text-fill-color: transparent;', ''),
    (r'background-clip: text;', ''),
    (r'-webkit-background-clip: text;', '')
]

for old, new in replacements:
    css = re.sub(old, new, css)

# Make sure tables and cards have proper backgrounds
css = re.sub(r'background: rgba\(0,0,0,\.7\);', 'background: rgba(0,0,0,.3);', css) # modals
css = re.sub(r'border: 2px solid rgba\(99,102,241,\.4\);', 'border: 2px solid var(--brand-2);', css)

with open('css/style.css', 'w', encoding='utf-8') as f:
    f.write(css)

print("CSS cleaned successfully!")
