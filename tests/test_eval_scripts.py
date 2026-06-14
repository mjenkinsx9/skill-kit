"""Self-tests for bin/behavioral-check and bin/trigger-accuracy.

Run from the repo root:

    python -m pytest tests -q

Both scripts are pure stdlib and have no package (their filenames are
extensionless bin/ executables), so they are loaded via
importlib.machinery.SourceFileLoader (spec_from_file_location alone cannot
infer a loader for a suffix-less file). Nothing here executes external
commands or touches ~/.claude — score()'s transcript resolution is
monkeypatched onto tmp_path fixtures.
"""

import importlib.machinery
import importlib.util
import json
import sys
from pathlib import Path

import pytest

BIN_DIR = Path(__file__).resolve().parents[1] / "bin"  # .../bin


def _load(mod_name: str, filename: str):
    path = BIN_DIR / filename
    loader = importlib.machinery.SourceFileLoader(mod_name, str(path))
    spec = importlib.util.spec_from_file_location(mod_name, path, loader=loader)
    mod = importlib.util.module_from_spec(spec)
    sys.modules[mod_name] = mod
    spec.loader.exec_module(mod)
    return mod


bc = _load("behavioral_check", "behavioral-check")
ta = _load("trigger_accuracy", "trigger-accuracy")


# ---- behavioral-check: extract_commands ---------------------------------------


class TestExtractCommands:
    def test_fenced_bash_block(self):
        md = (
            "## Scenario 1: golden path\n"
            "\n"
            "```bash\n"
            "python scripts/run.py --json\n"
            "echo not-a-launcher\n"
            "```\n"
        )
        cmds = bc.extract_commands(md)
        assert cmds == [
            {"scenario": "Scenario 1: golden path",
             "command": "python scripts/run.py --json"}
        ]

    def test_inline_backtick_command_span(self):
        md = "## Scenario 2: edge\n\nRun `python x.py` and inspect the report.\n"
        cmds = bc.extract_commands(md)
        assert cmds == [{"scenario": "Scenario 2: edge", "command": "python x.py"}]

    def test_prose_backticks_ignored(self):
        md = (
            "## Scenario 3: error\n"
            "\n"
            "The `status` field and `capacity_percent` are prose, not commands.\n"
        )
        assert bc.extract_commands(md) == []

    def test_scenario_label_preferred_over_preamble(self):
        # Same command appears under a generic preamble heading first and a
        # real "Scenario N" heading later: the scenario label must win, and
        # the command must be kept exactly once.
        md = (
            "# Preamble\n"
            "`python scripts/t.py`\n"
            "\n"
            "## Scenario 2: edge case\n"
            "`python scripts/t.py`\n"
        )
        cmds = bc.extract_commands(md)
        assert cmds == [
            {"scenario": "Scenario 2: edge case", "command": "python scripts/t.py"}
        ]

    def test_scenario_label_not_downgraded(self):
        # First seen under a real scenario heading; a later duplicate under a
        # non-scenario heading must NOT overwrite the label.
        md = (
            "## Scenario 1: golden\n"
            "`python scripts/t.py`\n"
            "\n"
            "## Cleanup\n"
            "`python scripts/t.py`\n"
        )
        cmds = bc.extract_commands(md)
        assert cmds == [
            {"scenario": "Scenario 1: golden", "command": "python scripts/t.py"}
        ]

    def test_env_prefixed_command_accepted(self):
        md = (
            "## Scenario 4: env\n"
            "\n"
            "```bash\n"
            "CERT_SCAN_TIMEOUT=4 python scripts/scan.py --all\n"
            "```\n"
        )
        cmds = bc.extract_commands(md)
        assert cmds == [
            {"scenario": "Scenario 4: env",
             "command": "CERT_SCAN_TIMEOUT=4 python scripts/scan.py --all"}
        ]


# ---- behavioral-check: split_env ----------------------------------------------


