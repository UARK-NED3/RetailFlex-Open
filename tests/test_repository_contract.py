import json
from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]


class RepositoryContractTests(unittest.TestCase):
    def test_source_manifest_has_no_embedded_local_paths_or_redistributed_inputs(self):
        manifest = json.loads((ROOT / "config" / "source_manifest.json").read_text(encoding="utf-8"))
        self.assertEqual(manifest["project"], "RetailFlex-Open")
        self.assertTrue(all(not source["redistributed"] for source in manifest["sources"]))
        self.assertNotIn("C:\\", json.dumps(manifest))

    def test_baseline_script_requires_weather_bundle_and_marks_output_as_screening(self):
        script = (ROOT / "scripts" / "build_supermarket_baseline.rb").read_text(encoding="utf-8")
        self.assertIn("Missing --epw PATH", script)
        self.assertIn("Missing companion DDY", script)
        self.assertIn("generated_screening_baseline", script)
        self.assertIn("not calibrated or independently validated", script)

    def test_demo_keeps_walmart_and_refrigeration_control_out_of_scope(self):
        config = json.loads((ROOT / "config" / "demo_scenarios.json").read_text(encoding="utf-8"))
        combined = json.dumps(config).lower()
        self.assertIn("not calibrated", combined)
        self.assertNotIn("refrigeration control", combined)
        self.assertEqual([scenario["id"] for scenario in config["scenarios"]], [
            "baseline", "thermal_shift", "thermal_shift_lighting"
        ])
