# sketchybar-app-font management
# Fork of kvndrsslr/sketchybar-app-font with custom icons

# Paths
font_dest := home_directory() / "Library/Fonts/sketchybar-app-font.ttf"
icon_map_dest := home_directory() / ".config/sketchybar/helpers/app_icons.lua"
helpers_dir := home_directory() / ".config/sketchybar/helpers"

# Default: show available recipes
default:
    @just --list

# =============================================================================
# Build & Install
# =============================================================================

# Build font and icon map, install to system
build:
    #!/usr/bin/env zsh
    set -euo pipefail
    
    echo "🔨 Building sketchybar-app-font..."
    
    # Install dependencies if needed
    if [[ ! -d node_modules ]]; then
        echo "Installing dependencies..."
        pnpm install --silent
    fi
    
    # Build
    pnpm run build
    
    # Install font
    echo "📦 Installing font..."
    cp dist/sketchybar-app-font.ttf "{{font_dest}}"
    echo "  ✓ Font installed to {{font_dest}}"
    
    # Install Lua icon map
    echo "📦 Installing icon map..."
    mkdir -p "{{helpers_dir}}"
    cp dist/icon_map.lua "{{icon_map_dest}}"
    echo "  ✓ Icon map installed to {{icon_map_dest}}"
    
    echo "✅ Build complete!"

# Build and reload sketchybar
build-reload: build
    @echo "🔄 Reloading sketchybar..."
    @sketchybar --reload
    @echo "✅ Sketchybar reloaded"

# Install dependencies only
deps:
    pnpm install

# =============================================================================
# Fork Sync
# =============================================================================

# Sync fork with upstream (fetch + merge, abort on conflicts)
sync:
    #!/usr/bin/env zsh
    set -euo pipefail
    
    echo "🔄 Syncing with upstream..."
    
    # Check for uncommitted changes
    if [[ -n $(git status --porcelain 2>/dev/null) ]]; then
        echo "❌ Repository has uncommitted changes. Commit or stash them first."
        exit 1
    fi
    
    # Ensure upstream remote exists
    if ! git remote get-url upstream &>/dev/null; then
        echo "Adding upstream remote..."
        git remote add upstream https://github.com/kvndrsslr/sketchybar-app-font.git
    fi
    
    # Fetch upstream
    echo "Fetching upstream..."
    git fetch upstream
    
    # Get current branch
    current_branch=$(git branch --show-current)
    
    # Try to merge upstream/main
    echo "Merging upstream/main into $current_branch..."
    if git merge upstream/main --no-edit; then
        echo "✅ Successfully merged upstream changes"
        
        # Check if there are new commits to push
        if git log origin/$current_branch..$current_branch --oneline | grep -q .; then
            echo ""
            echo "📤 New commits to push. Run: just push"
        fi
    else
        echo "❌ Merge conflict detected!"
        echo ""
        echo "Options:"
        echo "  1. Resolve conflicts manually, then: git add . && git commit"
        echo "  2. Abort the merge: git merge --abort"
        git merge --abort
        exit 1
    fi

# Push changes to origin
push:
    #!/usr/bin/env zsh
    set -euo pipefail
    echo "📤 Pushing to origin..."
    git push origin $(git branch --show-current)
    echo "✅ Pushed successfully"

# Show fork status (ahead/behind upstream)
status:
    #!/usr/bin/env zsh
    set -euo pipefail
    
    # Fetch to get latest info
    git fetch upstream --quiet 2>/dev/null || true
    git fetch origin --quiet 2>/dev/null || true
    
    current=$(git branch --show-current)
    echo "📊 Fork status"
    echo "   Branch: $current"
    echo ""
    
    # Compare with upstream
    ahead=$(git rev-list --count upstream/main..$current 2>/dev/null || echo "?")
    behind=$(git rev-list --count $current..upstream/main 2>/dev/null || echo "?")
    echo "   vs upstream/main: $ahead ahead, $behind behind"
    
    # Compare with origin
    ahead_origin=$(git rev-list --count origin/$current..$current 2>/dev/null || echo "?")
    behind_origin=$(git rev-list --count $current..origin/$current 2>/dev/null || echo "?")
    echo "   vs origin/$current: $ahead_origin ahead, $behind_origin behind"
    
    # Show uncommitted changes
    if [[ -n $(git status --porcelain 2>/dev/null) ]]; then
        echo ""
        echo "   ⚠️  Uncommitted changes present"
    fi

# Full update: sync fork, build, and reload
update: sync build-reload

# =============================================================================
# Development
# =============================================================================

# Watch for changes and auto-rebuild (dev mode)
dev:
    #!/usr/bin/env zsh
    echo "👀 Watching for changes (Ctrl+C to stop)..."
    pnpm run build:dev "{{icon_map_dest}}"

# Validate mappings
validate:
    pnpm run validate

# =============================================================================
# Links
# =============================================================================

# Open fork on GitHub
github:
    @open "https://github.com/moritzketzer/sketchybar-app-font"

# Open upstream repo on GitHub
upstream:
    @open "https://github.com/kvndrsslr/sketchybar-app-font"

# Show mapping stats
stats:
    #!/usr/bin/env zsh
    echo "📊 Icon Mapping Stats"
    echo ""
    mapping_count=$(ls -1 mappings/ 2>/dev/null | wc -l | tr -d ' ')
    svg_count=$(ls -1 svgs/ 2>/dev/null | wc -l | tr -d ' ')
    echo "   Mappings: $mapping_count"
    echo "   SVGs: $svg_count"
