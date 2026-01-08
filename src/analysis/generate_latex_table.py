#!/usr/bin/env python3
"""
Generate the LaTeX table for LLM-as-a-Judge metrics from the summary CSV.

This script mirrors the formatting used in the manuscript:
 - specific row ordering and color highlights
 - bold text for best-in-class metric values
 - mean ± std formatting with per-column precision
"""
from __future__ import annotations

import csv
import argparse
from pathlib import Path
from typing import Dict, List, Sequence

PROJECT_ROOT = Path(__file__).resolve().parents[2]
CSV_PATH = PROJECT_ROOT / "results" / "laj_metrics_summary.csv"

MODEL_ORDER: Sequence[Dict[str, str]] = (
    {"key": "GPT-4o Mini", "label": "GPT-4o Mini", "family": "GPT-4"},
    {"key": "GPT-4o", "label": "GPT-4o", "family": "GPT-4"},
    {"key": "GPT-4.1 Nano", "label": "GPT-4.1 Nano", "family": "GPT-4"},
    {"key": "GPT-4.1 Mini", "label": "GPT-4.1 Mini", "family": "GPT-4"},
    {"key": "GPT-4.1", "label": "GPT-4.1", "family": "GPT-4"},
    {"key": "GPT-5 Nano (low)", "label": "GPT-5 Nano (low)", "family": "GPT-5"},
    {"key": "GPT-5 Nano (medium)", "label": "GPT-5 Nano (medium)", "family": "GPT-5"},
    {"key": "GPT-5 Nano (high)", "label": "GPT-5 Nano (high)", "family": "GPT-5"},
    {"key": "GPT-5 Mini (low)", "label": "GPT-5 Mini (low)", "family": "GPT-5"},
    {"key": "GPT-5 Mini (medium)", "label": "GPT-5 Mini (medium)", "family": "GPT-5"},
    {"key": "GPT-5 Mini (high)", "label": "GPT-5 Mini (high)", "family": "GPT-5"},
    {"key": "GPT-5 (low)", "label": "GPT-5 (low)", "family": "GPT-5"},
    {"key": "GPT-5 (medium)", "label": "GPT-5 (medium)", "family": "GPT-5"},
    {"key": "GPT-5 (high)", "label": "GPT-5 (high)", "family": "GPT-5"},
    {"key": "GPT-OSS 20B (low)", "label": "GPT-OSS 20B (low)", "family": "GPT-OSS"},
    {"key": "GPT-OSS 20B (medium)", "label": "GPT-OSS 20B (med)", "family": "GPT-OSS"},
    {"key": "GPT-OSS 20B (high)", "label": "GPT-OSS 20B (high)", "family": "GPT-OSS"},
    {"key": "GPT-OSS 120B (low)", "label": "GPT-OSS 120B (low)", "family": "GPT-OSS"},
    {"key": "GPT-OSS 120B (medium)", "label": "GPT-OSS 120B (med)", "family": "GPT-OSS"},
    {"key": "GPT-OSS 120B (high)", "label": "GPT-OSS 120B (high)", "family": "GPT-OSS"},
)

ROW_HIGHLIGHTS = {
    "GPT-4o Mini": r"\rowcolor{yellow!20} ",
    "GPT-OSS 20B (high)": r"\rowcolor{red!10} ",
}

FAMILY_TITLES = {
    "GPT-4": "GPT-4 Family",
    "GPT-5": "GPT-5 Family",
    "GPT-OSS": "GPT-OSS Family",
}

# metric_id -> (mean_key, std_key, decimals, direction)
MetricSpec = Dict[str, object]
METRICS: Sequence[MetricSpec] = (
    {"id": "maae", "mean_key": "maae_mean", "std_key": "maae_std", "decimals": 2, "direction": "min"},
    {"id": "aps", "mean_key": "aps_mean", "std_key": "aps_std", "decimals": 2, "direction": "max"},
    {"id": "pmr", "mean_key": "pmr_mean", "std_key": "pmr_std", "decimals": 1, "direction": "max"},
    {"id": "cmr", "mean_key": "cmr_mean", "std_key": "cmr_std", "decimals": 1, "direction": "max"},
    {"id": "ecr", "mean_key": "ecr1_mean", "std_key": "ecr1_std", "decimals": 1, "direction": "max"},
    {"id": "attempts", "mean_key": "attempts_mean", "std_key": "attempts_std", "decimals": 2, "direction": "min"},
    {"id": "cost", "mean_key": "cost_adjusted_mean", "std_key": "cost_adjusted_std", "decimals": 2, "direction": "min"},
)

# Only these metrics receive bold formatting for best performance.
BOLD_METRICS = {"maae", "aps", "pmr", "cmr", "ecr", "cost"}

TOLERANCE = 1e-9


