#!/usr/bin/env python3
"""
Cost-Benefit Analysis V3 - LAJ Paper Metrics

Enhanced with metrics from "LLM-as-a-Judge for Scalable Test Coverage Evaluation" paper:
- ECR@1 (Evaluation Completion Rate at first attempt)
- Mean Attempts per evaluation
- Adjusted costs accounting for retry overhead
- Adjusted value scores

New CSV fields required for full analysis (in order of preference):
- total_attempts: Total number of attempts needed for each evaluation (1, 2, 3, etc.)
- attempt_number: Which attempt this was (1, 2, 3, etc.)
- first_attempt_success: Boolean indicating if succeeded on attempt 1

If these fields are not present, the script will work with existing data and mark
ECR@1/adjusted metrics as "N/A - needs retry tracking"

Usage:
    python cost_benefit_analysis_v3_laj_metrics.py
    python cost_benefit_analysis_v3_laj_metrics.py --base-folder results/llm-as-a-judge-benchmark/new
"""

import argparse
import csv
import math
from collections import Counter, defaultdict
from pathlib import Path
from statistics import mean, pstdev
from typing import Any, Dict, List, Optional

TOKENS_PER_MILLION = 1_000_000

# Default pricing (can be overridden by external file)
DEFAULT_MODEL_PRICING = {
    "GPT-4o": {"prompt_cost_per_1m": 2.50, "completion_cost_per_1m": 10.00},
    "GPT-4o Mini": {"prompt_cost_per_1m": 0.15, "completion_cost_per_1m": 0.60},
    "GPT-4.1": {"prompt_cost_per_1m": 2.00, "completion_cost_per_1m": 8.00},
    "GPT-4.1 Mini": {"prompt_cost_per_1m": 0.40, "completion_cost_per_1m": 1.60},
    "GPT-4.1 Nano": {"prompt_cost_per_1m": 0.10, "completion_cost_per_1m": 0.40},
    "GPT-5": {"prompt_cost_per_1m": 1.25, "completion_cost_per_1m": 10.00},
    "GPT-5 Mini": {"prompt_cost_per_1m": 0.25, "completion_cost_per_1m": 2.00},
    "GPT-5 Nano": {"prompt_cost_per_1m": 0.05, "completion_cost_per_1m": 0.40},
    "GPT-OSS 20B": {"prompt_cost_per_1m": 0.03, "completion_cost_per_1m": 0.15},
    "GPT-OSS 120B": {"prompt_cost_per_1m": 0.05, "completion_cost_per_1m": 0.45},
}


def normalize_cell(value: Any) -> Any:
    """Normalize CSV cell values into Python primitives."""
    if value is None:
        return None
    if isinstance(value, str):
        stripped = value.strip()
        if stripped == "":
            return None
        lowered = stripped.lower()
        if lowered in {"na", "n/a", "none", "null", "nan"}:
            return None
        if lowered in {"true", "false"}:
            return lowered == "true"
        try:
            if "." in stripped or "e" in stripped.lower():
                return float(stripped)
            return int(stripped)
        except ValueError:
            return stripped
    return value


def to_float(value: Any) -> Optional[float]:
    """Safely convert a value to float if possible."""
    if value is None:
        return None
    if isinstance(value, bool):
        return 1.0 if value else 0.0
    if isinstance(value, (int, float)):
        if isinstance(value, float) and not math.isfinite(value):
            return None
        return float(value)
    if isinstance(value, str):
        try:
            return float(value)
        except ValueError:
            return None
    return None


def to_int(value: Any) -> Optional[int]:
    """Safely convert a value to int if possible."""
    if value is None:
        return None
    if isinstance(value, bool):
        return int(value)
    if isinstance(value, int):
        return value
    if isinstance(value, float):
        if not math.isfinite(value):
            return None
        return int(round(value))
    if isinstance(value, str):
        try:
            return int(float(value))
        except ValueError:
            return None
    return None


def to_bool(value: Any) -> bool:
    """Convert a value to boolean using common conventions."""
    if isinstance(value, bool):
        return value
    if isinstance(value, (int, float)):
        return value != 0
    if isinstance(value, str):
        lowered = value.strip().lower()
        if lowered in {"true", "1", "yes", "y"}:
            return True
        if lowered in {"false", "0", "no", "n"}:
            return False
    return False


