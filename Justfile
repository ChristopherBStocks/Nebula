# Run linter
lint:
    deadnix
    statix check

# Format source files
format:
    statix fix
    nix fmt .
fmt: format

# Generate repository changelog and tag release
changelog version:
    git tag -a v{{ version }} -m "chore(release): v{{ version }}"
    git-cliff --output CHANGELOG.md
    git add -A
    git commit -s -m "chore(release): add changelog for v{{ version }}"
    git tag -f v{{ version }} -m "chore(release): v{{ version }}"
cl version:
    just changelog {{ version }}
