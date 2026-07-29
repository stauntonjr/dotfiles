#!/bin/bash
# Exit immediately if a command exits with a non-zero status
set -e

echo "=================================================="
echo "Initializing Full DGX Spark Model Stack"
echo "=================================================="

# 1. Nemotron 120B (Architect / Large Reasoning) on port 8000
echo "[1/4] Starting Nemotron-3-Super on port 8000..."
sparkrun run @eugr/nemotron-3-super-nvfp4 \
    --tensor-parallel 1 \
    --port 8000 &
PID_NEMOTRON=$!

# 2. Qwen3-VL-Embedding 8B on port 8001
echo "[2/4] Starting Qwen3-VL-Embedding on port 8001..."
sparkrun run @official/qwen3-vl-embedding-8b-vllm \
    --tensor-parallel 1 \
    --port 8001 &
PID_EMBED=$!

# 3. Qwen3-Coder-Next on port 8002 (Tab-Autocomplete)
echo "[3/4] Starting Qwen3-Coder-Next on port 8002..."
sparkrun run @official/qwen3-coder-next-int4-autoround-vllm \
    --tensor-parallel 1 \
    --port 8002 &
PID_CODER=$!

# 4. Qwen3.6-35B MoE on port 8003
echo "[4/4] Starting Qwen3.6-35B MoE on port 8003..."
sparkrun run @eugr/qwen3.6-35b-a3b-nvfp4 \
    --tensor-parallel 1 \
    --port 8003 &
PID_QWEN35=$!

echo "=================================================="
echo "All model processes launched in background:"
echo "  - Nemotron 120B         (Port 8000): PID $PID_NEMOTRON"
echo "  - Qwen3-VL-Embedding    (Port 8001): PID $PID_EMBED"
echo "  - Qwen3-Coder-Next      (Port 8002): PID $PID_CODER"
echo "  - Qwen3.6-35B MoE       (Port 8003): PID $PID_QWEN35"
echo "=================================================="

# Wait for background jobs to keep script active and manage signals
wait