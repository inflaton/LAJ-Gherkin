#!/usr/bin/env python3
"""
Automated evaluation script for LLM-as-a-Judge benchmark results with retry tracking.

This script now supports retry metrics by:
1. Finding ALL folder_coverage_summary_*.json files (not just latest)
2. Tracking which attempt each evaluation succeeded on
3. Generating CSV with attempt_number and total_attempts columns

Key features:
- Multiple JSON files = multiple attempts for failed evaluations
- Earlier timestamps = earlier attempts
- Tracks attempt_number for each successful evaluation
- Tracks total_attempts made for each ticket

Usage:
    # Process single run with retry tracking
    python src/analysis/eval_laj_run.py --folder results/llm-as-a-judge-benchmark/new/r2
    
    # Process all runs
    python src/analysis/eval_laj_run.py --folder results/llm-as-a-judge-benchmark/new --all-runs
    
    # Include partial results (failed evaluations)
    python src/analysis/eval_laj_run.py --folder results/llm-as-a-judge-benchmark/new/r2 --include-failed
"""

import argparse
import glob
import json
import os
from collections import defaultdict
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Optional, Tuple

import pandas as pd


def load_json_file(json_file_path: str) -> Dict:
    """Load JSON file and return data."""
    with open(json_file_path, "r") as f:
        return json.load(f)


def extract_timestamp_from_filename(filepath: str) -> str:
    """
    Extract timestamp from filename.
    
    Example: folder_coverage_summary_20251014_083723.json -> 20251014_083723
    """
    filename = os.path.basename(filepath)
    parts = filename.replace("folder_coverage_summary_", "").replace(".json", "")
    return parts


def find_all_summary_jsons(model_path: str) -> List[Tuple[str, str]]:
    """
    Find ALL folder_coverage_summary_*.json files in a model folder.
    
    Returns list of tuples: [(json_path, timestamp), ...]
    Sorted by timestamp (earliest first = attempt 1)
    """
    json_files = glob.glob(os.path.join(model_path, "folder_coverage_summary_*.json"))
    
    if not json_files:
        return []
    
    # Extract timestamps and sort
    json_with_timestamps = [
        (json_file, extract_timestamp_from_filename(json_file))
        for json_file in json_files
    ]
    
    # Sort by timestamp (earliest first)
    json_with_timestamps.sort(key=lambda x: x[1])
    
    return json_with_timestamps


def consolidate_results_with_attempts(json_paths_with_timestamps: List[Tuple[str, str]]) -> pd.DataFrame:
    """
    Consolidate results from multiple JSON files (representing retry attempts).
    
    Logic for total_attempts:
    - Sort JSON files by filename (timestamp)
    - For each jira_id, start with total_attempts = 0
    - For each file in order: total_attempts += 1
    - If status is "completed", stop counting (exit loop)
    - If status is "failed", continue to next file
    
    Returns DataFrame with columns:
    - jira_id
    - coverage_percentage
    - total_attempts (how many attempts until success/final attempt)
    - status
    - eval_time
    - prompt_tokens
    - completion_tokens
    """
    # Group results by jira_id across all attempts
    jira_attempts = defaultdict(list)
    
    for attempt_num, (json_path, timestamp) in enumerate(json_paths_with_timestamps, start=1):
        json_data = load_json_file(json_path)
        base_folder = os.path.dirname(json_path)
        
        for result in json_data["results"]:
            jira_id = result["jira_id"]
            
            # Extract metadata
            eval_time = get_eval_time(result.get("benchmark_report_path", ""), base_folder)
            
            # Extract token usage
            coverage_details = result.get("coverage_details", [])
            if coverage_details and coverage_details[0] and "usage" in coverage_details[0]:
                usage = coverage_details[0]["usage"]
                prompt_tokens = usage.get("prompt_tokens", 0) if usage else 0
                completion_tokens = usage.get("completion_tokens", 0) if usage else 0
            else:
                prompt_tokens = 0
                completion_tokens = 0
            
            # Normalize status
            status = "failed" if result.get("status") == "failed" else "completed"
            
            jira_attempts[jira_id].append({
                "attempt_number": attempt_num,
                "timestamp": timestamp,
                "jira_id": jira_id,
                "coverage_percentage": result.get("coverage_percentage", 0),
                "status": status,
                "eval_time": eval_time,
                "prompt_tokens": prompt_tokens,
                "completion_tokens": completion_tokens,
            })
    
    # For each jira_id, count attempts until success
    consolidated_results = []
    
    for jira_id, attempts in jira_attempts.items():
        # Sort attempts by attempt_number to ensure correct ordering
        attempts.sort(key=lambda x: x["attempt_number"])
        
        # Count attempts until we hit "completed" status
        total_attempts = 0
        final_attempt = None
        
        for attempt in attempts:
            total_attempts += 1
            final_attempt = attempt
            
            # If completed, stop counting
            if attempt["status"] == "completed":
                break
        
        # Use the final attempt (either first success or last failure)
        result = final_attempt.copy()
        result["total_attempts"] = total_attempts
        
        # Remove columns we don't want in the output
        result.pop("attempt_number", None)
        result.pop("timestamp", None)
        
        consolidated_results.append(result)
    
    # Convert to DataFrame
    df = pd.DataFrame(consolidated_results)
    
    # Sort by jira_id
    df["jira_id"] = df["jira_id"].astype(int)
    df = df.sort_values(by="jira_id").reset_index(drop=True)
    
    return df