class CsvTable:
    """Simple CSV helper that mimics the subset of pandas functionality needed here."""

    def __init__(self, rows: List[Dict[str, Any]], columns: List[str]):
        self.rows = rows
        self.columns = columns
        self._column_set = set(columns)

    @classmethod
    def from_csv(cls, path: str) -> "CsvTable":
        with open(path, newline="", encoding="utf-8") as handle:
            reader = csv.DictReader(handle)
            columns = reader.fieldnames or []
            rows = []
            for row in reader:
                normalized = {key: normalize_cell(value) for key, value in row.items()}
                rows.append(normalized)
        return cls(rows, columns)

    def __len__(self) -> int:
        return len(self.rows)

    def has_column(self, column: str) -> bool:
        return column in self._column_set

    def column_values(self, column: str) -> List[Any]:
        return [row.get(column) for row in self.rows]

    def sum_column(self, column: str) -> float:
        if not self.has_column(column):
            return 0.0
        total = 0.0
        for value in self.column_values(column):
            numeric = to_float(value)
            if numeric is not None:
                total += numeric
        return total

    def value_counts(self, column: str) -> Counter:
        counts: Counter = Counter()
        if not self.has_column(column):
            return counts
        for value in self.column_values(column):
            if value is None:
                continue
            counts[value] += 1
        return counts

def normalize_model_name(model_name: str) -> str:
    """Normalize model names for consistent display."""
    name_mapping = {
        "gpt-4o": "GPT-4o",
        "gpt-4o-mini": "GPT-4o Mini",
        "gpt-4.1": "GPT-4.1",
        "gpt-4.1-mini": "GPT-4.1 Mini",
        "gpt-4.1-nano": "GPT-4.1 Nano",
        "gpt-4_1": "GPT-4.1",
        "gpt-4_1-mini": "GPT-4.1 Mini",
        "gpt-4_1-nano": "GPT-4.1 Nano",
        "gpt-5": "GPT-5",
        "gpt-5-mini": "GPT-5 Mini",
        "gpt-5-nano": "GPT-5 Nano",
        # Add reasoning effort variants
        "gpt-5low": "GPT-5 (low)",
        "gpt-5medium": "GPT-5 (medium)",
        "gpt-5high": "GPT-5 (high)",
        "gpt-5-minilow": "GPT-5 Mini (low)",
        "gpt-5-minimedium": "GPT-5 Mini (medium)",
        "gpt-5-minihigh": "GPT-5 Mini (high)",
        "gpt-5-nanolow": "GPT-5 Nano (low)",
        "gpt-5-nanomedium": "GPT-5 Nano (medium)",
        "gpt-5-nanohigh": "GPT-5 Nano (high)",
        "openai_gpt-oss-20blow": "GPT-OSS 20B (low)",
        "openai_gpt-oss-20bmedium": "GPT-OSS 20B (medium)",
        "openai_gpt-oss-20bhigh": "GPT-OSS 20B (high)",
        "openai_gpt-oss-120blow": "GPT-OSS 120B (low)",
        "openai_gpt-oss-120bmedium": "GPT-OSS 120B (medium)",
        "openai_gpt-oss-120bhigh": "GPT-OSS 120B (high)",
    }
    return name_mapping.get(model_name, model_name)


def get_pricing_key(model_name: str) -> str:
    """Map model name to pricing key, removing reasoning effort suffix."""
    if "(low)" in model_name or "(medium)" in model_name or "(high)" in model_name:
        base_name = model_name.split(" (")[0]
        return base_name
    return model_name


def find_all_csv_files(base_folder: str, max_runs: int = None) -> dict:
    """Find all jira_coverage_*.csv files organized by run."""
    base_path = Path(base_folder)

    if not base_path.exists():
        print(f"❌ Base folder not found: {base_folder}")
        return {}

    run_folders = sorted([d for d in base_path.iterdir() if d.is_dir() and d.name.startswith('r')])

    if max_runs:
        run_folders = run_folders[:max_runs]

    print(f"🔍 Found {len(run_folders)} run folder(s): {[f.name for f in run_folders]}")

    results = {}

    for run_folder in run_folders:
        run_name = run_folder.name
        results[run_name] = {}

        csv_files = list(run_folder.rglob("jira_coverage_*.csv"))

        for csv_file in csv_files:
            model_name = csv_file.stem.replace("jira_coverage_", "")
            display_name = normalize_model_name(model_name)
            results[run_name][display_name] = str(csv_file)

        print(f"  ✓ {run_name}: Found {len(results[run_name])} model(s)")

    return results