class TestSplitEnv:
    def test_no_prefix(self):
        assert bc.split_env("python x.py") == ({}, "python x.py")

    def test_single_prefix(self):
        assert bc.split_env("FOO=1 python x.py") == ({"FOO": "1"}, "python x.py")

    def test_multiple_prefixes(self):
        env, rest = bc.split_env("A=1 B=two python x.py --flag")
        assert env == {"A": "1", "B": "two"}
        assert rest == "python x.py --flag"


# ---- behavioral-check: flags_for ----------------------------------------------


class TestFlagsFor:
    def test_clean_run_has_no_flags(self):
        res = {"timed_out": False, "stdout": "ok\n", "stderr": ""}
        assert bc.flags_for(res) == []

    def test_timeout_flag(self):
        res = {"timed_out": True, "stdout": "partial\n", "stderr": ""}
        assert bc.flags_for(res) == ["TIMEOUT"]

    def test_traceback_flag(self):
        res = {
            "timed_out": False,
            "stdout": "some output\n",
            "stderr": 'Traceback (most recent call last):\n  File "x.py" ...\n',
        }
        assert bc.flags_for(res) == ["TRACEBACK"]

    def test_empty_stdout_flag(self):
        res = {"timed_out": False, "stdout": "  \n", "stderr": "note\n"}
        assert bc.flags_for(res) == ["EMPTY-STDOUT"]

    def test_combined_flags_in_order(self):
        res = {
            "timed_out": True,
            "stdout": "",
            "stderr": "Traceback (most recent call last):\n",
        }
        assert bc.flags_for(res) == ["TIMEOUT", "TRACEBACK", "EMPTY-STDOUT"]


# ---- trigger-accuracy: parse_prompts ------------------------------------------


class TestParsePrompts:
    def test_valid_rows(self, tmp_path):
        f = tmp_path / "test-prompts.md"
        f.write_text(
            "# fixtures\n"
            "\n"
            "y | review this widget fixture for me\n"
            "n | what is the weather today\n"
            "some prose line that is not a fixture row\n",
            encoding="utf-8",
        )
        rows = ta.parse_prompts(f)
        assert rows == [
            {"prompt": "review this widget fixture for me", "should_fire": True},
            {"prompt": "what is the weather today", "should_fire": False},
        ]

    def test_no_rows_exits(self, tmp_path):
        f = tmp_path / "test-prompts.md"
        f.write_text("# no fixture rows here\njust prose\n", encoding="utf-8")
        with pytest.raises(SystemExit):
            ta.parse_prompts(f)

    def test_all_positive_exits(self, tmp_path):
        f = tmp_path / "test-prompts.md"
        f.write_text("y | one\ny | two\n", encoding="utf-8")
        with pytest.raises(SystemExit):
            ta.parse_prompts(f)

    def test_missing_file_exits(self, tmp_path):
        with pytest.raises(SystemExit):
            ta.parse_prompts(tmp_path / "does-not-exist.md")


# ---- trigger-accuracy: detect_fire --------------------------------------------


def _write_transcript(path: Path, blocks, top_level_content=False):
    """Write a minimal one-line sub-agent transcript carrying `blocks`."""
    if top_level_content:
        obj = {"content": blocks}
    else:
        obj = {"message": {"role": "assistant", "content": blocks}}
    lines = [
        "this line is not JSON and must be skipped",
        json.dumps(obj),
    ]
    path.write_text("\n".join(lines), encoding="utf-8")
    return path


def _skill_block(name):
    return {"type": "tool_use", "name": "Skill", "input": {"skill": name}}