def get_eval_time(benchmark_report_path: str, base_folder: str) -> float:
    """Extract evaluation time from benchmark report."""
    if not benchmark_report_path:
        return 0.0
    
    # Normalize path
    benchmark_report_path = benchmark_report_path.replace("../../../qualityguardian-eval", ".")
    benchmark_report_path = benchmark_report_path.replace(":", "-")
    
    # Make path absolute if it's relative
    if not os.path.isabs(benchmark_report_path):
        benchmark_report_path = os.path.join(os.getcwd(), benchmark_report_path)
    
    try:
        detail = load_json_file(benchmark_report_path)
        return detail["benchmark_results"]["average_generation_time_seconds"]
    except (FileNotFoundError, KeyError, json.JSONDecodeError):
        return 0.0


def find_all_model_results(base_folder: str) -> List[Dict]:
    """
    Find all model results under the base folder.
    
    Now returns info about ALL JSON files (for retry tracking).
    
    Returns a list of dicts with:
    - model_name: name of the model
    - model_path: path to the model folder
    - json_files: list of (json_path, timestamp) tuples
    - num_json_files: count of JSON files (indicates retry attempts)
    - latest_summary: data from most recent JSON
    """
    results = []
    
    # Walk through all subdirectories
    for root, dirs, files in os.walk(base_folder):
        # Find ALL summary JSON files in this directory
        json_files = find_all_summary_jsons(root)
        
        if json_files:
            # Load the latest JSON for summary stats
            latest_json_path = json_files[-1][0]
            latest_data = load_json_file(latest_json_path)
            
            # Extract model name from path relative to base_folder
            rel_path = os.path.relpath(root, base_folder)
            model_name = rel_path.replace(os.sep, "/")
            
            results.append({
                "model_name": model_name,
                "model_path": root,
                "json_files": json_files,
                "num_json_files": len(json_files),
                "latest_summary": latest_data,
                "failed_files": latest_data.get("failed_files", 0),
                "total_files": latest_data.get("total_files", 0),
                "analyzed_files": latest_data.get("analyzed_files", 0),
                "average_coverage": latest_data.get("average_coverage", 0),
            })
    
    return results