def calculate_reliability_metrics(table: CsvTable) -> dict:
    """
    Calculate ECR@1 and Mean Attempts from CSV data.

    Expected CSV columns for full metrics (in order of preference):
    - total_attempts: Total number of attempts needed for each evaluation (1, 2, 3, etc.)
    - attempt_number: Which attempt this was (1, 2, 3, etc.)
    - first_attempt_success: Boolean/int (1 if succeeded on first try, 0 otherwise)

    If these columns are missing, returns None values with tracking_available=False.
    """
    has_tracking = False
    ecr1: Optional[float] = None
    mean_attempts: Optional[float] = None
    failure_rate: Optional[float] = None

    if table.has_column("total_attempts"):
        has_tracking = True
        attempts_data: List[int] = []
        for value in table.column_values("total_attempts"):
            parsed = to_int(value)
            if parsed is not None:
                attempts_data.append(parsed)

        if attempts_data:
            mean_attempts = mean(attempts_data)
            total_evals = len(attempts_data)
            first_attempt_successes = sum(1 for entry in attempts_data if entry == 1)
            ecr1 = (first_attempt_successes / total_evals * 100) if total_evals else 0.0
            failure_rate = ((total_evals - first_attempt_successes) / total_evals * 100) if total_evals else 0.0

    elif table.has_column("attempt_number"):
        has_tracking = True
        attempt_counts: Dict[Any, int] = {}
        for row in table.rows:
            jira_id = row.get("jira_id")
            attempt = to_int(row.get("attempt_number"))
            if jira_id is None or attempt is None:
                continue
            previous = attempt_counts.get(jira_id, 0)
            attempt_counts[jira_id] = max(previous, attempt)

        if attempt_counts:
            counts = list(attempt_counts.values())
            mean_attempts = mean(counts)
            total_evals = len(counts)
            first_attempt_successes = sum(1 for value in counts if value == 1)
            ecr1 = (first_attempt_successes / total_evals * 100) if total_evals else 0.0
            failure_rate = ((total_evals - first_attempt_successes) / total_evals * 100) if total_evals else 0.0

    elif table.has_column("first_attempt_success"):
        has_tracking = True
        total_evals = 0
        successes = 0
        for value in table.column_values("first_attempt_success"):
            if value is None:
                continue
            total_evals += 1
            if to_bool(value):
                successes += 1

        if total_evals:
            ecr1 = successes / total_evals * 100
            failures = total_evals - successes
            mean_attempts = (successes * 1.0 + failures * 2.0) / total_evals
            failure_rate = failures / total_evals * 100

    return {
        "tracking_available": has_tracking,
        "ecr1": ecr1,
        "mean_attempts": mean_attempts,
        "failure_rate": failure_rate,
    }


def analyze_single_run(csv_path: str, model_name: str, ground_truth_lookup: Dict[Any, float], pricing_table: dict) -> Optional[dict]:
    """Analyze a single CSV file and return metrics including reliability metrics."""
    try:
        table = CsvTable.from_csv(csv_path)

        errors: List[float] = []
        abs_errors: List[float] = []
        perfect_matches = 0
        close_matches = 0

        for row in table.rows:
            jira_id = row.get("jira_id")
            truth = ground_truth_lookup.get(jira_id)
            predicted_raw = row.get("coverage_percentage")
            predicted = to_float(predicted_raw)

            if truth is None or predicted is None:
                continue

            error = predicted - truth
            abs_error = abs(error)

            errors.append(error)
            abs_errors.append(abs_error)

            if abs_error < 1e-9:
                perfect_matches += 1
            if abs_error <= 5.0 + 1e-9:
                close_matches += 1

        if not abs_errors:
            return None

        maae = mean(abs_errors)

        # NEW: Calculate reliability metrics
        reliability_metrics = calculate_reliability_metrics(table)

        # Get pricing info
        pricing_key = get_pricing_key(model_name)
        pricing_info = pricing_table.get(pricing_key, {
            "prompt_cost_per_1m": 0.0,
            "completion_cost_per_1m": 0.0,
        })

        # Calculate nominal costs
        prompt_tokens_sum = table.sum_column("prompt_tokens")
        completion_tokens_sum = table.sum_column("completion_tokens")
        num_evals = len(table)

        prompt_cost_total = (prompt_tokens_sum / TOKENS_PER_MILLION) * pricing_info["prompt_cost_per_1m"]
        completion_cost_total = (completion_tokens_sum / TOKENS_PER_MILLION) * pricing_info["completion_cost_per_1m"]
        total_cost = prompt_cost_total + completion_cost_total

        avg_cost_per_eval = total_cost / num_evals if num_evals else 0.0
        cost_per_1k_nominal = avg_cost_per_eval * 1000

        # NEW: Calculate adjusted costs accounting for reliability
        cost_per_1k_adjusted: Optional[float] = None
        cost_increase_pct: Optional[float] = None

        ecr1_metric = reliability_metrics["ecr1"]
        if reliability_metrics["tracking_available"] and ecr1_metric is not None and ecr1_metric > 0:
            cost_per_1k_adjusted = cost_per_1k_nominal * (100.0 / ecr1_metric)
            if cost_per_1k_nominal > 0:
                cost_increase_pct = ((cost_per_1k_adjusted - cost_per_1k_nominal) / cost_per_1k_nominal * 100)

        status_counts = table.value_counts("status")

        result = {
            "maae": maae,
            "aps": 100 - maae,  # Assessment Performance Score
            "success": status_counts.get("completed", 0),
            "perfect_matches": perfect_matches,
            "close_matches": close_matches,
            "pmr": (perfect_matches / num_evals * 100) if num_evals else 0,  # Perfect Match Rate
            "cmr": (close_matches / num_evals * 100) if num_evals else 0,  # Close Match Rate
            # Nominal costs
            "cost_per_1k_nominal": cost_per_1k_nominal,
            "avg_cost_per_eval": avg_cost_per_eval,
            # Reliability metrics
            "ecr1": reliability_metrics["ecr1"],
            "mean_attempts": reliability_metrics["mean_attempts"],
            "failure_rate": reliability_metrics["failure_rate"],
            "tracking_available": reliability_metrics["tracking_available"],
            # Adjusted costs
            "cost_per_1k_adjusted": cost_per_1k_adjusted,
            "cost_increase_pct": cost_increase_pct,
            # Additional info
            "num_evals": num_evals,
            "prompt_tokens": prompt_tokens_sum,
            "completion_tokens": completion_tokens_sum,
        }

        return result

    except Exception as exc:
        print(f"  ✗ Error analyzing {csv_path}: {exc}")
        return None


