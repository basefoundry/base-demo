#!/usr/bin/env python3
"""Executable conformance coverage for the checked-in Project Intake workflow."""

from __future__ import annotations

import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


REPO_ROOT = Path(__file__).resolve().parents[1]
WORKFLOW = REPO_ROOT / ".github" / "workflows" / "project-intake.yml"
BASE_TEMPLATE_COMMIT = "39d57ed3ace710621d9dd26af74c5f83b98fc3ae"
BASE_TEMPLATE_SHA256 = "3289a01a0533415f1f9e153051461f12c7d33f8f2cdfe6d7865baa77f1046d25"


def project_intake_run_command() -> str:
    """Extract the workflow step without depending on a YAML parser."""
    lines = WORKFLOW.read_text(encoding="utf-8").splitlines()
    step_marker = "      - name: Reconcile Project item"
    try:
        step_index = lines.index(step_marker)
        run_index = lines.index("        run: |", step_index)
    except ValueError as error:
        raise AssertionError("Project Intake reconcile step was not found") from error

    command_lines: list[str] = []
    for line in lines[run_index + 1 :]:
        if line and not line.startswith("          "):
            break
        command_lines.append(line[10:] if line else "")
    if not command_lines:
        raise AssertionError("Project Intake reconcile step is empty")
    return "\n".join(command_lines) + "\n"


