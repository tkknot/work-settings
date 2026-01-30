#!/bin/bash

# Copy .cursor settings to .gemini with format conversion

SOURCE_DIR="./.cursor"
DEST_DIR="./.gemini"

echo "=== Copying Cursor settings to Gemini format ==="

# Create directories
mkdir -p "$DEST_DIR/commands"
mkdir -p "$DEST_DIR/agents"
mkdir -p "$DEST_DIR/skills"

# Convert commands from MD to TOML
echo "Converting commands (MD -> TOML)..."
for md_file in "$SOURCE_DIR/commands"/*.md; do
    [ -f "$md_file" ] || continue
    filename=$(basename "$md_file" .md)
    # Remove -command suffix if present
    toml_name="${filename%-command}.toml"
    dst_file="$DEST_DIR/commands/$toml_name"
    
    echo "  $(basename "$md_file") -> $toml_name"
    
    # Extract description from frontmatter
    description=$(sed -n '/^---$/,/^---$/p' "$md_file" | grep '^description:' | sed 's/^description: *//')
    
    # Extract body (everything after the second ---)
    body=$(awk '/^---$/{count++; if(count==2){found=1; next}} found{print}' "$md_file")
    
    # Escape triple single quotes in body for TOML literal string
    escaped_body=$(echo "$body" | sed "s/'''/'''\"'''\"'''/g")
    
    # Write TOML file using literal string (''') to avoid escape issues
    {
        echo "description = \"$description\""
        echo ""
        echo "prompt = '''"
        echo "$escaped_body"
        echo "'''"
    } > "$dst_file"
done

# Copy and convert agents
echo "Converting agents..."
for md_file in "$SOURCE_DIR/agents"/*.md; do
    [ -f "$md_file" ] || continue
    filename=$(basename "$md_file" .md)
    dst_file="$DEST_DIR/agents/$filename.md"
    
    echo "  $filename.md"
    
    # Read the file and modify frontmatter
    awk '
    BEGIN { in_frontmatter = 0; frontmatter_count = 0; name_added = 0 }
    /^---$/ {
        frontmatter_count++
        if (frontmatter_count == 1) {
            in_frontmatter = 1
            print
            next
        } else if (frontmatter_count == 2) {
            in_frontmatter = 0
            print
            next
        }
    }
    in_frontmatter {
        # Skip mode line
        if ($0 ~ /^mode:/) next
        # Add name after description
        if ($0 ~ /^description:/ && !name_added) {
            print "name: '"$filename"'"
            name_added = 1
        }
        print
        next
    }
    { print }
    ' "$md_file" > "$dst_file"
done

# Copy skills (same format)
echo "Copying skills..."
cp -r "$SOURCE_DIR/skills"/* "$DEST_DIR/skills/"

# Copy AGENTS.md
echo "Copying AGENTS.md..."
cp AGENTS.md "$DEST_DIR/AGENTS.md"

# Create settings.json
echo "Creating settings.json..."
cat > "$DEST_DIR/settings.json" << 'EOF'
{
  "context": {
    "fileName": ["AGENTS.md", "GEMINI.md"]
  },
  "experimental": { "enableAgents": true }
}
EOF

echo ""
echo "Done! Files copied to $DEST_DIR"