def aggregate_multi_run_results(run_data: dict, ground_truth_path: str, pricing_table: dict) -> list:
    """Aggregate results across multiple runs with LAJ metrics."""
    
    ground_truth_table = CsvTable.from_csv(ground_truth_path)
    ground_truth_lookup: Dict[Any, float] = {}
    for row in ground_truth_table.rows:
        jira_id = row.get("jira_id")
        coverage = to_float(row.get("coverage_percentage"))
        if jira_id is None or coverage is None:
            continue
        ground_truth_lookup[jira_id] = coverage

    print(f"\n✓ Ground truth loaded from {ground_truth_path}")
    print(f"\n📊 Analyzing {len(run_data)} run(s)...\n")

    model_runs = defaultdict(list)

    for run_name, models in sorted(run_data.items()):
        print(f"Processing {run_name}...")
        for model_name, csv_path in models.items():
            result = analyze_single_run(csv_path, model_name, ground_truth_lookup, pricing_table)
            if result:
                model_runs[model_name].append(result)
                ecr1_str = f"ECR@1={result['ecr1']:.1f}%" if result['ecr1'] is not None else "ECR@1=N/A"
                print(f"  ✓ {model_name}: MAE={result['maae']:.2f}, {ecr1_str}, Cost=${result['cost_per_1k_nominal']:.2f}/1K")

    print(f"\n📈 Computing statistics across runs...\n")

    aggregated_results = []

    for model_name, runs in sorted(model_runs.items()):
        if not runs:
            continue

        num_runs = len(runs)
        
        # Check if any run has reliability tracking
        has_reliability = any(r["tracking_available"] for r in runs)

        # Calculate statistics for all metrics
        maae_values = [r["maae"] for r in runs]
        aps_values = [r["aps"] for r in runs]
        cost_nominal_values = [r["cost_per_1k_nominal"] for r in runs]
        pmr_values = [r["pmr"] for r in runs]
        cmr_values = [r["cmr"] for r in runs]
        
        # Reliability metrics (may be None)
        ecr1_values = [r["ecr1"] for r in runs if r["ecr1"] is not None]
        attempts_values = [r["mean_attempts"] for r in runs if r["mean_attempts"] is not None]
        cost_adj_values = [r["cost_per_1k_adjusted"] for r in runs if r["cost_per_1k_adjusted"] is not None]

        pricing_key = get_pricing_key(model_name)
        pricing_info = pricing_table.get(pricing_key, {
            "prompt_cost_per_1m": 0.0,
            "completion_cost_per_1m": 0.0,
        })

        generation = "GPT-4" if "GPT-4" in model_name else "GPT-5"
        
        # Calculate nominal value score: APS / Cost_nominal
        aps_mean = mean(aps_values)
        cost_nominal_mean = mean(cost_nominal_values)
        value_nominal = aps_mean / cost_nominal_mean if cost_nominal_mean > 0 else 0
        
        # Calculate adjusted metrics if available
        ecr1_mean = mean(ecr1_values) if ecr1_values else None
        ecr1_std = pstdev(ecr1_values) if len(ecr1_values) > 1 else 0.0
        attempts_mean = mean(attempts_values) if attempts_values else None
        attempts_std = pstdev(attempts_values) if len(attempts_values) > 1 else 0.0
        cost_adj_mean = mean(cost_adj_values) if cost_adj_values else None
        cost_adj_std = pstdev(cost_adj_values) if len(cost_adj_values) > 1 else 0.0
        
        # Calculate adjusted value score: APS / Cost_adjusted
        value_adjusted = aps_mean / cost_adj_mean if (cost_adj_mean is not None and cost_adj_mean > 0) else None
        
        # Calculate cost increase percentage
        if cost_adj_mean and cost_nominal_mean > 0:
            cost_increase = ((cost_adj_mean - cost_nominal_mean) / cost_nominal_mean * 100)
        else:
            cost_increase = None

        result = {
            "model": model_name,
            "num_runs": num_runs,
            "generation": generation,
            # Accuracy metrics
            "maae_mean": mean(maae_values),
            "maae_std": pstdev(maae_values) if num_runs > 1 else 0.0,
            "aps_mean": aps_mean,
            "aps_std": pstdev(aps_values) if num_runs > 1 else 0.0,
            "pmr_mean": mean(pmr_values),
            "pmr_std": pstdev(pmr_values) if num_runs > 1 else 0.0,
            "cmr_mean": mean(cmr_values),
            "cmr_std": pstdev(cmr_values) if num_runs > 1 else 0.0,
            # Reliability metrics (NEW)
            "ecr1_mean": ecr1_mean,
            "ecr1_std": ecr1_std,
            "attempts_mean": attempts_mean,
            "attempts_std": attempts_std,
            "has_reliability": has_reliability,
            # Cost metrics
            "cost_nominal_mean": cost_nominal_mean,
            "cost_nominal_std": pstdev(cost_nominal_values) if num_runs > 1 else 0.0,
            "cost_adjusted_mean": cost_adj_mean,
            "cost_adjusted_std": cost_adj_std,
            "cost_increase_pct": cost_increase,
            # Value scores
            "value_nominal": value_nominal,
            "value_adjusted": value_adjusted,
            # Pricing info
            "prompt_cost_per_1m": pricing_info["prompt_cost_per_1m"],
            "completion_cost_per_1m": pricing_info["completion_cost_per_1m"],
        }

        aggregated_results.append(result)
        
        # Print summary
        ecr1_display = f"ECR@1={ecr1_mean:.1f}±{ecr1_std:.1f}%" if ecr1_mean is not None else "ECR@1=N/A"
        cost_adj_display = f"${cost_adj_mean:.2f}±${cost_adj_std:.2f}" if cost_adj_mean is not None else "N/A"
        
        print(f"✓ {model_name}:")
        print(f"  MAE={result['maae_mean']:.2f}±{result['maae_std']:.2f}, APS={result['aps_mean']:.2f}±{result['aps_std']:.2f}")
        print(f"  {ecr1_display}, Cost(nom)=${cost_nominal_mean:.2f}±${result['cost_nominal_std']:.2f}/1K, Cost(adj)={cost_adj_display}/1K")
        value_adj_display = f"{value_adjusted:.2f}" if value_adjusted is not None else "N/A"
        print(f"  Value(nom)={value_nominal:.2f}, Value(adj)={value_adj_display} ({num_runs} run(s))")

    return aggregated_results