def write_mocks(state: Path) -> Path:
    mockbin = state / "bin"
    mockbin.mkdir()

    gh_mock = mockbin / "gh"
    gh_mock.write_text(
        r'''#!/usr/bin/env bash
set -u

printf '%s\n' "$*" >> "${PROJECT_INTAKE_STATE:?}/gh.log"

mock_value() {
  local field="$1"
  local state_file="${PROJECT_INTAKE_STATE:?}/${field}"
  if [[ -f "$state_file" ]]; then
    cat "$state_file"
    return 0
  fi
  case "$field" in
    status) printf '%s\n' "${PROJECT_INTAKE_EXISTING_STATUS:-}" ;;
    priority) printf '%s\n' "${PROJECT_INTAKE_EXISTING_PRIORITY:-}" ;;
    size) printf '%s\n' "${PROJECT_INTAKE_EXISTING_SIZE:-}" ;;
    area) printf '%s\n' "${PROJECT_INTAKE_EXISTING_AREA:-}" ;;
    initiative) printf '%s\n' "${PROJECT_INTAKE_EXISTING_INITIATIVE:-}" ;;
  esac
}

write_option() {
  local field_id="$1"
  local option_id="$2"
  local field_name=''
  local option_name=''
  case "$field_id" in
    F_status|10) field_name=status ;;
    F_priority|11) field_name=priority ;;
    F_size|12) field_name=size ;;
    F_area|13) field_name=area ;;
    F_initiative|14) field_name=initiative ;;
  esac
  case "$option_id" in
    O_backlog) option_name=Backlog ;;
    O_done) option_name=Done ;;
    O_p2) option_name=P2 ;;
    O_s) option_name=S ;;
    O_product) option_name=Product ;;
    O_adoption) option_name='Adoption Polish' ;;
  esac
  [[ -n "$field_name" && -n "$option_name" ]] || {
    printf 'unexpected field update: %s=%s\n' "$field_id" "$option_id" >&2
    exit 2
  }
  printf '%s\n' "$option_name" > "${PROJECT_INTAKE_STATE:?}/${field_name}"
}

graphql_item() {
  jq -nc \
    --arg status "$(mock_value status)" \
    --arg priority "$(mock_value priority)" \
    --arg size "$(mock_value size)" \
    --arg area "$(mock_value area)" \
    --arg initiative "$(mock_value initiative)" \
    '{items:[{id:"PVTI_item",status:$status,priority:$priority,size:$size,area:$area,initiative:$initiative}]}'
}

rest_item() {
  jq -nc \
    --arg status "$(mock_value status)" \
    --arg priority "$(mock_value priority)" \
    --arg size "$(mock_value size)" \
    --arg area "$(mock_value area)" \
    --arg initiative "$(mock_value initiative)" \
    '{id:101,fields:[
      {id:10,name:"Status",value:{name:{raw:$status}}},
      {id:11,name:"Priority",value:{name:{raw:$priority}}},
      {id:12,name:"Size",value:{name:{raw:$size}}},
      {id:13,name:"Area",value:{name:{raw:$area}}},
      {id:14,name:"Initiative",value:{name:{raw:$initiative}}}
    ] | map(select(.value.name.raw != ""))}'
}

case "$*" in
  "api repos/basefoundry/base-demo/issues/273")
    count_file="${PROJECT_INTAKE_STATE:?}/issue-view-count"
    count=0
    [[ ! -f "$count_file" ]] || count="$(cat "$count_file")"
    count=$((count + 1))
    printf '%s\n' "$count" > "$count_file"
    if [[ "${PROJECT_INTAKE_AUTH_FAIL:-}" == "1" ]]; then
      printf '401 Unauthorized: Bad credentials\n' >&2
      exit 1
    fi
    printf '%s\n' '{"id":2730,"number":273,"state":"open","html_url":"https://github.com/basefoundry/base-demo/issues/273","title":"Project Intake test issue"}'
    ;;
  "project list --owner basefoundry --format json --limit 100")
    printf '%s\n' '{"projects":[{"title":"base-demo","number":9}]}'
    ;;
  "project view 9 --owner basefoundry --format json --jq .id")
    printf 'PVT_project\n'
    ;;
  project\ item-add*)
    printf 'PVTI_item\n'
    ;;
  project\ item-list*)
    if [[ "${PROJECT_INTAKE_GRAPHQL_FAILURE:-}" == "quota" ]]; then
      printf 'GraphQL: API rate limit already exceeded\n' >&2
      exit 1
    fi
    count_file="${PROJECT_INTAKE_STATE:?}/graphql-item-list-count"
    count=0
    [[ ! -f "$count_file" ]] || count="$(cat "$count_file")"
    count=$((count + 1))
    printf '%s\n' "$count" > "$count_file"
    if [[ "${PROJECT_INTAKE_ITEM_NEVER_VISIBLE:-0}" == "1" ||
          ( "${PROJECT_INTAKE_DELAYED_ITEM_VISIBILITY:-0}" == "1" && "$count" == "1" ) ]]; then
      printf '%s\n' '{"items":[]}'
    else
      graphql_item
    fi
    ;;
  project\ field-list*)
    cat <<'JSON'
{"fields":[
  {"name":"Status","id":"F_status","options":[{"name":"Backlog","id":"O_backlog"},{"name":"Done","id":"O_done"}]},
  {"name":"Priority","id":"F_priority","options":[{"name":"P2","id":"O_p2"}]},
  {"name":"Size","id":"F_size","options":[{"name":"S","id":"O_s"}]},
  {"name":"Area","id":"F_area","options":[{"name":"Product","id":"O_product"}]},
  {"name":"Initiative","id":"F_initiative","options":[{"name":"Adoption Polish","id":"O_adoption"}]}
]}
JSON
    ;;
  project\ item-edit*)
    field_id=''
    option_id=''
    while (( $# > 0 )); do
      case "$1" in
        --field-id) field_id="$2"; shift 2 ;;
        --single-select-option-id) option_id="$2"; shift 2 ;;
        *) shift ;;
      esac
    done
    write_option "$field_id" "$option_id"
    ;;
  "api users/basefoundry")
    printf '%s\n' '{"login":"basefoundry","type":"Organization"}'
    ;;
  "api orgs/basefoundry/projectsV2?per_page=100")
    printf '%s\n' '[{"id":9,"number":9,"title":"base-demo"}]'
    ;;
  "api orgs/basefoundry/projectsV2/9/fields?per_page=100")
    cat <<'JSON'
[
  {"id":10,"name":"Status","options":[{"id":"O_backlog","name":{"raw":"Backlog"}},{"id":"O_done","name":{"raw":"Done"}}]},
  {"id":11,"name":"Priority","options":[{"id":"O_p2","name":{"raw":"P2"}}]},
  {"id":12,"name":"Size","options":[{"id":"O_s","name":{"raw":"S"}}]},
  {"id":13,"name":"Area","options":[{"id":"O_product","name":{"raw":"Product"}}]},
  {"id":14,"name":"Initiative","options":[{"id":"O_adoption","name":{"raw":"Adoption Polish"}}]}
]
JSON
    ;;
  api\ --method\ GET\ orgs/basefoundry/projectsV2/9/items/101*)
    rest_item
    ;;
  api\ --method\ GET\ orgs/basefoundry/projectsV2/9/items*)
    count_file="${PROJECT_INTAKE_STATE:?}/rest-item-search-count"
    count=0
    [[ ! -f "$count_file" ]] || count="$(cat "$count_file")"
    count=$((count + 1))
    printf '%s\n' "$count" > "$count_file"
    if [[ "${PROJECT_INTAKE_ITEM_EXISTS:-1}" == "1" ||
          ( -f "${PROJECT_INTAKE_STATE:?}/rest-item-added" &&
            "${PROJECT_INTAKE_ITEM_NEVER_VISIBLE:-0}" != "1" &&
            ( "${PROJECT_INTAKE_DELAYED_ITEM_VISIBILITY:-0}" != "1" || "$count" != "2" ) ) ]]; then
      if [[ "${PROJECT_INTAKE_CROSS_REPO_DECOY:-0}" == "1" ]]; then
        printf '%s\n' '[{"id":202,"content":{"id":9999,"number":273,"title":"Project Intake test issue"}},{"id":101,"content":{"id":2730,"number":273,"title":"Project Intake test issue"}}]'
      else
        printf '%s\n' '[{"id":101,"content":{"id":2730,"number":273,"title":"Project Intake test issue"}}]'
      fi
    else
      printf '%s\n' '[]'
    fi
    ;;
  api\ --method\ POST\ orgs/basefoundry/projectsV2/9/items*)
    : > "${PROJECT_INTAKE_STATE:?}/rest-item-added"
    if [[ "${PROJECT_INTAKE_REST_ADD_RESPONSE:-nested}" == "top-level" ]]; then
      printf '%s\n' '{"id":101}'
    else
      printf '%s\n' '{"value":{"id":101}}'
    fi
    ;;
  api\ --method\ PATCH\ orgs/basefoundry/projectsV2/9/items/101*)
    payload="$(cat)"
    printf '%s\n' "$payload" >> "${PROJECT_INTAKE_STATE:?}/rest-patches.log"
    while IFS=$'\t' read -r field_id option_id; do
      write_option "$field_id" "$option_id"
    done < <(jq -r '.fields[] | [.id, .value] | @tsv' <<<"$payload")
    rest_item
    ;;
  *)
    printf 'unexpected gh command: %s\n' "$*" >&2
    exit 2
    ;;
esac
''',
        encoding="utf-8",
    )
    gh_mock.chmod(0o755)

    sleep_mock = mockbin / "sleep"
    sleep_mock.write_text(
        "#!/usr/bin/env bash\nprintf '%s\\n' \"$*\" >> \"${PROJECT_INTAKE_STATE:?}/sleep.log\"\n",
        encoding="utf-8",
    )
    sleep_mock.chmod(0o755)
    return mockbin


