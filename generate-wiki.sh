#!/bin/bash
# Auto-generate Docsify sidebar and landing page for all wiki folders in /share/Web
# Usage: bash /share/Web/generate-wiki.sh
# Run this script whenever you add/remove .md files or create new wiki folders.

WEB_ROOT="${WEB_ROOT:-/share/Web}"
# If WEB_ROOT doesn't exist, use current directory
if [[ ! -d "$WEB_ROOT" ]]; then
  WEB_ROOT="$(dirname "$(realpath "$0")")"
fi

# --- Helper: Convert filename to readable title ---
to_title() {
  local name="$1"
  name="${name%.md}"                    # remove .md
  name=$(echo "$name" | sed 's/-/ /g') # dash to space
  # Capitalize first letter of each word
  echo "$name" | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) substr($i,2)}1'
}

# --- Generate _sidebar.md for a single project folder ---
generate_sidebar() {
  local project_dir="$1"
  local sidebar_file="$project_dir/_sidebar.md"
  local project_name=$(basename "$project_dir")

  echo "Generating sidebar for: $project_name"

  # Start sidebar
  echo "- [Home](/)" > "$sidebar_file"
  echo "" >> "$sidebar_file"

  # Find all subdirectories that contain .md files
  local has_root_files=false

  # First: list .md files in root (excluding README.md, _sidebar.md)
  for md in "$project_dir"/*.md; do
    [ -f "$md" ] || continue
    local fname=$(basename "$md")
    [[ "$fname" == "README.md" ]] && continue
    [[ "$fname" == "_sidebar.md" ]] && continue
    [[ "$fname" =~ ^_ ]] && continue
    has_root_files=true
    local title=$(to_title "$fname")
    echo "- [$title]($fname)" >> "$sidebar_file"
  done

  $has_root_files && echo "" >> "$sidebar_file"

  # Then: list subdirectories with their .md files
  for subdir in "$project_dir"/*/; do
    [ -d "$subdir" ] || continue
    local dirname=$(basename "$subdir")
    [[ "$dirname" == "@Recycle" ]] && continue
    [[ "$dirname" =~ ^\. ]] && continue
    [[ "$dirname" =~ ^\{ ]] && continue

    # Check if subdir has .md files
    local md_count=$(find "$subdir" -maxdepth 1 -name "*.md" ! -name "_*" | wc -l)
    [ "$md_count" -eq 0 ] && continue

    local section_title=$(to_title "$dirname")
    echo "- **$section_title**" >> "$sidebar_file"

    for md in "$subdir"*.md; do
      [ -f "$md" ] || continue
      local fname=$(basename "$md")
      [[ "$fname" =~ ^_ ]] && continue
      local title=$(to_title "$fname")
      echo "  - [$title]($dirname/$fname)" >> "$sidebar_file"
    done

    echo "" >> "$sidebar_file"
  done

  echo "  -> $sidebar_file"
}

# --- Ensure each project folder has index.html and .nojekyll ---
setup_docsify() {
  local project_dir="$1"
  local project_name=$(basename "$project_dir")

  # Create index.html if not exists
  if [ ! -f "$project_dir/index.html" ]; then
    cat > "$project_dir/index.html" << 'HTMLEOF'
<!DOCTYPE html>
<html lang="th">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Wiki</title>
  <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/docsify-themeable@0/dist/css/theme-simple.css">
  <style>
    :root { --theme-color: #3f51b5; --sidebar-width: 260px; }
    body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif; }
    .sidebar-nav li a { font-size: 14px; }
  </style>
</head>
<body>
  <div id="app">Loading...</div>
  <script>
    window.$docsify = {
      name: document.title,
      repo: false,
      loadSidebar: true,
      subMaxLevel: 3,
      search: { placeholder: 'Search...', noData: 'No results', depth: 3 },
      auto2top: true,
      relativePath: false
    }
  </script>
  <script src="https://cdn.jsdelivr.net/npm/docsify@4/lib/docsify.min.js"></script>
  <script src="https://cdn.jsdelivr.net/npm/docsify@4/lib/plugins/search.min.js"></script>
</body>
</html>
HTMLEOF
    echo "  -> Created index.html"
  fi

  # Create .nojekyll if not exists
  [ ! -f "$project_dir/.nojekyll" ] && touch "$project_dir/.nojekyll"
}

# --- Generate landing page at /share/Web/index.html ---
generate_landing() {
  local landing="$WEB_ROOT/index.html"
  echo "Generating landing page..."

  cat > "$landing" << 'HEADEOF'
<!DOCTYPE html>
<html lang="th">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Wiki Home</title>
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
      background: #f5f5f5; color: #333; padding: 40px 20px;
    }
    .container { max-width: 800px; margin: 0 auto; }
    h1 { font-size: 28px; margin-bottom: 8px; }
    .subtitle { color: #666; margin-bottom: 32px; }
    .grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(240px, 1fr)); gap: 16px; }
    .card {
      background: #fff; border-radius: 8px; padding: 24px;
      box-shadow: 0 1px 3px rgba(0,0,0,0.1);
      text-decoration: none; color: inherit;
      transition: box-shadow 0.2s, transform 0.2s;
    }
    .card:hover { box-shadow: 0 4px 12px rgba(0,0,0,0.15); transform: translateY(-2px); }
    .card h2 { font-size: 18px; margin-bottom: 8px; color: #3f51b5; }
    .card p { font-size: 14px; color: #666; }
  </style>
</head>
<body>
  <div class="container">
    <h1>Wiki</h1>
    <p class="subtitle">Documentation hub on NAS</p>
    <div class="grid">
HEADEOF

  # Find all project folders (contain at least one .md file)
  for dir in "$WEB_ROOT"/*/; do
    [ -d "$dir" ] || continue
    local dirname=$(basename "$dir")
    [[ "$dirname" == "@Recycle" ]] && continue
    [[ "$dirname" =~ ^\. ]] && continue
    [[ "$dirname" =~ ^\{ ]] && continue

    # Check if folder has any .md files (recursively)
    local md_count=$(find "$dir" -name "*.md" ! -name "_*" | head -1 | wc -l)
    [ "$md_count" -eq 0 ] && continue

    local title=$(to_title "$dirname")

    # Try to extract description from README.md first line
    local desc=""
    if [ -f "$dir/README.md" ]; then
      desc=$(head -5 "$dir/README.md" | grep -v "^#" | grep -v "^$" | head -1 | cut -c1-80)
    fi
    [ -z "$desc" ] && desc="Documentation"

    # Count .md files
    local file_count=$(find "$dir" -name "*.md" ! -name "_*" ! -name "README.md" | wc -l)

    cat >> "$landing" << CARDEOF
      <a class="card" href="/$dirname/">
        <h2>$title</h2>
        <p>$desc</p>
        <p style="margin-top:8px;font-size:12px;color:#999;">$file_count docs</p>
      </a>
CARDEOF
  done

  cat >> "$landing" << 'FOOTEOF'
    </div>
  </div>
</body>
</html>
FOOTEOF

  echo "  -> $landing"
}

# ============================================================
# MAIN
# ============================================================
echo "=== Wiki Generator ==="
echo ""

# Process each project folder
for dir in "$WEB_ROOT"/*/; do
  [ -d "$dir" ] || continue
  dirname=$(basename "$dir")
  [[ "$dirname" == "@Recycle" ]] && continue
  [[ "$dirname" =~ ^\. ]] && continue
  [[ "$dirname" =~ ^\{ ]] && continue

  # Only process folders that have .md files
  md_count=$(find "$dir" -name "*.md" ! -name "_*" | head -1 | wc -l)
  [ "$md_count" -eq 0 ] && continue

  setup_docsify "$dir"
  generate_sidebar "$dir"
done

echo ""
generate_landing
echo ""
echo "=== Done! ==="
