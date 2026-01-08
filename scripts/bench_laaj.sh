#!/bin/bash

cd "$(dirname "${BASH_SOURCE[0]}")"
cd ..
pwd

MODEL=$1
export OPEN_AI_TEMPERATURE=$2
export REASONING_EFFORT=$3
OUTPUT=$4
export DEBUG=$5

if [ -z "$MODEL" ]; then
  echo "No model specified. Usage: ./scripts/bench_laaj.sh <model> [temperature] [reasoning_effort] [output_folder]"
  exit 1
fi

if [ -z "$OPEN_AI_TEMPERATURE" ]; then
  export OPEN_AI_TEMPERATURE=0
fi

if [ -z "$OUTPUT" ]; then
  OUTPUT=r1/$MODEL$REASONING_EFFORT
fi

OUTPUT_DIR="./results/$OUTPUT"

# Delete any stale cache files (we no longer use them, benchmark_result_*.json files are the source of truth)
rm -f "$OUTPUT_DIR"/.analysis_cache_*.json 2>/dev/null

# Check if results already exist and are complete
LATEST_JSON=$(ls -t "$OUTPUT_DIR"/folder_coverage_summary_*.json 2>/dev/null | head -1)
if [ -f "$LATEST_JSON" ]; then
  ANALYZED=$(python3 -c "import json; data=json.load(open('$LATEST_JSON')); print(data.get('analyzed_files', 0))")
  FAILED=$(python3 -c "import json; data=json.load(open('$LATEST_JSON')); print(data.get('failed_files', -1))")
  TOTAL=$(python3 -c "import json; data=json.load(open('$LATEST_JSON')); print(data.get('total_files', 0))")

  if [ "$ANALYZED" = "$TOTAL" ] && [ "$FAILED" = "0" ]; then
    echo "✓ Skipping $MODEL - already complete (analyzed: $ANALYZED/$TOTAL, failed: $FAILED)"
    exit 0
  else
    echo "⚠ Re-running $MODEL - incomplete or has failures (analyzed: $ANALYZED/$TOTAL, failed: $FAILED)"
  fi
fi

echo "Benchmarking LLM-as-a-Judge with model: $MODEL OPEN_AI_TEMPERATURE: $OPEN_AI_TEMPERATURE REASONING_EFFORT: $REASONING_EFFORT"

python src/laj/analyze_gherkin_folder.py --folder ./dataset/benchmark_feautures \
    --model $MODEL --output "$OUTPUT_DIR"