def generate_csv_for_model(model_result: Dict, output_folder: str) -> str:
    """
    Generate a CSV file for a model with retry tracking.
    
    Args:
        model_result: Dict containing model info including all JSON files
        output_folder: Where to save the CSV
    
    Returns:
        Path to the generated CSV file
    """
    model_name = model_result["model_name"]
    json_files = model_result["json_files"]
    
    # Consolidate results across all attempts
    df_model = consolidate_results_with_attempts(json_files)
    
    # Generate output filename
    safe_model_name = model_name.replace("/", "_").replace("\\", "_")
    csv_filename = f"jira_coverage_{safe_model_name}.csv"
    csv_path = os.path.join(output_folder, csv_filename)
    
    # Save to CSV
    df_model.to_csv(csv_path, index=False)
    
    return csv_path


def calculate_success_rate(df: pd.DataFrame) -> float:
    """Calculate success rate (completed evaluations)."""
    if len(df) == 0:
        return 0.0
    
    completed = (df["status"] == "completed").sum()
    total = len(df)
    
    return (completed / total) * 100


def calculate_mean_attempts(df: pd.DataFrame) -> float:
    """Calculate mean number of attempts per evaluation."""
    if len(df) == 0:
        return 0.0
    
    return df["total_attempts"].mean()


def process_single_run(run_folder: str, include_failed: bool = False) -> Dict:
    """Process a single run folder and return summary statistics with retry tracking."""
    output_folder = run_folder
    os.makedirs(output_folder, exist_ok=True)
    
    # Find all model results
    all_results = find_all_model_results(run_folder)
    
    if not all_results:
        return {
            "run_name": os.path.basename(run_folder),
            "total_models": 0,
            "successful_models": 0,
            "failed_models": 0,
            "csv_generated": 0,
        }
    
    # Filter and process results
    successful_models = []
    failed_models = []
    
    print(f"\n  📋 Model Summary:")
    print(f"  {'Model':<40} {'Attempts':<10} {'Failed':<8} {'Success':<10}")
    print(f"  {'-'*70}")
    
    for result in all_results:
        model_name = result["model_name"]
        failed_files = result["failed_files"]
        total_files = result["total_files"]
        num_attempts = result["num_json_files"]
        
        # Generate CSV to calculate success rate (we'll regenerate later, but this is for preview)
        try:
            temp_df = consolidate_results_with_attempts(result["json_files"])
            success_rate = calculate_success_rate(temp_df)
            success_str = f"{success_rate:.1f}%"
        except:
            success_str = "N/A"
        
        status_icon = "✓" if failed_files == 0 else "⚠"
        
        # Truncate model name for display
        display_name = model_name[:37] + "..." if len(model_name) > 40 else model_name
        
        print(f"  {status_icon} {display_name:<40} {num_attempts:<10} {failed_files:<8} {success_str:<10}")
        
        if failed_files == 0 or include_failed:
            successful_models.append(result)
        else:
            failed_models.append(result)
    
    # Generate CSV files for successful models
    csv_count = 0
    if successful_models:
        print(f"\n  📊 Generating CSV files with retry tracking for {len(successful_models)} model(s):")
        
        for result in successful_models:
            model_name = result["model_name"]
            
            try:
                csv_path = generate_csv_for_model(result, output_folder)
                
                # Load and analyze the generated CSV
                df = pd.read_csv(csv_path)
                success_rate = calculate_success_rate(df)
                mean_attempts = calculate_mean_attempts(df)
                
                print(f"    ✓ {model_name}")
                print(f"      Success Rate: {success_rate:.1f}%, Mean Attempts: {mean_attempts:.2f}")
                csv_count += 1
            except Exception as e:
                print(f"    ❌ {model_name}: {str(e)}")
    
    # Report failed models
    if failed_models and not include_failed:
        print(f"\n  ⚠ Skipped {len(failed_models)} model(s) with failed_files > 0:")
        for result in failed_models[:5]:
            print(f"    - {result['model_name']} (failed: {result['failed_files']})")
        if len(failed_models) > 5:
            print(f"    ... and {len(failed_models) - 5} more")
    
    return {
        "run_name": os.path.basename(run_folder),
        "total_models": len(all_results),
        "successful_models": len(successful_models),
        "failed_models": len(failed_models),
        "csv_generated": csv_count,
    }


