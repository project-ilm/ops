#!/usr/bin/env bash
set -euo pipefail

REPO_NAME="misty-doi"
ORG="project-ilm"

echo "[INFO] Creating repository structure..."

mkdir -p "$REPO_NAME"/{
cli,
web/css,
web/js,
web/prompts,
templates,
scripts,
docs,
.github/workflows,
examples
}

cd "$REPO_NAME"

###############################################################################
# README
###############################################################################

cat > README.md << 'README'
# Misty DOI
## Muh Mitha Kijiye! ™

Misty DOI is a browser-first and CLI-first DOI publication toolkit.

Features:

- DOI minting via Zenodo
- OpenTimestamps integration
- SHA256 generation
- Metadata generation
- CITATION.cff generation
- codemeta.json generation
- Poster publication workflow
- GitHub Pages Web UI
- No backend required

## Security Model

Misty DOI is designed as a client-side system.

Your Zenodo token remains under your control.

Project ILM does not operate a backend.

## Components

- misty-doi CLI
- GitHub Pages Web UI
- Zenodo integration
- OTS timestamping

## License

GPL-3.0

## Copyright

Copyright (C) 1993-2026

Abhishek Choudhary

Project ILM

All Rights Reserved
README

###############################################################################
# LICENSE PLACEHOLDER
###############################################################################

cat > LICENSE << 'LICENSE'
GPL-3.0

Replace with full GPL text.
LICENSE

###############################################################################
# COPYRIGHT
###############################################################################

cat > COPYRIGHT << 'COPYRIGHT'
Copyright (C) 1993-2026

Abhishek Choudhary

Project ILM

All Rights Reserved
COPYRIGHT

###############################################################################
# CONTRIBUTING
###############################################################################

cat > CONTRIBUTING.md << 'CONTRIB'
# Contributing

Pull requests welcome.

Please include:

- Documentation
- Tests
- Example metadata

CONTRIB

###############################################################################
# PYPROJECT
###############################################################################

cat > pyproject.toml << 'PYPROJECT'
[project]
name = "misty-doi"
version = "0.1.0"
description = "Misty DOI - Muh Mitha Kijiye!"
authors = [
  { name="Abhishek Choudhary" }
]

requires-python = ">=3.10"

[project.scripts]
misty = "cli.misty:main"
PYPROJECT

###############################################################################
# CLI
###############################################################################

cat > cli/misty.py << 'PY'
#!/usr/bin/env python3

import argparse

def main():
    parser = argparse.ArgumentParser(
        prog="misty",
        description="Misty DOI"
    )

    sub = parser.add_subparsers(dest="cmd")

    sub.add_parser("init")
    sub.add_parser("metadata")
    sub.add_parser("validate")
    sub.add_parser("publish")
    sub.add_parser("ots")
    sub.add_parser("release")

    args = parser.parse_args()

    print(f"[MISTY] command={args.cmd}")

if __name__ == "__main__":
    main()
PY

chmod +x cli/misty.py

###############################################################################
# WEB UI
###############################################################################

cat > web/index.html << 'HTML'
<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<title>Misty DOI</title>
<link rel="stylesheet" href="css/style.css">
</head>
<body>

<h1>Misty DOI</h1>
<h2>Muh Mitha Kijiye! ™</h2>

<div class="notice">
<h3>Security Notice</h3>

<p>
This application is client-side only.
</p>

<p>
Project ILM does not receive or store
your Zenodo token.
</p>

<p>
Your token is used from your browser.
</p>
</div>

<h3>Metadata</h3>

<input id="title" placeholder="Title">

<br><br>

<textarea id="abstract"
rows="10"
cols="80"
placeholder="Abstract"></textarea>

<br><br>

<input
id="token"
type="password"
placeholder="Zenodo Token">

<br><br>

<button onclick="saveToken()">
Save Token (Session Only)
</button>

<button onclick="generateMetadata()">
Generate Metadata
</button>

<pre id="output"></pre>

<script src="js/app.js"></script>

</body>
</html>
HTML

cat > web/css/style.css << 'CSS'
body {
    font-family: sans-serif;
    margin: 2em;
}

.notice {
    border: 1px solid #999;
    padding: 1em;
}
CSS

cat > web/js/app.js << 'JS'
function saveToken() {
    const token =
        document.getElementById("token").value;

    sessionStorage.setItem(
        "zenodo_token",
        token
    );

    alert("Stored for browser session only.");
}

function generateMetadata() {

    const title =
        document.getElementById("title").value;

    const abstract =
        document.getElementById("abstract").value;

    const obj = {
        title,
        abstract
    };

    document.getElementById("output")
        .textContent =
        JSON.stringify(obj, null, 2);
}
JS

###############################################################################
# PROMPTS
###############################################################################

cat > web/prompts/poster.txt << 'PROMPT'
Generate an A0 portrait academic poster.
PROMPT

cat > web/prompts/metadata.txt << 'PROMPT'
Generate metadata for DOI publication.
PROMPT

cat > web/prompts/doi.txt << 'PROMPT'
Generate DOI publication package.
PROMPT

###############################################################################
# TEMPLATE FILES
###############################################################################

cat > templates/poster_manifest.json << 'JSON'
{
  "schema_version": "1.0"
}
JSON

cat > templates/codemeta.json << 'JSON'
{
  "@context": "https://doi.org/10.5063/schema/codemeta-2.0"
}
JSON

cat > templates/zenodo_metadata.json << 'JSON'
{
  "metadata": {}
}
JSON

cat > templates/CITATION.cff << 'CFF'
cff-version: 1.2.0
title: Misty DOI
CFF

###############################################################################
# PUBLISH SCRIPT
###############################################################################

cat > scripts/publish.sh << 'SCRIPT'
#!/usr/bin/env bash
set -euo pipefail

ZIP="${1:-release.zip}"

SHA=$(sha256sum "$ZIP" | awk '{print $1}')

echo "[STATUS] sha256: $SHA"

echo "$SHA" > SHA256SUMS
SCRIPT

chmod +x scripts/publish.sh

###############################################################################
# OTS SCRIPT
###############################################################################

cat > scripts/ots.sh << 'SCRIPT'
#!/usr/bin/env bash
set -euo pipefail

FILE="$1"

ots stamp "$FILE"

echo "[STATUS] timestamped"
SCRIPT

chmod +x scripts/ots.sh

###############################################################################
# GITHUB ACTION
###############################################################################

cat > .github/workflows/pages.yml << 'YAML'
name: pages

on:
  push:
    branches:
      - main

jobs:
  deploy:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4

      - uses: actions/configure-pages@v5

      - uses: actions/upload-pages-artifact@v3
        with:
          path: web

      - uses: actions/deploy-pages@v4
YAML

###############################################################################
# GIT INIT
###############################################################################

git init
git add .
git commit -m "Initial Misty DOI scaffold"

###############################################################################
# GH CREATE
###############################################################################

if command -v gh >/dev/null 2>&1; then

    gh repo create \
      "${ORG}/${REPO_NAME}" \
      --public \
      --source=. \
      --remote=origin \
      --push

    echo
    echo "[INFO] Enable GitHub Pages:"
    echo "Settings -> Pages -> GitHub Actions"
else
    echo
    echo "[WARN] gh CLI not found"
fi

echo
echo "[DONE]"
echo "Repo scaffold created."
