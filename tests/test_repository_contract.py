import json
from pathlib import Path
import importlib.util
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
        self.assertEqual(config["title"], "RetailFlex Decision Studio")
        self.assertEqual([scenario["id"] for scenario in config["scenarios"]], [
            "baseline", "thermal_shift", "thermal_shift_lighting"
        ])

    def test_controlled_site_interface_is_generic_and_protected(self):
        ignore_rules = (ROOT / ".gitignore").read_text(encoding="utf-8")
        manifest = json.loads((ROOT / "config" / "controlled_site_manifest.example.json").read_text(encoding="utf-8"))
        script = (ROOT / "scripts" / "inspect_controlled_site_model.rb").read_text(encoding="utf-8")
        self.assertIn("private/", ignore_rules)
        self.assertIn("controlled_site/", ignore_rules)
        self.assertEqual(manifest["data_classification"], "controlled")
        self.assertIn("public_release", manifest["prohibited_without_separate_authorization"])
        self.assertIn("non_identifying_structural_inventory", script)
        self.assertIn("No store-specific savings claim", script)

    def test_synthetic_site_intake_is_ready_and_has_no_identifying_content(self):
        spec = importlib.util.spec_from_file_location("site_intake", ROOT / "scripts" / "validate_site_intake.py")
        module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(module)
        intake = json.loads((ROOT / "config" / "site_intake.example.json").read_text(encoding="utf-8"))
        report = module.assess(intake)
        self.assertEqual(report["readiness"], "ready_with_warnings")
        self.assertEqual(report["permitted_next_step"], "configure_site_baseline_and_document_reconciliation")
        self.assertIn("bms_trends: pending authorization", report["warnings"])
        self.assertNotIn("Walmart", json.dumps(intake))

    def test_track_a_demo_configuration_has_explicit_gates(self):
        config = json.loads((ROOT / "config" / "demo_track_a.json").read_text(encoding="utf-8"))
        measure_states = [measure["state"] for measure in config["measure_library"]]
        self.assertEqual(config["evidence_class"], "synthetic_metadata_and_simulated_prototype_outputs")
        self.assertEqual(config["readiness_example"]["status"], "ready_with_warnings")
        self.assertIn("out of scope", measure_states)
        self.assertIn("Live BAS control", config["readiness_example"]["blocked_actions"])

    def test_published_demo_exposes_track_a_without_controlled_material(self):
        page = (ROOT / "docs" / "index.html").read_text(encoding="utf-8")
        self.assertIn("Readiness gate", page)
        self.assertIn("Bounded measure library", page)
        self.assertIn("synthetic Track A metadata", page)
        self.assertIn("Store-specific savings claim", page)
        self.assertNotIn("C:\\Users\\hanhu", page)
        self.assertNotIn("controlled_workspace", page)

    def test_demo_builder_exposes_interactive_trade_space_and_measure_explorer(self):
        builder = (ROOT / "scripts" / "build_demo_html.rb").read_text(encoding="utf-8")
        self.assertIn("Scenario trade-space", builder)
        self.assertIn("drawScatter", builder)
        self.assertIn("Measure explorer", builder)
        self.assertIn("selectScenario", builder)
        self.assertIn("selectMeasure", builder)

    def test_climate_atlas_is_public_derived_data_not_store_data(self):
        generator = (ROOT / "scripts" / "build_climate_atlas.py").read_text(encoding="utf-8")
        atlas_page = (ROOT / "docs" / "atlas" / "index.html").read_text(encoding="utf-8")
        self.assertIn("source_records_redistributed\": False", generator)
        self.assertIn("retail_climate_archetype", generator)
        self.assertIn("RetailFlex Climate Atlas", atlas_page)
        self.assertIn("not retail stores", atlas_page)
        atlas_app = (ROOT / "docs" / "atlas" / "app.js").read_text(encoding="utf-8")
        self.assertIn("RETAILFLEX_CLIMATE_ATLAS", atlas_app)
        self.assertNotIn("fetch(", atlas_app)
