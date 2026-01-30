#!/bin/bash

# Copy .cursor settings to .gemini with TOML conversion for commands

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
    
    # Write TOML file
    {
        echo "description = \"$description\""
        echo ""
        echo 'prompt = """'
        echo "$body"
        echo '"""'
    } > "$dst_file"
done

# Copy agents (same format)
echo "Copying agents..."
cp -r "$SOURCE_DIR/agents"/* "$DEST_DIR/agents/"

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
