import os
import json
import openai
import datetime
import ast
import asyncio
import logging
import argparse
import glob
from dataclasses import dataclass, asdict
from typing import List, Optional

logging.basicConfig(
    level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger(__name__)
if os.getenv("DEBUG"):
    logger.setLevel(logging.DEBUG)

from coverage_config import load_json_file, load_text_file, load_yaml_file
from coverage_config import COVERAGE_REPORT_BASE_PATH
from coverage_config import (
    TOTAL_NUM_RUNS,
    OPENAI_API_KEY,
    OPENAI_MODEL,
    OPENAI_MAX_TOKEN,
    OPENAI_TEMPERATURE,
)
from coverage_config import (
    TOTAL_COVERAGE_REPORT_RUN,
    LLM_PROMPTS_FILE_PATH,
    API_GUIDELINE_PATH,
    JIRA_STORY_PATH,
    GHERKIN_BASE_PATH,
    COVERAGE_EXAMPLE_OUTPUT_FILE_PATH,
)


@dataclass
class coverage_analysis:
    coverage_percentage: int
    covered: List[str]
    gaps: List[str]
    recommendations: List[str]
    usage: Optional[dict] = None


@dataclass
class benchmark_output:
    average_coverage_percentage: int
    generation_time_seconds: float
    generated_output_count: int
    status: str
    gherkin_id: Optional[str] = None
    coverage_analysis: Optional[List["coverage_analysis"]] = None


@dataclass
class llm_config:
    model: str
    temperature: float
    max_tokens: int
    seed: int = -1


@dataclass
class test_config:
    benchmark_start_time: str
    benchmark_end_time: str
    framework: str
    device: str
    llm_config: llm_config


@dataclass
class benchmark_config:
    benchmark_id: str
    jira_id: str
    jira_title: str
    benchmark_status: str
    total_run: int
    total_passed: int
    total_failed: int


@dataclass
class benchmark_results:
    average_coverage_percentage: int
    average_generation_time_seconds: float
    benchmark_output: List[benchmark_output]


@dataclass
class benchmark_data:
    benchmark_config: benchmark_config
    test_config: test_config
    benchmark_results: benchmark_results

    def to_dict(self):
        return asdict(self)


api_guidelines = load_text_file(API_GUIDELINE_PATH)
jira_stories = load_json_file(JIRA_STORY_PATH)
llm_prompts = load_yaml_file(LLM_PROMPTS_FILE_PATH)
coverage_example_output = load_json_file(COVERAGE_EXAMPLE_OUTPUT_FILE_PATH)


def is_valid_gherkin(gherkin_content):
    """
    Validate if the content follows Gherkin syntax.
    """
    required_keywords = ["Feature:", "Scenario:"]
    if not any(keyword in gherkin_content for keyword in required_keywords):
        return False

    gherkin_steps = ["Given", "When", "Then", "And", "But"]
    if not any(f" {step} " in gherkin_content for step in gherkin_steps):
        return False

    if "Feature:" in gherkin_content and "Scenario:" not in gherkin_content:
        return False

    return True


def get_jira_story_by_id(jira_id):
    """Retrieve a JIRA story by its ID from the loaded stories"""
    return next(
        (story for story in jira_stories if str(story.get("id")) == str(jira_id)), None
    )


def has_existing_gherkin_files(ticket_id):
    """Check if Gherkin files already exist for the given ticket ID"""
    pattern = os.path.join(GHERKIN_BASE_PATH, f"*{ticket_id}*.feature")
    existing_files = glob.glob(pattern)

    if existing_files:
        logger.info(
            f"Found existing Gherkin files for ticket {ticket_id}: {existing_files}"
        )
        return True

    logger.debug(f"No existing Gherkin files found for ticket {ticket_id}")
    return False


def parse_ticket_ids(ticket_input):
    """Parse ticket IDs from various input formats"""
    if not ticket_input:
        return []

    ticket_ids = []

    # Split by comma and process each part
    parts = [part.strip() for part in ticket_input.split(",")]

    for part in parts:
        if "-" in part and len(part.split("-")) == 2:
            # Handle range format like "1-5"
            try:
                start, end = map(int, part.split("-"))
                ticket_ids.extend(list(range(start, end + 1)))
            except ValueError:
                logger.warning(f"Invalid range format: {part}")
        else:
            # Handle single ticket ID
            try:
                ticket_ids.append(int(part))
            except ValueError:
                logger.warning(f"Invalid ticket ID: {part}")

    return ticket_ids


def save_benchmark_output(jira_id, benchmark_data_object):
    """Save benchmark data to a JSON file"""
    timestamp = datetime.datetime.now().strftime("%Y%m%d_%H%M%S%f")
    filename = f"/benchmark_result_{jira_id}_{timestamp}.json"
    filepath = COVERAGE_REPORT_BASE_PATH + filename
    os.makedirs(os.path.dirname(filepath), exist_ok=True)

    with open(filepath, "w") as f:
        json.dump(benchmark_data_object.to_dict(), f, indent=2)

    logger.info(f"Benchmark data saved to {filepath}")


def generate_user_prompt(jira_story, gherkin_tests):
    """Generate the prompt for the LLM to analyze coverage"""
    return llm_prompts["prompts"]["user_message"].format(
        jira_id=jira_story["id"],
        jira_title=jira_story["title"],
        jira_description={", ".join(jira_story["description"])},
        gherkin_tests=gherkin_tests,
        guidelines=api_guidelines,
        example_output=coverage_example_output,
    )


def create_openai_client():
    if os.getenv("DISABLE_SSL_VERIFY"):
        # Disable SSL warnings
        import urllib3
        import httpx

        urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

        # Create HTTP client with SSL verification disabled
        http_client = httpx.Client(verify=False)
    else:
        http_client = None

    # Initialize OpenAI client
    client = openai.OpenAI(
        api_key=OPENAI_API_KEY,
        base_url=os.getenv("OPENAI_BASE_URL") or None,
        http_client=http_client,
    )

    return client


def get_coverage_analysis(prompt, model_config={}):
    """Send the prompt to the LLM and get the coverage analysis response"""
    client = create_openai_client()

    model = model_config.get("model", OPENAI_MODEL)
    temperature = model_config.get("temperature", OPENAI_TEMPERATURE)
    max_tokens = model_config.get("max_tokens", OPENAI_MAX_TOKEN)
    messages = [
        {"role": "system", "content": llm_prompts["prompts"]["system_message"]},
        {"role": "user", "content": prompt},
    ]

    reasoning_effort = os.getenv("REASONING_EFFORT")

    response = (
        (
            client.chat.completions.create(
                model=model,
                messages=messages,
                temperature=1,
                max_completion_tokens=max_tokens,
                reasoning_effort=reasoning_effort,
            )
            if "gpt-5" in model
            else client.chat.completions.create(
                model=model,
                messages=messages,
                temperature=temperature,
                max_tokens=max_tokens,
                reasoning_effort=reasoning_effort,
            )
        )
        if reasoning_effort
        else (
            client.chat.completions.create(
                model=model,
                messages=messages,
                temperature=temperature,
                max_tokens=max_tokens,
            )
        )
    )

    return response.choices[0].message.content.strip(), response.usage


def parse_analysis_json(analysis_json):
    """Extract coverage data from the analysis JSON"""
    coverage_percentage = analysis_json.get("coverage_percentage", 0)
    covered_items = analysis_json.get("covered", [])
    gaps_items = analysis_json.get("gaps", [])
    recommendations_items = analysis_json.get("recommendations", [])

    # Handle nested coverage_analysis format
    if isinstance(analysis_json, dict) and "coverage_analysis" in analysis_json:
        coverage_data = analysis_json["coverage_analysis"]
        if isinstance(coverage_data, dict):
            coverage_percentage = coverage_data.get(
                "coverage_percentage", coverage_percentage
            )
            covered_items = coverage_data.get("covered", covered_items)
            gaps_items = coverage_data.get("gaps", gaps_items)
            recommendations_items = coverage_data.get(
                "recommendations", recommendations_items
            )

    return {
        "coverage_percentage": coverage_percentage,
        "covered": covered_items,
        "gaps": gaps_items,
        "recommendations": recommendations_items,
    }


def analyze_coverage(
    jira_story, gherkin_output, model_config={}, gherkin_base_path=GHERKIN_BASE_PATH
):
    """Analyze the coverage of Gherkin tests against a JIRA story"""
    logger.info(
        f"Analyzing coverage for JIRA {jira_story['id']} with Gherkin output: {gherkin_output}"
    )

    try:
        gherkin_tests = load_text_file(os.path.join(gherkin_base_path, gherkin_output))
        logger.debug(f"Loaded Gherkin tests: {gherkin_tests[:100]}...")

        user_prompt = generate_user_prompt(jira_story, gherkin_tests)
        analysis, usage = get_coverage_analysis(user_prompt, model_config=model_config)
        logger.debug(f"analysis: {analysis}")
        logger.debug(f"usage: {usage}")

        try:
            try:
                analysis_json = ast.literal_eval(analysis)
            except (ValueError, SyntaxError):
                # hack for gpt-oss sometimes returning JSON with <think> tags
                analysis = analysis.replace("<think>", "").replace("</think>", "")

                # hack for gpt-4o-mini sometimes returning invalid JSON
                analysis = analysis.replace("\n", "")

                analysis = analysis.strip()
                if analysis.startswith("{") and not analysis.endswith("}}"):
                    analysis = analysis + "}"

                analysis_json = ast.literal_eval(analysis)

            logger.debug(f"Successfully parsed analysis JSON")

            # Extract coverage data
            coverage_data = parse_analysis_json(analysis_json)

            # Create coverage analysis object
            coverage = coverage_analysis(
                coverage_percentage=coverage_data["coverage_percentage"],
                covered=coverage_data["covered"],
                gaps=coverage_data["gaps"],
                recommendations=coverage_data["recommendations"],
                usage=usage.to_dict() if usage else None,
            )

            # Create benchmark output
            benchmark = benchmark_output(
                gherkin_id=gherkin_output,
                average_coverage_percentage=coverage_data["coverage_percentage"],
                generation_time_seconds=0.0,
                generated_output_count=1,
                coverage_analysis=[coverage],
                status="completed",
            )
            return benchmark

        except (ValueError, SyntaxError, KeyError) as e:
            logger.error(f"Error parsing analysis output: {str(e)}")
            logger.debug(f"Raw analysis: {analysis[:200]}...")

            coverage = coverage_analysis(
                coverage_percentage=0,
                covered=[],
                gaps=["Failed to parse coverage analysis"],
                recommendations=["Retry analysis with different parameters"],
            )

            benchmark = benchmark_output(
                gherkin_id=gherkin_output,
                average_coverage_percentage=0,
                generation_time_seconds=0.0,
                generated_output_count=0,
                coverage_analysis=[coverage],
                status="failed",
            )
            return benchmark

    except Exception as e:
        logger.error(f"Unexpected error in coverage analysis: {str(e)}")

        usage_data = usage.to_dict() if "usage" in locals() and usage else None

        coverage = coverage_analysis(
            coverage_percentage=0,
            covered=[],
            gaps=[f"Error analyzing coverage: {str(e)}"],
            recommendations=["Check system configuration and try again"],
            usage=usage_data,
        )

        return benchmark_output(
            gherkin_id=gherkin_output,
            average_coverage_percentage=0,
            generation_time_seconds=0.0,
            generated_output_count=0,
            coverage_analysis=[coverage],
            status="failed",
        )


def create_benchmark_object(jira_story, agent_config):
    """Create and initialize a benchmark data object"""
    return benchmark_data(
        benchmark_config=benchmark_config(
            benchmark_id=f"{jira_story['id']}_{datetime.datetime.now().isoformat()}",
            jira_id=jira_story["id"],
            jira_title=jira_story["title"],
            benchmark_status="in_progress",
            total_run=0,
            total_passed=0,
            total_failed=0,
        ),
        test_config=test_config(
            benchmark_start_time=str(datetime.datetime.now().isoformat()),
            benchmark_end_time="",
            framework=agent_config["agent_framework"],
            device=agent_config["device"],
            llm_config=llm_config(
                model=OPENAI_MODEL,
                temperature=OPENAI_TEMPERATURE,
                max_tokens=OPENAI_MAX_TOKEN,
            ),
        ),
        benchmark_results=benchmark_results(
            average_coverage_percentage=0,
            average_generation_time_seconds=0,
            benchmark_output=[],
        ),
    )


def update_benchmark_metrics(benchmark_obj, result, time_taken_seconds, output_count):
    """Update benchmark metrics based on analysis results"""
    # Update timing info
    benchmark_obj.benchmark_results.average_generation_time_seconds = time_taken_seconds
    result.generation_time_seconds = time_taken_seconds
    result.generated_output_count = output_count

    # Add result to benchmark outputs
    benchmark_obj.benchmark_results.benchmark_output.append(result)

    # Calculate averages
    total_coverage_percentage = 0

    try:
        coverage_percentage = int(result.average_coverage_percentage)
        total_coverage_percentage += coverage_percentage
    except (ValueError, TypeError):
        logger.warning(
            f"Could not convert coverage percentage '{result.average_coverage_percentage}' to int"
        )
        total_coverage_percentage += 0

    # Update average metrics
    if benchmark_obj.benchmark_results.benchmark_output:
        output_count = len(benchmark_obj.benchmark_results.benchmark_output)
        benchmark_obj.benchmark_results.average_coverage_percentage = (
            total_coverage_percentage // output_count
        )

    # Update run counters
    benchmark_obj.benchmark_config.total_run += 1

    has_output = benchmark_obj.benchmark_results.benchmark_output
    is_successful = (
        has_output
        and benchmark_obj.benchmark_results.benchmark_output[0].status == "completed"
    )

    benchmark_obj.benchmark_config.total_passed += 1 if is_successful else 0
    benchmark_obj.benchmark_config.total_failed += (
        1 if has_output and not is_successful else 0
    )


async def process_jira_ticket(ticket_id, agent_config, skip_existing=True):
    """Process a single JIRA ticket through the benchmark pipeline"""
    logger.info(f"Processing JIRA ticket ID: {ticket_id} with {TOTAL_NUM_RUNS} runs")

    # Check if Gherkin files already exist and skip if requested
    if skip_existing and has_existing_gherkin_files(ticket_id):
        logger.info(f"Skipping ticket {ticket_id} - existing Gherkin files found")
        return

    jira_story = get_jira_story_by_id(ticket_id)
    if not jira_story:
        logger.error(f"JIRA story with ID {ticket_id} not found")
        return

    logger.info(f"Found JIRA story: {jira_story['id']} - {jira_story['title']}")

    benchmark_obj = create_benchmark_object(jira_story, agent_config)

    total_time_seconds = 0
    total_outputs = 0
    all_benchmark_outputs = []

    for run_idx in range(TOTAL_NUM_RUNS):
        logger.info(f"Starting generation run {run_idx + 1}/{TOTAL_NUM_RUNS}")

        # Start timing
        start_time = datetime.datetime.now()
        logger.info(f"Starting generation at {start_time.isoformat()}")

        # Generate Gherkin tests
        try:
            gherkin_outputs = await start_swarm_simple(
                agent_config["qe_coder_agent"],
                agent_config["qe_coder_agent"],
                str(ticket_id),
            )

            # Stop timing
            end_time = datetime.datetime.now()
            time_taken = end_time - start_time
            time_taken_seconds = time_taken.total_seconds()
            logger.info(
                f"Generation run {run_idx + 1} completed in {time_taken_seconds:.2f} seconds"
            )

            total_time_seconds += time_taken_seconds

            # Process gherkin outputs
            if gherkin_outputs:
                total_outputs += len(gherkin_outputs)

                # Use the last output
                last_sequence = max(gherkin_outputs.keys())
                last_output = gherkin_outputs[last_sequence]

                logger.info(f"Processing output #{last_sequence}: {last_output}")
                gherkin_path = os.path.join(GHERKIN_BASE_PATH, last_output)
                gherkin_content = load_text_file(gherkin_path)

                if not is_valid_gherkin(gherkin_content):
                    logger.warning(
                        f"Run {run_idx + 1}: Invalid Gherkin format in output {last_output}"
                    )
                    failed_output = benchmark_output(
                        gherkin_id=last_output,
                        average_coverage_percentage=0,
                        generation_time_seconds=time_taken_seconds,
                        generated_output_count=len(gherkin_outputs),
                        coverage_analysis=[
                            coverage_analysis(
                                coverage_percentage=0,
                                covered=[],
                                gaps=["Invalid Gherkin format detected"],
                                recommendations=[
                                    "Regenerate tests with proper Gherkin syntax"
                                ],
                            )
                        ],
                        status="failed",
                    )
                    all_benchmark_outputs.append(failed_output)
                    benchmark_obj.benchmark_config.total_failed += 1
                    continue  # Skip to the next run

                all_coverage_analyses = []
                # Run analysis 3 times for this output
                for analysis_idx in range(TOTAL_COVERAGE_REPORT_RUN):
                    logger.info(
                        f"Running coverage analysis {analysis_idx + 1}/3 for output {last_sequence}"
                    )

                    analysis_result = analyze_coverage(jira_story, last_output)

                    # Store all coverage analyses for this run
                    if analysis_result.coverage_analysis:
                        all_coverage_analyses.extend(analysis_result.coverage_analysis)

                # Calculate average coverage percentage across analyses
                total_coverage = sum(
                    int(ca.coverage_percentage) for ca in all_coverage_analyses
                )
                avg_coverage = (
                    total_coverage // len(all_coverage_analyses)
                    if all_coverage_analyses
                    else 0
                )

                # Create a benchmark output for this run - including all 3 coverage analyses
                run_benchmark_output = benchmark_output(
                    gherkin_id=last_output,
                    average_coverage_percentage=avg_coverage,
                    generation_time_seconds=time_taken_seconds,
                    generated_output_count=len(gherkin_outputs),
                    coverage_analysis=all_coverage_analyses,
                    status="completed",
                )

                # Add to list of all benchmark outputs
                all_benchmark_outputs.append(run_benchmark_output)
            else:
                logger.warning(f"Run {run_idx + 1}: No Gherkin outputs were generated")

        except Exception as e:
            logger.error(f"Error during processing run {run_idx + 1}: {str(e)}")

            # Create a failed benchmark output for this run
            failed_output = benchmark_output(
                gherkin_id="",
                average_coverage_percentage=0,
                generation_time_seconds=0,
                generated_output_count=0,
                coverage_analysis=[],
                status="failed",
            )
            all_benchmark_outputs.append(failed_output)
            benchmark_obj.benchmark_config.total_failed += 1

    # Set all benchmark outputs in the result object
    benchmark_obj.benchmark_results.benchmark_output = all_benchmark_outputs

    # Calculate and update overall averages
    if all_benchmark_outputs:
        avg_coverage = sum(
            output.average_coverage_percentage for output in all_benchmark_outputs
        ) // len(all_benchmark_outputs)
        avg_generation_time = sum(
            output.generation_time_seconds for output in all_benchmark_outputs
        ) / len(all_benchmark_outputs)

        benchmark_obj.benchmark_results.average_coverage_percentage = avg_coverage
        benchmark_obj.benchmark_results.average_generation_time_seconds = (
            avg_generation_time
        )

    # Finalize benchmark
    benchmark_obj.test_config.benchmark_end_time = str(
        datetime.datetime.now().isoformat()
    )
    benchmark_obj.benchmark_config.benchmark_status = "completed"
    benchmark_obj.benchmark_config.total_run = TOTAL_NUM_RUNS

    # Count successful runs
    successful_runs = sum(
        1 for output in all_benchmark_outputs if output.status == "completed"
    )
    benchmark_obj.benchmark_config.total_passed = successful_runs
    benchmark_obj.benchmark_config.total_failed = TOTAL_NUM_RUNS - successful_runs

    # Save results
    save_benchmark_output(jira_id=jira_story["id"], benchmark_data_object=benchmark_obj)
    logger.info(
        f"Benchmark completed for JIRA ticket {ticket_id} with {TOTAL_NUM_RUNS} runs"
    )


def get_ticket_configuration():
    """Get JIRA ticket configuration from command line args and environment variables"""
    parser = argparse.ArgumentParser(description="JIRA Coverage Analysis Tool")
    parser.add_argument(
        "--tickets",
        "-t",
        type=str,
        help="JIRA ticket IDs (comma-separated list or ranges like '1-5,8,10-15')",
    )
    parser.add_argument(
        "--skip-existing",
        action="store_true",
        default=True,
        help="Skip tickets that already have Gherkin files (default: True)",
    )
    parser.add_argument(
        "--no-skip-existing",
        action="store_false",
        dest="skip_existing",
        help="Process all tickets even if Gherkin files exist",
    )

    args = parser.parse_args()

    # Get ticket IDs from command line args or environment variables
    ticket_input = args.tickets or os.getenv("JIRA_TICKETS")

    if ticket_input:
        ticket_ids = parse_ticket_ids(ticket_input)
    else:
        # Default fallback
        logger.warning(
            "No JIRA tickets specified via --tickets or JIRA_TICKETS env var, using default [8]"
        )
        ticket_ids = [8]

    return {"ticket_ids": ticket_ids, "skip_existing": args.skip_existing}


async def main():
    """Main entry point for the coverage analysis process"""
    logger.info("Starting coverage analysis")

    # Get ticket configuration
    config = get_ticket_configuration()
    ticket_ids = config["ticket_ids"]
    skip_existing = config["skip_existing"]

    logger.info(f"Configured to process tickets: {ticket_ids}")
    logger.info(f"Skip existing Gherkin files: {skip_existing}")

    # Get agent configuration
    agent_config = {
        "qe_coder_agent": os.getenv("QE_CODER_AGENT"),
        "agent_framework": os.getenv("QE_FRAMEWORK"),
        "device": os.getenv("DEVICE", ""),
    }

    logger.info(f"Agent configuration: {agent_config}")

    # Process all configured tickets
    for ticket_id in ticket_ids:
        logger.info(f"Processing JIRA ticket: {ticket_id}")
        await process_jira_ticket(ticket_id, agent_config, skip_existing)

    logger.info("Coverage analysis completed")


if __name__ == "__main__":
    asyncio.run(main())
