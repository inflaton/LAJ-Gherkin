#!/usr/bin/env python3
"""
Gherkin Folder Coverage Analysis Tool

This tool analyzes all Gherkin files in a specified folder and generates coverage reports
against corresponding JIRA stories. It can process entire directories of existing Gherkin
files to evaluate test coverage comprehensively.
"""

import os
import json
import glob
import argparse
import datetime
import logging
import asyncio
import copy
from typing import List, Dict, Optional

# Import from the existing coverage module
from coverage import (
    load_text_file,
    get_jira_story_by_id,
    analyze_coverage,
    is_valid_gherkin,
    benchmark_data,
    benchmark_config,
    test_config,
    llm_config,
    benchmark_results,
)
from coverage_config import (
    OPENAI_MODEL,
    OPENAI_TEMPERATURE,
    OPENAI_MAX_TOKEN,
    COVERAGE_REPORT_BASE_PATH,
)

logging.basicConfig(
    level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger(__name__)
if os.getenv("DEBUG"):
    logger.setLevel(logging.DEBUG)


def _safe_model_name(model_name: str) -> str:
    """Return a filesystem-friendly identifier for the model name."""
    return "".join(
        c if c.isalnum() or c in ("-", "_") else "_" for c in model_name or "default"
    )


def _get_cache_file_path(output_dir: str, model_name: str) -> str:
    """Construct the cache file path for a given model in the output directory."""
    safe_name = _safe_model_name(model_name)
    return os.path.join(output_dir, f".analysis_cache_{safe_name}.json")


def load_analysis_cache(output_dir: str, model_name: str) -> Dict[str, Dict]:
    """Load cached analysis metadata for the given model if available."""
    cache_path = _get_cache_file_path(output_dir, model_name)

    if not os.path.exists(cache_path):
        return {}

    try:
        with open(cache_path, "r") as cache_file:
            cache_data = json.load(cache_file)
            if isinstance(cache_data, dict):
                return cache_data
    except json.JSONDecodeError:
        logger.warning(f"Cache file is not valid JSON, ignoring cache: {cache_path}")
    except Exception as exc:
        logger.warning(f"Unable to load analysis cache {cache_path}: {exc}")

    return {}


def save_analysis_cache(
    output_dir: str, model_name: str, cache_data: Dict[str, Dict]
) -> None:
    """Persist the analysis cache for the given model."""
    cache_path = _get_cache_file_path(output_dir, model_name)

    try:
        with open(cache_path, "w") as cache_file:
            json.dump(cache_data, cache_file, indent=2)
        logger.info(f"Updated analysis cache: {cache_path}")
    except Exception as exc:
        logger.warning(f"Unable to write analysis cache {cache_path}: {exc}")


def bootstrap_cache_from_reports(
    gherkin_files: List[str], output_dir: str, model_name: str
) -> Dict[str, Dict]:
    """Reconstruct cache entries from existing benchmark reports when possible."""

    if not output_dir or not gherkin_files:
        return {}

    gherkin_by_name = {
        os.path.basename(path): path for path in gherkin_files if os.path.exists(path)
    }

    if not gherkin_by_name:
        return {}

    report_pattern = os.path.join(output_dir, "benchmark_result_*.json")
    reconstructed: Dict[str, Dict] = {}

    for report_path in glob.glob(report_pattern):
        try:
            with open(report_path, "r") as report_file:
                report_data = json.load(report_file)
        except Exception as exc:
            logger.debug(f"Skipping unreadable report {report_path}: {exc}")
            continue

        benchmark_cfg = report_data.get("benchmark_config", {})
        results_block = report_data.get("benchmark_results", {})
        test_cfg = report_data.get("test_config", {})

        if benchmark_cfg.get("benchmark_status") != "completed":
            continue

        llm_cfg = test_cfg.get("llm_config") or {}
        if llm_cfg.get("model") != model_name:
            continue

        benchmark_outputs = results_block.get("benchmark_output") or []
        if not benchmark_outputs:
            continue

        for coverage_entry in benchmark_outputs:
            gherkin_id = coverage_entry.get("gherkin_id")
            if not gherkin_id:
                continue

            file_path = gherkin_by_name.get(gherkin_id)
            # logger.debug(f"Mapping Gherkin ID {gherkin_id} to file path {file_path}")
            # logger.debug(f"output_dir: {output_dir}")
            if not file_path:
                continue

            try:
                file_mod_time = os.path.getmtime(file_path)
            except OSError:
                continue

            jira_id = str(benchmark_cfg.get("jira_id"))
            expected_jira_id = extract_jira_id_from_filename(file_path)
            if expected_jira_id and jira_id and jira_id != expected_jira_id:
                continue
            summary_result = {
                "file_path": file_path,
                "jira_id": jira_id,
                "jira_title": benchmark_cfg.get("jira_title", ""),
                "status": "completed",
                "coverage_percentage": coverage_entry.get(
                    "average_coverage_percentage",
                    results_block.get("average_coverage_percentage", 0),
                ),
                "analysis_time": test_cfg.get("benchmark_end_time"),
                "benchmark_report_path": report_path,
                "model_used": model_name,
                "coverage_details": coverage_entry.get("coverage_analysis", []),
            }

            reconstructed[file_path] = {
                "status": "completed",
                "jira_id": jira_id,
                "file_mod_time": file_mod_time,
                "result": summary_result,
            }

    if reconstructed:
        logger.info(
            f"Bootstrapped {len(reconstructed)} cached analyses from existing reports"
        )

    return reconstructed


def get_folder_configuration():
    """Get folder configuration from command line args and environment variables"""
    parser = argparse.ArgumentParser(
        description="Gherkin Folder Coverage Analysis Tool"
    )
    parser.add_argument(
        "--folder", "-f", type=str, help="Path to folder containing Gherkin files"
    )
    parser.add_argument(
        "--output",
        "-o",
        type=str,
        help="Output directory for coverage reports (overrides COVERAGE_REPORT_BASE_PATH env var)",
    )
    parser.add_argument(
        "--pattern",
        "-p",
        type=str,
        default="*.feature",
        help="File pattern to match Gherkin files (default: *.feature)",
    )
    parser.add_argument(
        "--recursive",
        "-r",
        action="store_true",
        help="Search for Gherkin files recursively in subdirectories",
    )
    parser.add_argument(
        "--jira-mapping",
        type=str,
        help="JSON file mapping Gherkin files to JIRA ticket IDs (optional)",
    )
    parser.add_argument(
        "--model",
        "-m",
        type=str,
        help="OpenAI model to use for analysis (overrides env config)",
    )
    parser.add_argument(
        "--temperature", type=float, help="Temperature setting for the model (0.0-2.0)"
    )
    parser.add_argument(
        "--max-tokens", type=int, help="Maximum tokens for model responses"
    )

    args = parser.parse_args()

    # Get folder path from command line args or environment variables
    folder_path = args.folder or os.getenv("GHERKIN_FILES_BASE_PATH")

    if not folder_path:
        logger.error(
            "No folder path specified via --folder or GHERKIN_FILES_BASE_PATH env var"
        )
        raise ValueError("Folder path is required")

    if not os.path.exists(folder_path):
        logger.error(f"Folder path does not exist: {folder_path}")
        raise ValueError(f"Folder path does not exist: {folder_path}")

    # Get output path from command line args or environment variables
    output_path = (
        args.output
        or os.getenv("COVERAGE_REPORT_BASE_PATH")
        or COVERAGE_REPORT_BASE_PATH
    )

    # Sanitize output path for gpt-oss model names
    output_path = output_path.replace(":", "-")

    # Create output directory if it doesn't exist
    try:
        os.makedirs(output_path, exist_ok=True)
        logger.info(f"Output directory confirmed/created: {output_path}")
    except PermissionError:
        logger.error(f"Permission denied creating output directory: {output_path}")
        raise ValueError(
            f"Cannot create output directory: {output_path} (permission denied)"
        )
    except OSError as e:
        logger.error(f"Error creating output directory {output_path}: {str(e)}")
        raise ValueError(f"Cannot create output directory: {output_path} ({str(e)})")

    return {
        "folder_path": folder_path,
        "output_path": output_path,
        "file_pattern": args.pattern,
        "recursive": args.recursive,
        "jira_mapping_file": args.jira_mapping,
        "model": args.model,
        "temperature": args.temperature,
        "max_tokens": args.max_tokens,
    }


def find_gherkin_files(
    folder_path: str, pattern: str = "*.feature", recursive: bool = False
) -> List[str]:
    """Find all Gherkin files in the specified folder"""
    if recursive:
        search_pattern = os.path.join(folder_path, "**", pattern)
        gherkin_files = glob.glob(search_pattern, recursive=True)
    else:
        search_pattern = os.path.join(folder_path, pattern)
        gherkin_files = glob.glob(search_pattern)

    logger.info(
        f"Found {len(gherkin_files)} Gherkin files matching pattern '{pattern}'"
    )
    # for file_path in gherkin_files:
    # logger.debug(f"Found Gherkin file: {file_path}")

    return gherkin_files


def extract_jira_id_from_filename(filename: str) -> Optional[str]:
    """Extract JIRA ticket ID from filename using common patterns"""
    import re

    # Remove path and extension
    base_name = os.path.splitext(os.path.basename(filename))[0]

    # Common patterns for JIRA IDs in filenames
    patterns = [
        r"jira[_-]?(\d+)",  # jira_8, jira-8, jira8
        r"ticket[_-]?(\d+)",  # ticket_8, ticket-8, ticket8
        r"story[_-]?(\d+)",  # story_8, story-8, story8
        r"(\d+)[_-]",  # 8_, 8-
        r"[_-](\d+)",  # _8, -8
        r"^(\d+)$",  # just the number
        r"(\d+)",  # any number in the filename
    ]

    for pattern in patterns:
        match = re.search(pattern, base_name, re.IGNORECASE)
        if match:
            return match.group(1)

    logger.warning(f"Could not extract JIRA ID from filename: {filename}")
    return None


def load_jira_mapping(mapping_file: str) -> Dict[str, str]:
    """Load JIRA mapping from JSON file"""
    try:
        with open(mapping_file, "r") as f:
            mapping = json.load(f)
        logger.info(f"Loaded JIRA mapping for {len(mapping)} files")
        return mapping
    except Exception as e:
        logger.error(f"Error loading JIRA mapping file {mapping_file}: {str(e)}")
        return {}


def get_jira_id_for_file(
    file_path: str, jira_mapping: Optional[Dict[str, str]] = None
) -> Optional[str]:
    """Get JIRA ticket ID for a Gherkin file"""
    relative_path = os.path.basename(file_path)

    # First check explicit mapping
    if jira_mapping and relative_path in jira_mapping:
        return jira_mapping[relative_path]

    # Try to extract from filename
    return extract_jira_id_from_filename(file_path)


def get_model_config(config: Dict) -> Dict:
    """Get model configuration with command line overrides"""
    return {
        "model": config.get("model") or OPENAI_MODEL,
        "temperature": config.get("temperature") or OPENAI_TEMPERATURE,
        "max_tokens": config.get("max_tokens") or OPENAI_MAX_TOKEN,
    }


def create_benchmark_report(
    jira_story: Dict,
    analysis_result,
    file_path: str,
    start_time: datetime.datetime,
    end_time: datetime.datetime,
    model_config: Dict,
) -> benchmark_data:
    """Create a benchmark report in the same format as the existing coverage tool"""

    # Create benchmark configuration
    benchmark_cfg = benchmark_config(
        benchmark_id=f"{jira_story['id']}_{datetime.datetime.now().isoformat()}",
        jira_id=str(jira_story["id"]),
        jira_title=jira_story["title"],
        benchmark_status=(
            "completed" if analysis_result.status == "completed" else "failed"
        ),
        total_run=1,
        total_passed=1 if analysis_result.status == "completed" else 0,
        total_failed=0 if analysis_result.status == "completed" else 1,
    )

    # Create test configuration
    test_cfg = test_config(
        benchmark_start_time=start_time.isoformat(),
        benchmark_end_time=end_time.isoformat(),
        framework="analyze_gherkin_folder",
        device=os.getenv("DEVICE", "Unknown"),
        llm_config=llm_config(
            model=model_config["model"],
            temperature=model_config["temperature"],
            max_tokens=model_config["max_tokens"],
        ),
    )

    # Create benchmark results
    results = benchmark_results(
        average_coverage_percentage=analysis_result.average_coverage_percentage,
        average_generation_time_seconds=(end_time - start_time).total_seconds(),
        benchmark_output=[analysis_result],
    )

    return benchmark_data(
        benchmark_config=benchmark_cfg, test_config=test_cfg, benchmark_results=results
    )


def save_benchmark_report(
    benchmark_obj: benchmark_data, output_path: Optional[str] = None
) -> str:
    """Save benchmark report in the standard format"""
    output_dir = output_path or COVERAGE_REPORT_BASE_PATH
    # Directory should already exist from configuration setup

    timestamp = datetime.datetime.now().strftime("%Y%m%d_%H%M%S%f")
    filename = (
        f"benchmark_result_{benchmark_obj.benchmark_config.jira_id}_{timestamp}.json"
    )
    filepath = os.path.join(output_dir, filename)

    try:
        with open(filepath, "w") as f:
            json.dump(benchmark_obj.to_dict(), f, indent=2)
        logger.info(f"Benchmark report saved to {filepath}")
        return filepath
    except PermissionError:
        logger.error(f"Permission denied writing to {filepath}")
        raise
    except OSError as e:
        logger.error(f"Error writing benchmark report to {filepath}: {str(e)}")
        raise


async def analyze_gherkin_file(
    file_path: str, jira_id: str, model_config: Dict, output_path: Optional[str] = None
) -> Optional[Dict]:
    """Analyze a single Gherkin file for coverage and generate benchmark report"""
    logger.info(f"Analyzing Gherkin file: {file_path} for JIRA ticket: {jira_id}")
    logger.info(
        f"Using model: {model_config['model']} (temp: {model_config['temperature']}, max_tokens: {model_config['max_tokens']})"
    )

    start_time = datetime.datetime.now()

    try:
        # Load and validate Gherkin content
        gherkin_content = load_text_file(file_path)

        if not is_valid_gherkin(gherkin_content):
            logger.warning(f"Invalid Gherkin format in file: {file_path}")
            return {
                "file_path": file_path,
                "jira_id": jira_id,
                "status": "failed",
                "error": "Invalid Gherkin format",
            }

        # Get JIRA story
        jira_story = get_jira_story_by_id(jira_id)
        if not jira_story:
            logger.warning(f"JIRA story not found for ID: {jira_id}")
            return {
                "file_path": file_path,
                "jira_id": jira_id,
                "status": "failed",
                "error": f"JIRA story not found for ID: {jira_id}",
            }

        # Analyze coverage
        filename = os.path.basename(file_path)
        analysis_result = analyze_coverage(
            jira_story,
            filename,
            model_config=model_config,
            gherkin_base_path=os.path.dirname(file_path),
        )

        end_time = datetime.datetime.now()

        # Create and save benchmark report
        benchmark_obj = create_benchmark_report(
            jira_story, analysis_result, file_path, start_time, end_time, model_config
        )
        report_path = save_benchmark_report(benchmark_obj, output_path)

        # Create summary result for folder analysis
        result = {
            "file_path": file_path,
            "jira_id": jira_id,
            "jira_title": jira_story.get("title", ""),
            "status": analysis_result.status,
            "coverage_percentage": analysis_result.average_coverage_percentage,
            "analysis_time": end_time.isoformat(),
            "benchmark_report_path": report_path,
            "model_used": model_config["model"],
            "coverage_details": [],
        }

        # Add detailed coverage analysis
        if analysis_result.coverage_analysis:
            for coverage in analysis_result.coverage_analysis:
                result["coverage_details"].append(
                    {
                        "coverage_percentage": coverage.coverage_percentage,
                        "covered_items": coverage.covered,
                        "gaps": coverage.gaps,
                        "recommendations": coverage.recommendations,
                        "usage": coverage.usage,
                    }
                )

        return result

    except Exception as e:
        logger.error(f"Error analyzing file {file_path}: {str(e)}")
        return {
            "file_path": file_path,
            "jira_id": jira_id,
            "status": "failed",
            "error": str(e),
        }


async def analyze_folder(config: Dict) -> Dict:
    """Analyze all Gherkin files in the specified folder"""
    folder_path = config["folder_path"]
    output_path = config["output_path"]
    file_pattern = config["file_pattern"]
    recursive = config["recursive"]
    jira_mapping_file = config["jira_mapping_file"]

    # Get model configuration
    model_config = get_model_config(config)

    logger.info(f"Starting folder analysis for: {folder_path}")
    logger.info(f"Output directory: {output_path}")
    logger.info(f"Model configuration: {model_config}")

    # Load JIRA mapping if provided
    jira_mapping = {}
    if jira_mapping_file:
        jira_mapping = load_jira_mapping(jira_mapping_file)

    # Find all Gherkin files
    gherkin_files = find_gherkin_files(folder_path, file_pattern, recursive)
    # logger.debug("gherkin_files:", gherkin_files)

    if not gherkin_files:
        logger.warning(f"No Gherkin files found in {folder_path}")
        return {
            "status": "completed",
            "total_files": 0,
            "analyzed_files": 0,
            "results": [],
        }

    # Build cache directly from existing benchmark reports (ignore .analysis_cache files)
    # This is simpler and more reliable - we just check all benchmark_result_*.json files
    cache = bootstrap_cache_from_reports(
        gherkin_files, output_path, model_config["model"]
    )

    if cache:
        logger.info(
            f"Loaded {len(cache)} completed analyses from existing reports"
        )

    cache_hits = 0

    # Analyze each file
    results = []
    analyzed_count = 0

    for file_path in gherkin_files:
        # logger.debug(f"file_path: {file_path}")
        try:
            file_mod_time = os.path.getmtime(file_path)
        except OSError as exc:
            logger.warning(
                f"Unable to read modified time for {file_path}; will re-analyze. Error: {exc}"
            )
            file_mod_time = None

        # Get JIRA ID for this file
        jira_id = get_jira_id_for_file(file_path, jira_mapping)

        if not jira_id:
            logger.warning(f"Could not determine JIRA ID for file: {file_path}")
            results.append(
                {
                    "file_path": file_path,
                    "jira_id": None,
                    "status": "skipped",
                    "error": "Could not determine JIRA ID",
                }
            )
            continue

        cache_entry = cache.get(file_path)

        # Check if we already have a completed analysis from benchmark reports
        # We trust the benchmark reports since they're the source of truth
        can_use_cache = (
            cache_entry
            and cache_entry.get("status") == "completed"
            and cache_entry.get("jira_id") == jira_id
        )

        if can_use_cache:
            logger.info(f"Skipping already analyzed file (cache hit): {file_path}")
            cached_result = copy.deepcopy(cache_entry.get("result", {}))
            if not cached_result:
                cached_result = {
                    "file_path": file_path,
                    "jira_id": jira_id,
                    "status": "cached",
                }
            cached_result["status"] = "cached"
            cached_result["cache_hit"] = True
            cached_result.setdefault("file_path", file_path)
            cached_result.setdefault("jira_id", jira_id)
            cached_result.setdefault("model_used", model_config["model"])
            results.append(cached_result)
            analyzed_count += 1
            cache_hits += 1
            continue

        # Analyze the file
        result = await analyze_gherkin_file(
            file_path, jira_id, model_config, output_path
        )

        if result:
            results.append(result)
            if result["status"] != "failed":
                analyzed_count += 1

        if os.getenv("DEBUG"):
            logger.debug(f"Analysis result for {file_path}: {result}")
            # break

    # Generate summary report
    summary = {
        "analysis_timestamp": datetime.datetime.now().isoformat(),
        "folder_path": folder_path,
        "file_pattern": file_pattern,
        "recursive_search": recursive,
        "total_files": len(gherkin_files),
        "analyzed_files": analyzed_count,
        "failed_files": len([r for r in results if r["status"] == "failed"]),
        "skipped_files": len([r for r in results if r["status"] == "skipped"]),
        "cache_hits": cache_hits,
        "average_coverage": 0,
        "model_config": {
            "model": model_config["model"],
            "temperature": model_config["temperature"],
            "max_tokens": model_config["max_tokens"],
            "framework": "analyze_gherkin_folder",
            "device": os.getenv("DEVICE", "Unknown"),
        },
        "results": results,
    }

    # Calculate average coverage
    successful_results = [
        r
        for r in results
        if r["status"] in {"completed", "cached"} and "coverage_percentage" in r
    ]
    if successful_results:
        total_coverage = sum(r["coverage_percentage"] for r in successful_results)
        summary["average_coverage"] = total_coverage / len(successful_results)

    # Save summary report only if there were new analyses (not all cache hits)
    new_analyses = analyzed_count - cache_hits
    if new_analyses > 0:
        output_dir = output_path or COVERAGE_REPORT_BASE_PATH
        # Directory should already exist from configuration setup
        timestamp = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
        summary_file = os.path.join(output_dir, f"folder_coverage_summary_{timestamp}.json")

        try:
            with open(summary_file, "w") as f:
                json.dump(summary, f, indent=2)
            logger.info(f"Saved summary report to: {summary_file}")
        except PermissionError:
            logger.error(f"Permission denied writing summary to {summary_file}")
            raise
        except OSError as e:
            logger.error(f"Error writing summary report to {summary_file}: {str(e)}")
            raise
    else:
        logger.info(f"All {cache_hits} files were cache hits - skipping summary file creation")

    # Note: We no longer maintain .analysis_cache files
    # Instead, we always rebuild from benchmark_result_*.json files which is more reliable

    return summary


async def main():
    """Main entry point for the Gherkin folder analysis"""
    try:
        logger.info("Starting Gherkin folder coverage analysis")

        # Get configuration
        config = get_folder_configuration()

        logger.info(f"Configuration: {config}")

        # Analyze the folder
        summary = await analyze_folder(config)

        # Print summary
        logger.info("=== Analysis Summary ===")
        logger.info(f"Total files: {summary['total_files']}")
        logger.info(f"Analyzed files: {summary['analyzed_files']}")
        logger.info(f"Failed files: {summary['failed_files']}")
        logger.info(f"Skipped files: {summary['skipped_files']}")
        logger.info(f"Cache hits: {summary['cache_hits']}")
        logger.info(f"Average coverage: {summary['average_coverage']:.2f}%")

        if summary["analyzed_files"] > 0:
            logger.info("Coverage analysis completed successfully")
        else:
            logger.warning("No files were successfully analyzed")

    except Exception as e:
        logger.error(f"Error during folder analysis: {str(e)}")
        raise


if __name__ == "__main__":
    asyncio.run(main())
