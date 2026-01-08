# LLM-as-a-Judge for Scalable Test Coverage Evaluation

**Paper:** "LLM-as-a-Judge for Scalable Test Coverage Evaluation: Accuracy, Operational Reliability, and Cost"

**arXiv:** https://arxiv.org/abs/2512.01232

This repository contains the complete implementation, dataset, and evaluation framework for our AAAI 2026 paper on using LLMs to assess software test coverage at scale.

## Overview

Assessing software test coverage at scale remains a bottleneck in QA pipelines. We present **LLM-as-a-Judge (LAJ)**, a production-ready, rubric-driven framework for evaluating Gherkin acceptance tests with structured JSON outputs.

**Key Contributions:**
- 📊 Comprehensive evaluation of 20 model configurations (GPT-4, GPT-5, GPT-OSS) across 500 runs
- 📈 Novel reliability metrics: Evaluation Completion Rate (ECR@1) and adjusted costs
- 💰 Cost analysis spanning 175× range ($0.45-$78.96 per 1K evaluations)
- 🎯 Production-ready framework with reproducible results
- 📦 Public dataset: 100 expert-annotated Jira tickets + Gherkin test scripts

## Project Structure

```
LAJ-Gherkin/
├── dataset/                          # Benchmark dataset
│   ├── synthetic-jira-tickets-expanded.csv    # 100 Jira tickets
│   ├── benchmark_feautures/                    # 100 ground truth Gherkin scripts
│   ├── jira_coverage_ground_truth.csv          # Expert coverage annotations
│   └── expert-annotations.xlsx                 # Expert validation spreadsheet
│
├── src/
│   ├── laj/                          # LAJ framework implementation
│   │   ├── coverage.py                         # Core coverage analysis
│   │   ├── coverage_llm_prompt.yaml            # System & user prompts
│   │   └── analyze_gherkin_folder.py           # Batch evaluation
│   │
│   └── analysis/                     # Metrics calculation & analysis
│       ├── cost_benefit_analysis.py            # Calculate MAAE, APS, ECR@1, costs
│       ├── eval_laj_run.py                     # Process evaluation results
│       ├── generate_latex_table.py             # Generate paper tables
│       └── model_perf_analysis.py              # Performance comparison
│
├── results/                          # Evaluation results (5 runs)
│   ├── r1/, r2/, r3/, r4/, r5/                # Raw evaluation data per run
│   ├── laj_metrics_summary.csv                 # Aggregated metrics (Table 1)
│   └── combined_results_table.tex              # LaTeX table for paper
│
├── scripts/                          # Experiment runners
│   ├── bench_laaj.sh                           # Run single model evaluation
│   ├── bench_laaj-all.sh                       # Run all 20 models × 5 runs
│   └── model_perf.sh                           # Quick performance analysis
│
├── notebooks/                        # Analysis notebooks
│   ├── 01_EDA.ipynb                            # Exploratory data analysis
│   └── 02_LLM-as-a-Judge.ipynb                 # Main LAJ analysis
│
└── .env.example                      # Environment configuration template
```

## Setup

### Prerequisites
- Python 3.11+
- OpenAI API key (for GPT-4, GPT-4o, GPT-5 models)
- Optional: OpenRouter API key (for GPT-OSS models)

### Installation

1. **Clone the repository**
```bash
git clone https://github.com/inflaton/LAJ-Gherkin.git
cd LAJ-Gherkin
```

2. **Create and activate virtual environment**
```bash
python3 -m venv .venv
source .venv/bin/activate  # On Windows: .venv\Scripts\activate
```

3. **Install dependencies**
```bash
pip install -r requirements.txt
```

4. **Configure environment variables**
```bash
cp .env.example .env
# Edit .env and add your OpenAI API key
```

Required environment variables:
```bash
export OPEN_AI_API_KEY=<your-openai-api-key>
export OPEN_AI_MODEL=gpt-4o
export OPEN_AI_TEMPERATURE=0
export OPEN_AI_MAX_TOKEN=16384
```

### Using OpenRouter for GPT-OSS Models

To evaluate GPT-OSS models via OpenRouter:

1. **Get an OpenRouter API key** from https://openrouter.ai/

2. **Configure environment** - See [.env.openrouter](.env.openrouter) for a complete example (git-ignored):
```bash
export OPENAI_BASE_URL=https://openrouter.ai/api/v1
export OPEN_AI_API_KEY=<your-openrouter-api-key>
export OPEN_AI_MODEL=openai/gpt-oss-20b
export OPEN_AI_TEMPERATURE=0
export OPEN_AI_MAX_TOKEN=16384
```

