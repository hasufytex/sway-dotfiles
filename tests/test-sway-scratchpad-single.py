#!/usr/bin/env python3
"""Exercise the admission shortcut with fake IPC; never touch desktop windows."""
import json
import os
from pathlib import Path
import subprocess
import tempfile
import time
import unittest

SCRIPT = Path(__file__).resolve().parents[1] / "scripts/.local/bin/sway-scratchpad-single"


def window(identifier, *, focused=False, scratch=False):
    return dict(type="con", id=identifier, pid=100, app_id="foot",
                focused=focused, scratchpad_state="fresh" if scratch else "none",
                nodes=[], floating_nodes=[])


def tree(*nodes, hidden=()):
    return dict(type="root", nodes=[
        dict(type="workspace", name="__i3_scratch", nodes=[], floating_nodes=list(hidden)),
        dict(type="workspace", name="4", nodes=list(nodes), floating_nodes=[]),
    ])


class ScratchpadTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="scratchpad-single-test-")
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        (self.root / "swaymsg").write_text("""#!/usr/bin/env bash
set -eu
case "$*" in
    '-r -t get_tree')
        printf 'tree\\n' >> "$SCRATCH_TEST_ROOT/queries"
        cat "$SCRATCH_TEST_ROOT/tree.json" ;;
    '-q '*)
        printf '%s\\n' "$2" >> "$SCRATCH_TEST_ROOT/commands"
        if [[ ${SCRATCH_TEST_WAIT:-} ]]; then
            touch "$SCRATCH_TEST_ROOT/started"
            read -r _ < "$SCRATCH_TEST_ROOT/release"
        fi ;;
    *) exit 9 ;;
esac
""")
        (self.root / "swaymsg").chmod(0o755)
        self.env = dict(os.environ, PATH=f"{self.root}:{os.environ['PATH']}",
                        XDG_RUNTIME_DIR=str(self.root), SWAYSOCK="/test/sway.sock",
                        SCRATCH_TEST_ROOT=str(self.root))

    def write_tree(self, value):
        (self.root / "tree.json").write_text(json.dumps(value))

    def invoke(self, value):
        self.write_tree(value)
        return subprocess.run([str(SCRIPT)], env=self.env, capture_output=True, text=True)

    def commands(self):
        path = self.root / "commands"
        return path.read_text().splitlines() if path.exists() else []

    def test_empty_accepts_only_focused_window(self):
        result = self.invoke(tree(window(10), window(11, focused=True)))
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.commands(), [
            "[con_id=11] move scratchpad; [con_id=11] scratchpad show"])

    def test_hidden_window_occupies_slot(self):
        result = self.invoke(tree(window(11, focused=True), hidden=[window(10, scratch=True)]))
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("occupied", result.stderr)
        self.assertEqual(self.commands(), [])

    def test_shown_window_occupies_slot(self):
        result = self.invoke(tree(window(10, scratch=True), window(11, focused=True)))
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.commands(), [])

    def test_existing_member_can_be_hidden(self):
        result = self.invoke(tree(window(10, focused=True, scratch=True)))
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.commands(), ["[con_id=10] move scratchpad"])

    def test_nested_hidden_membership(self):
        group = dict(type="floating_con", id=20, scratchpad_state="fresh",
                     nodes=[window(10), window(12)], floating_nodes=[])
        result = self.invoke(tree(window(11, focused=True), hidden=[group]))
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.commands(), [])

    def test_parent_with_multiple_windows_is_refused(self):
        group = dict(type="con", id=20, focused=True, nodes=[window(10), window(11)],
                     floating_nodes=[])
        result = self.invoke(tree(group))
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.commands(), [])

    def test_focused_child_of_floating_group_is_refused(self):
        value = tree()
        value["nodes"][1]["floating_nodes"] = [dict(
            type="floating_con", id=20, nodes=[window(10), window(11, focused=True)],
            floating_nodes=[])]
        result = self.invoke(value)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("individual", result.stderr)
        self.assertEqual(self.commands(), [])

    def test_single_floating_window_is_accepted(self):
        value = tree()
        value["nodes"][1]["floating_nodes"] = [window(11, focused=True)]
        result = self.invoke(value)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.commands(), [
            "[con_id=11] move scratchpad; [con_id=11] scratchpad show"])

    def test_no_focus_and_bad_tree_do_not_move_anything(self):
        self.assertEqual(self.invoke(tree(window(11))).returncode, 0)
        self.assertNotEqual(self.invoke({}).returncode, 0)
        self.assertEqual(self.commands(), [])

    def test_already_over_limit_does_not_evict_or_add(self):
        result = self.invoke(tree(window(11, focused=True), hidden=[
            window(10, scratch=True), window(12, scratch=True)]))
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.commands(), [])

    def test_parallel_presses_serialize_check_and_command(self):
        self.write_tree(tree(window(11, focused=True)))
        os.mkfifo(self.root / "release")
        first = subprocess.Popen([str(SCRIPT)], env=dict(self.env, SCRATCH_TEST_WAIT="1"),
                                 stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        try:
            deadline = time.monotonic() + 3
            while not (self.root / "started").exists():
                self.assertIsNone(first.poll())
                self.assertLess(time.monotonic(), deadline)
                time.sleep(0.01)
            second = subprocess.run([str(SCRIPT)], env=self.env, capture_output=True,
                                    text=True, timeout=2)
            self.assertEqual(second.returncode, 0, second.stderr)
            self.assertEqual((self.root / "queries").read_text().splitlines(), ["tree"])
            self.assertEqual(self.commands(), [
                "[con_id=11] move scratchpad; [con_id=11] scratchpad show"])
        finally:
            with (self.root / "release").open("w") as release:
                release.write("done\n")
            _, error = first.communicate(timeout=2)
            self.assertEqual(first.returncode, 0, error)


if __name__ == "__main__":
    unittest.main()