def main():
    parser = argparse.ArgumentParser(
        description="Evaluate LLM-as-a-Judge benchmark results with retry tracking"
    )
    parser.add_argument(
        "--folder",
        type=str,
        default="results/llm-as-a-judge-benchmark/new",
        help="Base folder containing run folders or a specific run folder",
    )
    parser.add_argument(
        "--output",
        type=str,
        default=None,
        help="Output folder for CSV files (default: same as input folder)",
    )
    parser.add_argument(
        "--include-failed",
        action="store_true",
        help="Include models with failed_files > 0",
    )
    parser.add_argument(
        "--all-runs",
        action="store_true",
        help="Process all run folders (r1, r2, r3, etc.) under the base folder",
    )
    
    args = parser.parse_args()
    
    # Validate input folder
    if not os.path.isdir(args.folder):
        print(f"❌ Error: Folder '{args.folder}' does not exist")
        return 1
    
    print("=" * 80)
    print("LLM-as-a-Judge Benchmark CSV Generation with Retry Tracking")
    print("=" * 80)
    print("\n🎯 Features:")
    print("  - Tracks attempt_number for each evaluation")
    print("  - Tracks total_attempts per ticket")
    print("  - Supports reliability metrics")
    
    base_folder = Path(args.folder)
    
    # Auto-detect if this is a run folder or base folder
    is_run_folder = base_folder.name.startswith('r') and base_folder.name[1:].isdigit()
    
    if args.all_runs or (not is_run_folder and not args.output):
        # Process all run folders
        run_folders = sorted([
            d for d in base_folder.iterdir()
            if d.is_dir() and d.name.startswith('r') and d.name[1:].isdigit()
        ])
        
        if not run_folders:
            print(f"❌ No run folders (r1, r2, etc.) found in {args.folder}")
            return 1
        
        print(f"\n🔍 Found {len(run_folders)} run folder(s): {[f.name for f in run_folders]}\n")
        
        all_summaries = []
        
        for run_folder in run_folders:
            print(f"\n{'='*80}")
            print(f"Processing {run_folder.name}...")
            print(f"{'='*80}")
            
            summary = process_single_run(str(run_folder), args.include_failed)
            all_summaries.append(summary)
            
            print(f"\n  ✓ {run_folder.name}: {summary['csv_generated']}/{summary['total_models']} CSV files generated")
        
        # Print overall summary
        print(f"\n{'='*80}")
        print("OVERALL SUMMARY")
        print(f"{'='*80}")
        print(f"{'Run':<10} {'Total':<8} {'Success':<10} {'Failed':<8} {'CSV Gen':<10}")
        print("-" * 80)
        
        for summary in all_summaries:
            print(f"{summary['run_name']:<10} {summary['total_models']:<8} "
                  f"{summary['successful_models']:<10} {summary['failed_models']:<8} "
                  f"{summary['csv_generated']:<10}")
        
        print(f"{'='*80}")
        print(f"Total runs processed: {len(all_summaries)}")
        print(f"Total CSV files generated: {sum(s['csv_generated'] for s in all_summaries)}")
    
    else:
        # Process single folder
        output_folder = args.output if args.output else args.folder
        
        print(f"\n🔍 Scanning for model results in: {args.folder}")
        
        summary = process_single_run(args.folder, args.include_failed)
        
        print(f"\n{'='*80}")
        print(f"✓ CSV files saved to: {output_folder}")
        print(f"✓ Generated {summary['csv_generated']}/{summary['total_models']} CSV files")
        print(f"{'='*80}")
    
    print("\n✅ CSV generation complete! Files now include:")
    print("   - total_attempts: How many attempts were made until success")
    print("\n💡 Next: Use the CSV files for further analysis\n")
    
    return 0


if __name__ == "__main__":
    exit(main())