def load_metrics(path: Path) -> Dict[str, Dict[str, Dict[str, float]]]:
    """Load metric values keyed by model and metric id."""
    data: Dict[str, Dict[str, Dict[str, float]]] = {}
    with path.open(newline="") as fh:
        reader = csv.DictReader(fh)
        for row in reader:
            model = row["model"]
            metrics: Dict[str, Dict[str, float]] = {}
            for spec in METRICS:
                metric_id = str(spec["id"])
                metrics[metric_id] = {
                    "mean": float(row[str(spec["mean_key"])]),
                    "std": float(row[str(spec["std_key"])]),
                }
            data[model] = metrics
    return data


def find_best_models(data: Dict[str, Dict[str, Dict[str, float]]]) -> Dict[str, List[str]]:
    """Compute which models achieve the best value per metric."""
    best: Dict[str, List[str]] = {}
    for spec in METRICS:
        metric_id = str(spec["id"])
        direction = str(spec["direction"])
        model_values = {model: metrics[metric_id]["mean"] for model, metrics in data.items()}
        if not model_values:
            best[metric_id] = []
            continue
        comparator = min if direction == "min" else max
        target_value = comparator(model_values.values())
        best_models = [
            model
            for model, value in model_values.items()
            if abs(value - target_value) <= TOLERANCE
        ]
        best[metric_id] = best_models
    return best


def format_mean_std(mean: float, std: float, decimals: int) -> str:
    fmt = f"{{:.{decimals}f}}"
    return f"{fmt.format(mean)}$\\pm${fmt.format(std)}"


def build_table_lines() -> List[str]:
    data = load_metrics(CSV_PATH)
    best_by_metric = find_best_models(data)

    lines: List[str] = [
        r"\begin{table*}[t]",
        r"\centering",
        r"\caption{Complete Model Performance Across All Dimensions (Mean $\pm$ Std, 5 runs)}",
        r"\label{tab:combined_results}",
        r"\scriptsize",
        r"\begin{threeparttable}",
        r"\begin{tabular}{@{}lccccccc@{}}",
        r"\toprule",
        r"\textbf{Model} & \textbf{MAAE} & \textbf{APS} & \textbf{PMR} & \textbf{CMR} & \textbf{ECR@1} & \textbf{Attempts} & \textbf{Cost} \\",
        r" & \textbf{(\%)} & \textbf{(\%)} & \textbf{(\%)} & \textbf{(\%)} & \textbf{(\%)} &  & \textbf{(\$/1K)} \\",
        r"\midrule",
    ]

    current_family: str | None = None

    for entry in MODEL_ORDER:
        model_key = entry["key"]
        display_label = entry["label"]
        family = entry["family"]

        if model_key not in data:
            raise KeyError(f"Model '{model_key}' not found in {CSV_PATH}")

        if family != current_family:
            if current_family is not None:
                lines.append(r"\midrule")
            family_title = FAMILY_TITLES.get(family, f"{family} Family")
            lines.append(rf"\multicolumn{{8}}{{c}}{{\textbf{{{family_title}}}}} \\")
            lines.append(r"\cmidrule(lr){1-8}")
            current_family = family

        metrics = data[model_key]
        row_prefix = ROW_HIGHLIGHTS.get(model_key, "")
        cells: List[str] = []

        model_cell = display_label
        if "yellow" in row_prefix:
            model_cell = r"\textbf{" + model_cell + "}"

        if row_prefix:
            model_cell = f"{row_prefix}{model_cell}"

        cells.append(model_cell)

        for spec in METRICS:
            metric_id = str(spec["id"])
            entry = metrics[metric_id]
            rendered = format_mean_std(entry["mean"], entry["std"], int(spec["decimals"]))
            if metric_id in BOLD_METRICS and model_key in best_by_metric.get(metric_id, ()):
                rendered = r"\textbf{" + rendered + "}"
            cells.append(rendered)

        lines.append(" & ".join(cells) + r" \\")

    lines.extend(
        (
            r"\bottomrule",
            r"\end{tabular}",
            r"\begin{tablenotes}",
            r"\footnotesize",
            r"\item MAAE = Mean Absolute Assessment Error; APS = Assessment Performance Score; PMR = Perfect Match Rate; CMR = Close Match Rate; ECR@1 = Evaluation Completion Rate (first attempt); Cost = adjusted cost per 1K evaluations (accounting for retries). Yellow highlighting indicates optimal production model; red indicates poorest reliability; bold indicates best performance per metric.",
            r"\end{tablenotes}",
            r"\end{threeparttable}",
            r"\end{table*}",
        )
    )

    return lines


def parse_args(argv: Sequence[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Generate the manuscript LaTeX table for LLM-as-a-Judge metrics."
    )
    parser.add_argument(
        "-o",
        "--output",
        type=Path,
        help="Optional path to write the LaTeX table (prints to stdout if omitted).",
    )
    return parser.parse_args(argv)


def main(argv: Sequence[str] | None = None) -> None:
    args = parse_args(argv)
    table_lines = build_table_lines()
    table_text = "\n".join(table_lines) + "\n"

    if args.output:
        args.output.write_text(table_text, encoding="utf-8")
    else:
        print(table_text, end="")


if __name__ == "__main__":
    main()