class TestDetectFire:
    def test_exact_skill_match(self, tmp_path):
        t = _write_transcript(tmp_path / "a.jsonl", [_skill_block("widget-lint")])
        assert ta.detect_fire(t, "widget-lint") == {
            "fired": True, "other_skill_fired": None, "error": None}

    def test_namespaced_suffix_match(self, tmp_path):
        t = _write_transcript(
            tmp_path / "b.jsonl", [_skill_block("plugin:widget-lint")],
            top_level_content=True)  # also exercises the top-level-content shape
        assert ta.detect_fire(t, "widget-lint") == {
            "fired": True, "other_skill_fired": None, "error": None}

    def test_stealer_recorded(self, tmp_path):
        t = _write_transcript(tmp_path / "c.jsonl", [_skill_block("other-skill")])
        assert ta.detect_fire(t, "widget-lint") == {
            "fired": False, "other_skill_fired": "other-skill", "error": None}

    def test_read_of_skill_md_fallback(self, tmp_path):
        blocks = [{
            "type": "tool_use", "name": "Read",
            "input": {"file_path":
                      "C:\\repo\\.claude\\skills\\widget-lint\\SKILL.md"},
        }]
        t = _write_transcript(tmp_path / "d.jsonl", blocks)
        res = ta.detect_fire(t, "widget-lint",
                             skill_md=".claude/skills/widget-lint/SKILL.md")
        assert res == {"fired": True, "other_skill_fired": None, "error": None}

    def test_read_fallback_needs_skill_md(self, tmp_path):
        # Same Read block, but no --skill-md given: must NOT count as fired.
        blocks = [{
            "type": "tool_use", "name": "Read",
            "input": {"file_path":
                      "C:\\repo\\.claude\\skills\\widget-lint\\SKILL.md"},
        }]
        t = _write_transcript(tmp_path / "e.jsonl", blocks)
        assert ta.detect_fire(t, "widget-lint")["fired"] is False

    def test_pi_tool_call_read_fallback(self, tmp_path):
        blocks = [{
            "type": "toolCall", "name": "read",
            "arguments": {"path": "/repo/.codex/skills/widget-lint/SKILL.md"},
        }]
        t = _write_transcript(tmp_path / "pi.jsonl", blocks)
        res = ta.detect_fire(
            t, "widget-lint", skill_md=".codex/skills/widget-lint/SKILL.md")
        assert res == {"fired": True, "other_skill_fired": None, "error": None}

    def test_openai_tool_calls_read_fallback(self, tmp_path):
        obj = {"message": {"role": "assistant", "tool_calls": [{"function": {
            "name": "functions.read",
            "arguments": json.dumps(
                {"path": "/repo/.codex/skills/widget-lint/SKILL.md"}),
        }}]}}
        t = tmp_path / "codex.jsonl"
        t.write_text(json.dumps(obj), encoding="utf-8")
        res = ta.detect_fire(
            t, "widget-lint", skill_md=".codex/skills/widget-lint/SKILL.md")
        assert res == {"fired": True, "other_skill_fired": None, "error": None}

    def test_top_level_function_call_read_fallback(self, tmp_path):
        obj = {
            "type": "function_call",
            "name": "read",
            "arguments": json.dumps(
                {"path": "/repo/.codex/skills/widget-lint/SKILL.md"}),
        }
        t = tmp_path / "function_call.jsonl"
        t.write_text(json.dumps(obj), encoding="utf-8")
        res = ta.detect_fire(
            t, "widget-lint", skill_md=".codex/skills/widget-lint/SKILL.md")
        assert res == {"fired": True, "other_skill_fired": None, "error": None}

    def test_missing_transcript_is_error(self, tmp_path):
        res = ta.detect_fire(tmp_path / "nope.jsonl", "widget-lint")
        assert res == {"fired": False, "other_skill_fired": None,
                       "error": "transcript-not-found"}

    def test_empty_transcript_is_error(self, tmp_path):
        t = tmp_path / "empty.jsonl"
        t.write_text("", encoding="utf-8")
        res = ta.detect_fire(t, "widget-lint")
        assert res == {"fired": False, "other_skill_fired": None,
                       "error": "empty-transcript"}

    def test_codex_text_signal_optional(self, tmp_path):
        t = tmp_path / "codex-text.jsonl"
        t.write_text(json.dumps({
            "type": "item.completed",
            "item": {"type": "agent_message",
                     "text": "I am using the `widget-lint` workflow."},
        }), encoding="utf-8")
        assert ta.detect_fire(t, "widget-lint")["fired"] is False
        assert ta.detect_fire(t, "widget-lint", text_signal=True) == {
            "fired": True, "other_skill_fired": None, "error": None}