def print_laj_summary_table(results: list):
    """Print comprehensive LAJ summary table with all new metrics."""
    if not results:
        print("No model results to summarize.")
        return

    # Check if any model has reliability tracking
    has_reliability = any(r["has_reliability"] for r in results)

    print("\n" + "=" * 200)
    print("LAJ PERFORMANCE & COST ANALYSIS - Complete Metrics")
    print("=" * 200)
    
    if has_reliability:
        # Full table with reliability metrics
        print(
            f"{'Rank':<5} {'Model':<25} {'MAAE':<15} {'APS':<15} {'PMR':<12} {'CMR':<12} "
            f"{'ECR@1':<15} {'Attempts':<12} {'Cost(nom)':<18} {'Cost(adj)':<18} {'V(nom)':<10} {'V(adj)':<10}"
        )
        print("-" * 200)
        
        sorted_results = sorted(results, key=lambda x: x["maae_mean"])
        
        for i, r in enumerate(sorted_results, 1):
            maae_str = f"{r['maae_mean']:.2f}±{r['maae_std']:.2f}"
            aps_str = f"{r['aps_mean']:.2f}±{r['aps_std']:.2f}"
            cost_nom_str = f"${r['cost_nominal_mean']:.2f}±${r['cost_nominal_std']:.2f}"
            pmr_str = f"{r['pmr_mean']:.1f}±{r['pmr_std']:.1f}"
            cmr_str = f"{r['cmr_mean']:.1f}±{r['cmr_std']:.1f}"
            
            if r["ecr1_mean"] is not None:
                ecr1_str = f"{r['ecr1_mean']:.1f}±{r['ecr1_std']:.1f}%"
                if r["attempts_mean"] is not None:
                    attempts_str = f"{r['attempts_mean']:.2f}±{r['attempts_std']:.2f}"
                else:
                    attempts_str = "N/A"
                if r["cost_adjusted_mean"] is not None:
                    cost_adj_str = f"${r['cost_adjusted_mean']:.2f}±${r['cost_adjusted_std']:.2f}"
                else:
                    cost_adj_str = "N/A"
                value_adj_str = f"{r['value_adjusted']:.2f}" if r["value_adjusted"] is not None else "N/A"
            else:
                ecr1_str = "N/A"
                attempts_str = "N/A"
                cost_adj_str = "N/A"
                value_adj_str = "N/A"
            
            medal = "🏆" if i == 1 else ("🥈" if i == 2 else ("🥉" if i == 3 else ""))
            
            print(
                f"{i:<5} {r['model']:<25} {maae_str:<15} {aps_str:<15} "
                f"{pmr_str:<12} {cmr_str:<12} {ecr1_str:<15} {attempts_str:<12} "
                f"{cost_nom_str:<18} {cost_adj_str:<18} {r['value_nominal']:<10.2f} {value_adj_str:<10} {medal}"
            )
    else:
        # Simplified table without reliability metrics
        print("⚠️  No reliability tracking data found. To enable ECR@1 and adjusted metrics,")
        print("   add 'total_attempts', 'attempt_number', or 'first_attempt_success' columns to your CSV files.\n")
        
        print(
            f"{'Rank':<5} {'Model':<25} {'MAAE':<15} {'APS':<15} {'PMR':<12} {'CMR':<12} "
            f"{'Cost/1K':<18} {'Value':<10}"
        )
        print("-" * 120)
        
        sorted_results = sorted(results, key=lambda x: x["maae_mean"])
        
        for i, r in enumerate(sorted_results, 1):
            maae_str = f"{r['maae_mean']:.2f}±{r['maae_std']:.2f}"
            aps_str = f"{r['aps_mean']:.2f}±{r['aps_std']:.2f}"
            cost_str = f"${r['cost_nominal_mean']:.2f}±${r['cost_nominal_std']:.2f}"
            pmr_str = f"{r['pmr_mean']:.1f}±{r['pmr_std']:.1f}"
            cmr_str = f"{r['cmr_mean']:.1f}±{r['cmr_std']:.1f}"
            
            medal = "🏆" if i == 1 else ("🥈" if i == 2 else ("🥉" if i == 3 else ""))
            
            print(
                f"{i:<5} {r['model']:<25} {maae_str:<15} {aps_str:<15} "
                f"{pmr_str:<12} {cmr_str:<12} {cost_str:<18} {r['value_nominal']:<10.2f} {medal}"
            )

    print("-" * 200)

    # Analysis sections
    print("\n📊 DETAILED ANALYSIS:")
    
    # Best accuracy
    best_acc = sorted(results, key=lambda x: x["maae_mean"])[0]
    print(f"\n✨ BEST ACCURACY: {best_acc['model']}")
    print(f"   MAAE: {best_acc['maae_mean']:.2f}±{best_acc['maae_std']:.2f} pp")
    print(f"   APS: {best_acc['aps_mean']:.2f}±{best_acc['aps_std']:.2f}%")
    
    # Cost analysis
    cheapest_nom = min(results, key=lambda x: x["cost_nominal_mean"])
    print(f"\n💰 LOWEST NOMINAL COST: {cheapest_nom['model']}")
    print(f"   ${cheapest_nom['cost_nominal_mean']:.2f}±${cheapest_nom['cost_nominal_std']:.2f} per 1K evals")
    
    if has_reliability:
        # Reliability analysis
        reliable_models = [r for r in results if r["ecr1_mean"] is not None]
        if reliable_models:
            best_reliability = max(reliable_models, key=lambda x: x["ecr1_mean"])
            print(f"\n🎯 HIGHEST RELIABILITY: {best_reliability['model']}")
            print(f"   ECR@1: {best_reliability['ecr1_mean']:.1f}±{best_reliability['ecr1_std']:.1f}%")
            if best_reliability["attempts_mean"] is not None:
                print(f"   Mean Attempts: {best_reliability['attempts_mean']:.2f}±{best_reliability['attempts_std']:.2f}")
            else:
                print("   Mean Attempts: N/A")
            
            # Best adjusted value
            adj_value_models = [r for r in results if r["value_adjusted"] is not None]
            if adj_value_models:
                best_adj_value = max(adj_value_models, key=lambda x: x["value_adjusted"])
                print(f"\n⭐ BEST ADJUSTED VALUE: {best_adj_value['model']}")
                print(f"   Value (adjusted): {best_adj_value['value_adjusted']:.2f} APS/$")
                print(f"   APS: {best_adj_value['aps_mean']:.2f}, Cost (adjusted): ${best_adj_value['cost_adjusted_mean']:.2f}/1K")
                print(f"   ECR@1: {best_adj_value['ecr1_mean']:.1f}%")
            
            # Cost impact analysis
            print(f"\n📈 RELIABILITY COST IMPACT:")
            impact_models = [r for r in results if r["cost_increase_pct"] is not None]
            if impact_models:
                max_impact = max(impact_models, key=lambda x: x["cost_increase_pct"])
                min_impact = min(impact_models, key=lambda x: x["cost_increase_pct"])
                print(f"   Highest impact: {max_impact['model']} (+{max_impact['cost_increase_pct']:.1f}%)")
                print(f"   Lowest impact: {min_impact['model']} (+{min_impact['cost_increase_pct']:.1f}%)")
    else:
        print("\n⚠️  Enable reliability tracking to see:")
        print("   - ECR@1 (Evaluation Completion Rate)")
        print("   - Mean Attempts per evaluation")
        print("   - Adjusted costs accounting for retries")
        print("   - Adjusted value scores")
        print("\n   See instructions in script header for how to add retry tracking.")

    # Production recommendation
    print(f"\n🎖️  PRODUCTION RECOMMENDATION:")
    # Find model with best balance of accuracy and cost
    scored_models = []
    for r in results:
        # Score: prioritize accuracy, but penalize high cost
        # Higher APS is better, lower cost is better
        if r["value_adjusted"] is not None:
            score = r["value_adjusted"]  # Use adjusted value if available
        else:
            score = r["value_nominal"]
        scored_models.append((r, score))
    
    best_balanced = max(scored_models, key=lambda x: x[1])[0]
    print(f"   {best_balanced['model']}")
    print(f"   - APS: {best_balanced['aps_mean']:.2f}% (accuracy)")
    if best_balanced['ecr1_mean'] is not None:
        print(f"   - ECR@1: {best_balanced['ecr1_mean']:.1f}% (reliability)")
        if best_balanced["cost_adjusted_mean"] is not None:
            print(f"   - Cost: ${best_balanced['cost_adjusted_mean']:.2f}/1K (adjusted)")
        else:
            print("   - Cost: N/A (adjusted)")
        if best_balanced["value_adjusted"] is not None:
            print(f"   - Value: {best_balanced['value_adjusted']:.2f} APS/$ (adjusted)")
        else:
            print("   - Value: N/A (adjusted)")
    else:
        print(f"   - Cost: ${best_balanced['cost_nominal_mean']:.2f}/1K")
        print(f"   - Value: {best_balanced['value_nominal']:.2f} APS/$")


