"""Tests architecture rule calibration."""
import argparse
import contextlib
import io
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

    def test_every_rule_has_positive_and_negative_coverage(self):
        declared = {rule["id"] for rule in self.config["rules"]}
        positive = {
            rule for case in self.cases if case["expect"]
            for rule in case.get("covers", [])
        }
        negative = {
            rule for case in self.cases if not case["expect"]
            for rule in case.get("covers", [])
        }
        self.assertEqual(declared, positive, "rules without positive coverage")
        self.assertEqual(declared, negative, "rules without negative coverage")
        self.assertTrue(all(set(case.get("covers", [])) <= declared for case in self.cases))

    def test_layers_cover_the_declared_architecture(self):
        _, layers, _, _, _ = arch.load_config(REPO_ROOT, arch.DEFAULT_CONFIG)
        samples = {
            "presentation": [
                "lib/app/modules/home/home_view.dart",
                "lib/app/widgets/language_switcher.dart",
            ],
            "application": [
                "lib/app/features/language/application/language_cubit.dart",
                "lib/app/controllers/scene_director.dart",
                "lib/app/narrative/application/narrative_position.dart",
            ],
            "domain": [
                "lib/app/domain/providers/asset_loader.dart",
                "lib/app/features/render_quality/domain/render_quality.dart",
                "lib/app/narrative/domain/narrative_document.dart",
            ],
            "core": ["lib/app/core/constants/app_colors.dart"],
            "data": ["lib/app/data/providers/bundle_asset_loader.dart"],
        }

        for layer, paths in samples.items():
            matcher = arch.Matcher(layers[layer], layers)
            for path in paths:
                with self.subTest(layer=layer, path=path):
                    self.assertIsNotNone(matcher.match(path))

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

    def test_baseline_shrink_only_removes_entries(self):
        with tempfile.TemporaryDirectory(prefix="arch-baseline-") as scratch:
            baseline_path = "quality/architecture-baseline.json"
            initial = {"violations": ["kept", "stale"]}
            write(scratch, baseline_path, json.dumps(initial))
            args = argparse.Namespace(init_baseline=False, shrink_baseline=True)

            baseline, stale = arch.settle_baseline(
                args,
                scratch,
                baseline_path,
                {"kept", "new"},
            )

            self.assertEqual(baseline, {"kept"})
            self.assertEqual(stale, [])
            with open(os.path.join(scratch, baseline_path), encoding="utf-8") as handle:
                self.assertEqual(json.load(handle)["violations"], ["kept"])

    def test_new_and_stale_violations_are_reported(self):
        _, _, _, rules, _ = arch.load_config(REPO_ROOT, arch.DEFAULT_CONFIG)
        rule = next(item for item in rules if item.id == "F-ISOLATION")
        violations = [(rule, "lib/app/features/alpha/probe.dart", 2,
                       "lib/app/features/beta/probe.dart")]
        stale = ["F-ISOLATION|lib/app/features/old/probe.dart|missing.dart"]
        output = io.StringIO()

        with contextlib.redirect_stdout(output):
            new, known = arch.report(violations, set(), stale, False)

        self.assertEqual(len(new), 1)
        self.assertEqual(known, [])
        self.assertIn("NEW lib/app/features/alpha/probe.dart:2 F-ISOLATION", output.getvalue())
        self.assertIn("STALE baseline entry", output.getvalue())


if __name__ == "__main__":
    unittest.main()
