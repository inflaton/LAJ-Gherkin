import os
import yaml
import json
from dotenv import load_dotenv

load_dotenv()

BASE_PATH = os.path.dirname(os.path.abspath(__file__))

# OpenAI settings
OPENAI_API_KEY = os.getenv("OPEN_AI_API_KEY", "")
OPENAI_MODEL = os.getenv("OPEN_AI_MODEL", "gpt-4")
OPENAI_MAX_TOKEN = int(os.getenv("OPEN_AI_MAX_TOKEN", 500))
OPENAI_TEMPERATURE = float(os.getenv("OPEN_AI_TEMPERATURE", 0.7))

# Input file paths
API_GUIDELINE_PATH = BASE_PATH + os.getenv("API_STANDARD_GUIDELINE_FILE_PATH", "")
JIRA_STORY_PATH = BASE_PATH + os.getenv("JIRA_STORY_PATH", "")
GHERKIN_BASE_PATH = BASE_PATH + os.getenv("GHERKIN_FILES_BASE_PATH", "")
COVERAGE_EXAMPLE_OUTPUT_FILE_PATH = BASE_PATH + os.getenv(
    "COVERAGE_REPORT_EXAMPLE_OUTPUT_FILE_PATH", ""
)

LLM_PROMPTS_FILE_PATH = BASE_PATH + os.getenv("LLM_PROMPTS", "")

# Output
COVERAGE_REPORT_BASE_PATH = BASE_PATH + os.getenv("COVERAGE_REPORT_BASE_PATH", "")

TOTAL_NUM_RUNS = int(os.getenv("TOTAL_NUM_RUNS", 1))

TOTAL_COVERAGE_REPORT_RUN = int(os.getenv("TOTAL_COVERAGE_REPORT_RUN", 1))


def load_json_file(path: str):
    try:
        with open(path, "r") as file:
            return json.load(file)
    except Exception as e:
        print(f"Error reading JSON file at {path}: {e}")
        return []


def load_text_file(path: str):
    try:
        with open(path, "r") as file:
            return file.read()
    except Exception as e:
        print(f"Error reading text file at {path}: {e}")
        return ""


def load_yaml_file(path: str):
    try:
        with open(path, "r") as file:
            return yaml.safe_load(file)
    except Exception as e:
        print(f"Error reading YAML file at {path}: {e}")
        return {}