def save_results_to_csv(results: list, output_path: str):
    """Save aggregated results to CSV with all LAJ metrics."""
    if not results:
        print("\n⚠️ No results to save.")
        return

    # Reorder columns for better readability
    column_order = [
        "model", "num_runs", "generation",
        # Accuracy
        "maae_mean", "maae_std", "aps_mean", "aps_std", "pmr_mean", "pmr_std", "cmr_mean", "cmr_std",
        # Reliability
        "ecr1_mean", "ecr1_std", "attempts_mean", "attempts_std",
        # Costs
        "cost_nominal_mean", "cost_nominal_std", "cost_adjusted_mean", "cost_adjusted_std", "cost_increase_pct",
        # Value
        "value_nominal", "value_adjusted",
        # Pricing
        "prompt_cost_per_1m", "completion_cost_per_1m",
    ]

    available_columns = set()
    for row in results:
        available_columns.update(row.keys())

    ordered_columns = [col for col in column_order if col in available_columns]
    remaining_columns = [col for col in sorted(available_columns) if col not in ordered_columns]
    fieldnames = ordered_columns + remaining_columns

    with open(output_path, "w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=fieldnames)
        writer.writeheader()
        for row in results:
            sanitized = {}
            for column in fieldnames:
                value = row.get(column)
                if value is None:
                    sanitized[column] = ""
                elif isinstance(value, float):
                    if not math.isfinite(value):
                        sanitized[column] = ""
                    else:
                        sanitized[column] = value
                else:
                    sanitized[column] = value
            writer.writerow(sanitized)

    print(f"\n✓ Results saved to: {output_path}")


def print_data_collection_guide():
    """Print instructions for collecting reliability data."""
    print("\n" + "=" * 80)
    print("HOW TO ENABLE RELIABILITY TRACKING (ECR@1, Adjusted Costs)")
    print("=" * 80)
    print("""
To fully utilize LAJ metrics, your CSV files should track retry attempts.

OPTION 1: Add 'total_attempts' column (RECOMMENDED - SIMPLEST)
---------------------------------------------------------------
Track the total number of attempts needed for each evaluation.

Example CSV structure:
    jira_id,coverage_percentage,total_attempts,status,prompt_tokens,completion_tokens
    ticket-1,85,1,completed,1200,800  # Succeeded on first try
    ticket-2,90,1,completed,1150,750
    ticket-3,75,2,completed,1200,800  # Required 2 attempts
    ticket-4,95,1,completed,1100,700
    ticket-5,80,3,completed,1250,850  # Required 3 attempts

OPTION 2: Add 'attempt_number' column
--------------------------------------
Track which attempt each row represents (used when logging each attempt separately).

Example CSV structure:
    jira_id,coverage_percentage,attempt_number,status,prompt_tokens,completion_tokens
    ticket-1,85,1,completed,1200,800
    ticket-2,90,1,completed,1150,750
    ticket-3,75,2,completed,1200,800  # This is the 2nd (successful) attempt
    ticket-4,95,1,completed,1100,700

OPTION 3: Add 'first_attempt_success' column
----------------------------------------------
Boolean/int flag: 1 if succeeded on first try, 0 if required retry.

Example CSV structure:
    jira_id,coverage_percentage,first_attempt_success,status,prompt_tokens,completion_tokens
    ticket-1,85,1,completed,1200,800  # Success on first attempt
    ticket-2,90,1,completed,1150,750
    ticket-3,75,0,completed,1200,800  # Required retry
    ticket-4,95,1,completed,1100,700

IMPLEMENTATION EXAMPLE (for total_attempts):
--------------------------------------------
```python
def evaluate_with_retry_tracking(test_case, model, max_attempts=5):
    for attempt in range(1, max_attempts + 1):
        result = model.evaluate(test_case)
        
        if is_valid_result(result):
            return {
                'jira_id': test_case.id,
                'coverage_percentage': result.coverage,
                'total_attempts': attempt,  # How many attempts it took
                'status': 'completed',
                'prompt_tokens': result.prompt_tokens,
                'completion_tokens': result.completion_tokens,
                'eval_time': result.eval_time
            }
    
    # Failed after max attempts
    return None
```

Once you add retry tracking, this script will automatically calculate:
- ECR@1: % of evaluations that succeed on first attempt
- Mean Attempts: Average number of tries needed
- Adjusted Cost: Real cost accounting for retries = Cost_nominal × (100 / ECR@1)
- Adjusted Value: True cost-performance = APS / Cost_adjusted
- Cost Increase %: How much reliability issues inflate costs
""")
    print("=" * 80)


def main():
    parser = argparse.ArgumentParser(
        description="Multi-run LAJ cost-benefit analysis with reliability metrics"
    )
    parser.add_argument(
        "--base-folder",
        type=str,
        default="results",
        help="Base folder containing run subfolders (default: results)",
    )
    parser.add_argument(
        "--ground-truth",
        type=str,
        default="dataset/jira_coverage_ground_truth.csv",
        help="Path to ground truth CSV",
    )
    parser.add_argument(
        "--runs",
        type=int,
        default=None,
        help="Maximum number of runs to analyze (default: all)",
    )
    parser.add_argument(
        "--output",
        type=str,
        default=None,
        help="Output CSV path (default: <base_folder>/laj_metrics_summary.csv)",
    )
    parser.add_argument(
        "--show-guide",
        action="store_true",
        help="Show data collection guide for reliability tracking",
    )

    args = parser.parse_args()

    if args.show_guide:
        print_data_collection_guide()
        return 0

    if args.output is None:
        base_path = Path(args.base_folder)
        args.output = str(base_path / "laj_metrics_summary.csv")

    print("=" * 80)
    print("LLM-as-a-Judge Cost-Benefit Analysis V3 - LAJ Paper Metrics")
    print("=" * 80)

    # Find CSV files
    run_data = find_all_csv_files(args.base_folder, args.runs)

    if not run_data:
        print("❌ No CSV files found. Exiting.")
        print("\nRun with --show-guide to see how to structure your data.")
        return 1

    # Aggregate results
    results = aggregate_multi_run_results(run_data, args.ground_truth, DEFAULT_MODEL_PRICING)

    if not results:
        print("❌ No results to analyze. Exiting.")
        return 1

    # Print comprehensive summary
    print_laj_summary_table(results)

    # Save results
    save_results_to_csv(results, args.output)

    print("\n" + "=" * 80)
    print("✓ Analysis complete!")
    print("=" * 80)
    
    # Check if reliability tracking was available
    has_reliability = any(r["has_reliability"] for r in results)
    if not has_reliability:
        print("\n💡 TIP: Run with --show-guide to learn how to enable reliability tracking")

    return 0


if __name__ == "__main__":
    exit(main())
