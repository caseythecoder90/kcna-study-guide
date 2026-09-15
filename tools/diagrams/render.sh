#!/usr/bin/env bash
# Render every notes/**/diagrams/*.puml to an SVG next to it.
#   tools/diagrams/render.sh                 # all diagrams
#   tools/diagrams/render.sh path/to/x.puml  # just one
# Requires Java and plantuml.jar (path below or $PLANTUML_JAR). No Graphviz
# needed: the theme pins the built-in Smetana layout engine.
set -euo pipefail
JAR="${PLANTUML_JAR:-$HOME/.cache/plantuml/plantuml.jar}"
[ -f "$JAR" ] || { echo "plantuml.jar not found at $JAR (set PLANTUML_JAR)"; exit 1; }
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
if [ $# -gt 0 ]; then FILES=("$@"); else mapfile -t FILES < <(find "$ROOT/notes" -path '*/diagrams/*.puml' | sort); fi
for f in "${FILES[@]}"; do
  java -jar "$JAR" -tsvg -charset UTF-8 "$f"
  svg="${f%.puml}.svg"
  # Give browsers a fallback font stack so text metrics stay close to Arial.
  sed -i 's/font-family="Arial"/font-family="Arial, Helvetica, sans-serif"/g' "$svg"
  echo "rendered $(realpath --relative-to="$ROOT" "$svg")"
done
