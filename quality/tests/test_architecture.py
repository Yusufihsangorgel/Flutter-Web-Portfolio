"""Calibration for quality/check_architecture.py.

Every case under "calibration" in quality/architecture-rules.json is written
into a scratch tree and scanned with the repository's real rules. A positive
case must trigger exactly the listed rule ids, a negative case none, so a
broken pattern or parser cannot pass as a clean tree.

Run: python3 -m unittest discover -s quality/tests
"""
import json
import os
import sys
import tempfile
import unittest

QUALITY_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
REPO_ROOT = os.path.dirname(QUALITY_DIR)
sys.path.insert(0, QUALITY_DIR)

import check_architecture as arch  # noqa: E402


def write(root, relative, text):
    path = os.path.join(root, relative)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", encoding="utf-8") as handle:
        handle.write(text)


class ArchitectureCalibrationTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        with open(os.path.join(REPO_ROOT, arch.DEFAULT_CONFIG), encoding="utf-8") as handle:
            cls.config = json.load(handle)
        cls.cases = cls.config.get("calibration", [])

    def test_config_has_positive_and_negative_cases(self):
        self.assertTrue(any(case["expect"] for case in self.cases), "no positive case")
        self.assertTrue(any(not case["expect"] for case in self.cases), "no negative case")

    def test_every_rule_is_calibrated(self):
        calibrated = {rule for case in self.cases for rule in case["expect"]}
        declared = {rule["id"] for rule in self.config["rules"]}
        self.assertEqual(declared - calibrated, set(), "rules without a positive case")

    def test_cases_trigger_exactly_the_expected_rules(self):
        for case in self.cases:
            with self.subTest(file=case["file"]):
                self.assertEqual(sorted(case["expect"]), self.scan_case(case))

    def scan_case(self, case):
        with tempfile.TemporaryDirectory(prefix="arch-calibration-") as scratch:
            config = dict(self.config, baseline="quality/no-baseline.json")
            write(scratch, arch.DEFAULT_CONFIG, json.dumps(config))
            for source in config["sources"]:
                if source["lang"] == "go":
                    write(scratch, source["dir"] + "/go.mod", "module %s\n" % source["go_module"])
            write(scratch, case["file"], case["source"])
            _, _, sources, rules, exclude = arch.load_config(scratch, arch.DEFAULT_CONFIG)
            violations, _ = arch.scan(scratch, sources, rules, exclude)
            return sorted(rule.id for rule, path, _, _ in violations if path == case["file"])


if __name__ == "__main__":
    unittest.main()
