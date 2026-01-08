#!/bin/bash
# Run LLM-as-a-Judge benchmarks across all models for multiple runs
# Usage: ./scripts/bench_laaj-all.sh <end_run> [start_run]
# Example: ./scripts/bench_laaj-all.sh 5       # Will run from r1 to r5
# Example: ./scripts/bench_laaj-all.sh 3 2     # Will run from r2 to r3

cd "$(dirname "${BASH_SOURCE[0]}")"
cd ..
pwd

RUN_NUM=$1
START_NUM=$2

if [ -z "$RUN_NUM" ]; then
  echo "No run number specified. Usage: $0 <end_run> [start_run]"
  echo "Example: $0 5       # Will run from r1 to r5"
  echo "Example: $0 2 2     # Will run only r2"
  echo "Example: $0 5 2     # Will run from r2 to r5"
  exit 1
fi

if [ -z "$START_NUM" ]; then
  START_NUM=1
fi

echo "Running benchmarks from r$START_NUM to r$RUN_NUM"
echo "Results will be stored in results/r1/, results/r2/, etc."

for i in $(seq $START_NUM $RUN_NUM); do
  echo ""
  echo "========================================="
  echo "Starting run $i of $RUN_NUM (r$i)"
  echo "========================================="
  echo ""

  # GPT-4 models
  ./scripts/bench_laaj.sh gpt-4o-mini 0 "" r$i/gpt-4o-mini
  ./scripts/bench_laaj.sh gpt-4o 0 "" r$i/gpt-4o
  ./scripts/bench_laaj.sh gpt-4.1-nano 0 "" r$i/gpt-4.1-nano
  ./scripts/bench_laaj.sh gpt-4.1-mini 0 "" r$i/gpt-4.1-mini
  ./scripts/bench_laaj.sh gpt-4.1 0 "" r$i/gpt-4.1

  # GPT-5 Nano (low/medium/high reasoning)
  ./scripts/bench_laaj.sh gpt-5-nano 0 low r$i/gpt-5-nanolow
  ./scripts/bench_laaj.sh gpt-5-nano 0 medium r$i/gpt-5-nanomedium
  ./scripts/bench_laaj.sh gpt-5-nano 0 high r$i/gpt-5-nanohigh

  # GPT-5 Mini (low/medium/high reasoning)
  ./scripts/bench_laaj.sh gpt-5-mini 0 low r$i/gpt-5-minilow
  ./scripts/bench_laaj.sh gpt-5-mini 0 medium r$i/gpt-5-minimedium
  ./scripts/bench_laaj.sh gpt-5-mini 0 high r$i/gpt-5-minihigh

  # GPT-5 (low/medium/high reasoning)
  ./scripts/bench_laaj.sh gpt-5 0 low r$i/gpt-5low
  ./scripts/bench_laaj.sh gpt-5 0 medium r$i/gpt-5medium
  ./scripts/bench_laaj.sh gpt-5 0 high r$i/gpt-5high

  # GPT-OSS models (via OpenRouter)
  # Note: Uncomment and configure if you have OpenRouter access
  # cp .env.openrouter .env
  # ./scripts/bench_laaj.sh openai/gpt-oss-20b 0 low r$i/openai/gpt-oss-20blow
  # ./scripts/bench_laaj.sh openai/gpt-oss-20b 0 medium r$i/openai/gpt-oss-20bmedium
  # ./scripts/bench_laaj.sh openai/gpt-oss-20b 0 high r$i/openai/gpt-oss-20bhigh
  # ./scripts/bench_laaj.sh openai/gpt-oss-120b 0 low r$i/openai/gpt-oss-120blow
  # ./scripts/bench_laaj.sh openai/gpt-oss-120b 0 medium r$i/openai/gpt-oss-120bmedium
  # ./scripts/bench_laaj.sh openai/gpt-oss-120b 0 high r$i/openai/gpt-oss-120bhigh
  # cp .env.openai .env

  echo ""
  echo "Completed run $i of $RUN_NUM"
  echo ""
done

echo "========================================="
echo "All benchmarks completed!"
echo "Results stored in results/r$START_NUM through results/r$RUN_NUM"
echo ""
echo "Next steps:"
echo "1. Generate CSV files: python src/analysis/eval_laj_run.py --folder results --all-runs"
echo "2. Calculate metrics: python src/analysis/cost_benefit_analysis.py"
echo "3. Generate LaTeX table: python src/analysis/generate_latex_table.py -o results/combined_results_table.tex"
echo "========================================="
