#!/usr/bin/env bash
###############################################################################
#  local_models_setup.sh — stand up small, happy models on a limited box via
#  Ollama. Curated for CPU / small-VRAM machines; good for the AI-bias/sycophancy
#  research harness, local drafting, and keeping the laptop busy.
#
#  Usage: local_models_setup.sh            install ollama + pull the small set
#         local_models_setup.sh --tiny      only the sub-1B models (very low RAM)
#  © 1993-2026 Abhishek Choudhary. GPL-3.0-or-later.
###############################################################################
set -euo pipefail
TINY=0; [ "${1:-}" = "--tiny" ] && TINY=1
say(){ printf '\n\033[1;33m=== %s ===\033[0m\n' "$*"; }
loud(){ printf '\033[1;36m  %s\033[0m\n' "$*"; }
command -v ollama >/dev/null 2>&1 || { say "INSTALL OLLAMA"; curl -fsSL https://ollama.com/install.sh | sh; }
say "PULL SMALL MODELS"
TINY_SET="qwen2.5:0.5b gemma2:2b llama3.2:1b"
SMALL_SET="qwen2.5:3b phi3:mini llama3.2:3b"
for m in $TINY_SET; do loud "pull $m"; ollama pull "$m" || true; done
[ "$TINY" -eq 0 ] && for m in $SMALL_SET; do loud "pull $m"; ollama pull "$m" || true; done
say "DONE"
loud "test: ollama run qwen2.5:0.5b 'one-line summary of Project ILM'"
loud "bias harness: point CIIO/DPE/CLACE runners at http://localhost:11434"