# ---- trigger-accuracy: score ---------------------------------------------------


class TestScore:
    def test_aggregate_math_and_inconclusive_exclusion(self, tmp_path, monkeypatch):
        fire = [_skill_block("widget-lint")]
        steal = [_skill_block("other-skill")]
        transcripts = {
            "a1": _write_transcript(tmp_path / "a1.jsonl", fire),
            "a2": _write_transcript(tmp_path / "a2.jsonl", fire),
            "b1": _write_transcript(tmp_path / "b1.jsonl", steal),
            "c1": _write_transcript(tmp_path / "c1.jsonl", steal),
            "d1": _write_transcript(tmp_path / "d1.jsonl", fire),
        }
        # "zz" resolves to no transcript -> detect error -> inconclusive prompt.
        monkeypatch.setattr(ta, "resolve_transcript",
                            lambda agent_id: transcripts.get(agent_id))
        runs = [
            {"prompt": "p-tp", "should_fire": True, "agent_ids": ["a1", "a2"]},
            {"prompt": "p-tn", "should_fire": False, "agent_ids": ["b1"]},
            {"prompt": "p-fn", "should_fire": True, "agent_ids": ["c1"]},
            {"prompt": "p-fp", "should_fire": False, "agent_ids": ["d1"]},
            {"prompt": "p-inc", "should_fire": False, "agent_ids": ["zz"]},
        ]
        result = ta.score(runs, "widget-lint", None, 0.5)

        agg = result["aggregate"]
        assert agg["tp"] == 1 and agg["fp"] == 1
        assert agg["tn"] == 1 and agg["fn"] == 1
        assert agg["n"] == 4                  # inconclusive prompt excluded
        assert agg["inconclusive"] == 1
        assert agg["positives"] == 2 and agg["negatives"] == 2
        assert agg["precision"] == 0.5
        assert agg["recall"] == 0.5
        assert agg["accuracy"] == 0.5
        assert agg["trigger"] == 0.5

        by_prompt = {p["query"]: p for p in result["prompts"]}
        assert by_prompt["p-tp"]["pass"] is True
        assert by_prompt["p-tp"]["rate"] == 1.0
        assert by_prompt["p-tn"]["pass"] is True
        assert by_prompt["p-tn"]["other_skill_fired"] == "other-skill"  # stealer
        assert by_prompt["p-fn"]["pass"] is False
        assert by_prompt["p-fp"]["pass"] is False
        assert by_prompt["p-inc"]["pass"] is None
        assert by_prompt["p-inc"]["errors"] == 1
        assert by_prompt["p-inc"]["runs"] == 0

    def test_all_inconclusive_scores_zero_accuracy(self, monkeypatch):
        monkeypatch.setattr(ta, "resolve_transcript", lambda agent_id: None)
        runs = [{"prompt": "p", "should_fire": True, "agent_ids": ["x"]}]
        agg = ta.score(runs, "widget-lint", None, 0.5)["aggregate"]
        assert agg["n"] == 0
        assert agg["inconclusive"] == 1
        assert agg["accuracy"] == 0.0  # phantom credit must not be granted

    def test_score_transcripts_uses_explicit_paths(self, tmp_path):
        fire = [_skill_block("widget-lint")]
        miss = [_skill_block("other-skill")]
        fire_t = _write_transcript(tmp_path / "fire.jsonl", fire)
        miss_t = _write_transcript(tmp_path / "miss.jsonl", miss)
        runs = [
            {"prompt": "p-tp", "should_fire": True,
             "transcripts": [str(fire_t)]},
            {"prompt": "p-tn", "should_fire": False,
             "transcripts": [str(miss_t)]},
        ]
        result = ta.score_transcripts(runs, "widget-lint", None, 0.5)
        assert result["mechanism"] == "transcript-paths"
        assert result["aggregate"]["trigger"] == 1.0