class ProjectIntakeTests(unittest.TestCase):
    def run_scenario(self, **overrides: str) -> tuple[subprocess.CompletedProcess[str], Path]:
        state = Path(tempfile.mkdtemp(prefix="base-demo-project-intake-"))
        self.addCleanup(shutil.rmtree, state)
        mockbin = write_mocks(state)
        env = os.environ.copy()
        env.update(
            {
                "BASE_PROJECT_OWNER": "basefoundry",
                "BASE_PROJECT_TITLE": "base-demo",
                "BASE_PROJECT_ISSUE_NUMBER": "273",
                "BASE_PROJECT_DEFAULT_OPEN_STATUS": "Backlog",
                "BASE_PROJECT_DEFAULT_CLOSED_STATUS": "Done",
                "BASE_PROJECT_DEFAULT_PRIORITY": "P2",
                "BASE_PROJECT_DEFAULT_SIZE": "S",
                "BASE_PROJECT_DEFAULT_AREA": "Product",
                "BASE_PROJECT_DEFAULT_INITIATIVE": "Adoption Polish",
                "GH_TOKEN": "test-token",
                "GITHUB_REPOSITORY": "basefoundry/base-demo",
                "PROJECT_INTAKE_STATE": str(state),
                "PATH": f"{mockbin}:{env['PATH']}",
            }
        )
        env.update(overrides)
        result = subprocess.run(
            ["bash", "-c", project_intake_run_command()],
            check=False,
            capture_output=True,
            env=env,
            text=True,
            timeout=30,
        )
        return result, state

    def test_matches_reviewed_base_template(self) -> None:
        digest = hashlib.sha256(WORKFLOW.read_bytes()).hexdigest()
        self.assertEqual(
            digest,
            BASE_TEMPLATE_SHA256,
            f"Project Intake must match Base template commit {BASE_TEMPLATE_COMMIT}",
        )

    def test_graphql_quota_exhaustion_falls_back_to_rest(self) -> None:
        result, state = self.run_scenario(PROJECT_INTAKE_GRAPHQL_FAILURE="quota")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("Falling back to the REST Projects API.", result.stderr)
        self.assertIn("via REST fallback", result.stdout)
        self.assertIn(
            "api --method PATCH orgs/basefoundry/projectsV2/9/items/101 --input -",
            (state / "gh.log").read_text(encoding="utf-8"),
        )

    def test_authentication_failure_does_not_fallback_or_retry(self) -> None:
        result, state = self.run_scenario(PROJECT_INTAKE_AUTH_FAIL="1")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("GitHub authentication failed during Project Intake", result.stderr)
        self.assertIn("Bad credentials", result.stderr)
        self.assertNotIn("Falling back", result.stderr)
        self.assertFalse((state / "sleep.log").exists())

    def test_retries_delayed_graphql_item_visibility(self) -> None:
        result, state = self.run_scenario(PROJECT_INTAKE_DELAYED_ITEM_VISIBILITY="1")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("not visible after it was added", result.stderr)
        self.assertEqual((state / "sleep.log").read_text(encoding="utf-8"), "1\n")

    def test_fails_closed_when_item_never_becomes_visible(self) -> None:
        result, state = self.run_scenario(PROJECT_INTAKE_ITEM_NEVER_VISIBLE="1")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("bounded visibility retry", result.stderr)
        self.assertEqual((state / "sleep.log").read_text(encoding="utf-8"), "1\n2\n")
        self.assertNotIn("Synced issue", result.stdout)

    def test_rest_deduplication_uses_exact_issue_identity(self) -> None:
        result, state = self.run_scenario(
            PROJECT_INTAKE_GRAPHQL_FAILURE="quota",
            PROJECT_INTAKE_CROSS_REPO_DECOY="1",
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        gh_log = (state / "gh.log").read_text(encoding="utf-8")
        self.assertIn("items/101", gh_log)
        self.assertNotIn("items/202", gh_log)
        self.assertNotIn("--method POST", gh_log)

    def test_rest_fallback_preserves_existing_fields(self) -> None:
        result, state = self.run_scenario(
            PROJECT_INTAKE_GRAPHQL_FAILURE="quota",
            PROJECT_INTAKE_EXISTING_PRIORITY="P1",
            PROJECT_INTAKE_EXISTING_AREA="Security",
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        payload = json.loads((state / "rest-patches.log").read_text(encoding="utf-8"))
        updates = {entry["id"]: entry["value"] for entry in payload["fields"]}
        self.assertEqual(updates, {10: "O_backlog", 12: "O_s", 14: "O_adoption"})
        self.assertFalse((state / "priority").exists())
        self.assertFalse((state / "area").exists())

    def test_rest_add_accepts_live_response_and_retries_visibility(self) -> None:
        result, state = self.run_scenario(
            PROJECT_INTAKE_GRAPHQL_FAILURE="quota",
            PROJECT_INTAKE_ITEM_EXISTS="0",
            PROJECT_INTAKE_REST_ADD_RESPONSE="top-level",
            PROJECT_INTAKE_DELAYED_ITEM_VISIBILITY="1",
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("not visible after it was added", result.stderr)
        self.assertEqual((state / "sleep.log").read_text(encoding="utf-8"), "1\n")
        gh_log = (state / "gh.log").read_text(encoding="utf-8")
        self.assertEqual(gh_log.count("--method POST"), 1)


if __name__ == "__main__":
    unittest.main(verbosity=2)