3. **Run evaluation** as normal:
```bash
./scripts/bench_laaj.sh openai/gpt-oss-20b
```

**GPT-OSS models** evaluated in the paper:
- `openai/gpt-oss-20b` (low/medium/high reasoning effort)
- `qwen/qwen-2.5-72b-instruct` (low/medium/high reasoning effort)
- Other open-source models available via OpenRouter

## Quick Start

### Evaluate a Single Model
```bash
./scripts/bench_laaj.sh gpt-4o-mini
```

### Run Full Benchmark (All 20 Models × 5 Runs)
```bash
./scripts/bench_laaj-all.sh 5  # Run 5 iterations
```

### Generate Paper Results
```bash
# Step 1: Process raw evaluation results
python src/analysis/eval_laj_run.py --folder results --all-runs

# Step 2: Calculate metrics (MAAE, APS, ECR@1, costs)
python src/analysis/cost_benefit_analysis.py

# Step 3: Generate LaTeX table for paper
python src/analysis/generate_latex_table.py -o results/combined_results_table.tex
```

## Dataset

Our benchmark consists of:
- **100 Jira tickets** - Realistic API development scenarios for Kill Bill billing platform
- **100 Gherkin scripts** - Expert-created BDD acceptance tests
- **Ground truth annotations** - Coverage percentages (0-100) from senior QA engineers
- **HTTP method distribution:** GET (50%), POST (21%), DELETE (15%), PUT (14%)

All data is in `dataset/` folder.

## Metrics

The framework calculates comprehensive metrics across three dimensions:

### Accuracy Metrics
- **MAAE** (Mean Absolute Assessment Error): Average deviation from ground truth
- **APS** (Assessment Performance Score): 100 - MAAE
- **PMR** (Perfect Match Rate): % of exact matches
- **CMR** (Close Match Rate): % within ±5pp

### Reliability Metrics
- **ECR@1** (Evaluation Completion Rate): % successful on first attempt
- **Mean Attempts**: Average API calls per evaluation

### Cost Metrics
- **Nominal Cost**: Base cost per 1K evaluations
- **Adjusted Cost**: Cost accounting for retries = Nominal × (100 / ECR@1)
- **Value Score**: APS / Cost

## Key Results

**Best Production Model:** GPT-4o Mini
- MAAE: 6.07 (±0.08)
- ECR@1: 96.6%
- Cost: $1.01/1K evaluations
- 78× cheaper than GPT-5 (high) with better accuracy

**Cost Range:** $0.45 - $78.96 per 1K evaluations (175× difference)

See `results/laj_metrics_summary.csv` for complete results.

## Repository Contents

### Core Framework
- `src/laj/coverage.py` - Main LAJ evaluation logic
- `src/laj/coverage_llm_prompt.yaml` - Rubric-driven prompts
- `src/laj/analyze_gherkin_folder.py` - Batch folder analysis

### Analysis Tools
- `src/analysis/cost_benefit_analysis.py` - Comprehensive metrics calculator
- `src/analysis/generate_latex_table.py` - Paper table generator
- `src/analysis/eval_laj_run.py` - Result aggregator with retry tracking

### Experiments
- `scripts/bench_laaj.sh` - Single model benchmark
- `scripts/bench_laaj-all.sh` - Full 20-model suite
- `notebooks/` - Jupyter notebooks for analysis

## Citation

If you use this work, please cite:

```bibtex
@article{huang2024laj,
  title={LLM-as-a-Judge for Scalable Test Coverage Evaluation: Accuracy, Operational Reliability, and Cost},
  author={Huang, Donghao and Chew, Shila and Dutkiewicz, Anna and Wang, Zhaoxia},
  journal={arXiv preprint arXiv:2512.01232},
  year={2024},
  url={https://arxiv.org/abs/2512.01232}
}
```

## License

MIT License - see [LICENSE](LICENSE) file for details.

## Contact

- **Donghao Huang** - dh.huang.2023@smu.edu.sg
- **Project Link:** https://github.com/inflaton/LAJ-Gherkin

## Acknowledgments

This research was conducted at:
- School of Computing and Information Systems, Singapore Management University
- Mastercard Research and Development

---

**For detailed methodology and findings, please refer to our paper.**
