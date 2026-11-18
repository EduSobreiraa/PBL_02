import hashlib
import json
import tempfile
import unittest
from pathlib import Path

from verification.check_pbl03_sources import check_project


class CheckPbl03SourcesTest(unittest.TestCase):
    def setUp(self):
        self.temp_dir = tempfile.TemporaryDirectory()
        self.root = Path(self.temp_dir.name)
        self.write("rtl/top/top_pbl03.v", "module top_pbl03; endmodule\n")
        self.write("vendor/vga/vga_sync.v", "module vga_sync; assign x = 1'b0; endmodule\n")
        self.entries = [
            {"path": "rtl/top/top_pbl03.v", "module": "top_pbl03", "category": "structural"},
            {"path": "vendor/vga/vga_sync.v", "module": "vga_sync", "category": "vendor"},
        ]
        self.write_manifest()
        self.write_qsf()
        self.write_upstream()

    def tearDown(self):
        self.temp_dir.cleanup()

    def write(self, relative_path, content):
        path = self.root / relative_path
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(content, encoding="utf-8")
        return path

    def write_manifest(self):
        self.write("verification/pbl03_sources.json", json.dumps(self.entries))

    def write_qsf(self, extra_lines=()):
        lines = [
            "set_global_assignment -name VERILOG_FILE ../rtl/top/top_pbl03.v",
            "set_global_assignment -name VERILOG_FILE ../vendor/vga/vga_sync.v",
            *extra_lines,
        ]
        self.write("quartus/pbl03.qsf", "\n".join(lines) + "\n")

    def write_upstream(self):
        digest = hashlib.sha256((self.root / "vendor/vga/vga_sync.v").read_bytes()).hexdigest()
        self.write("vendor/vga/UPSTREAM.md", f"- SHA-256: `{digest}`\n")

    def errors(self):
        return check_project(self.root)

    def test_valid_project_passes_and_vendor_syntax_is_exempt(self):
        self.assertEqual([], self.errors())

    def test_qsf_manifest_mismatch_and_legacy_source_fail_with_paths(self):
        self.write("rtl/modulo_principal.v", "module modulo_principal; endmodule\n")
        self.write_qsf(("set_global_assignment -name VERILOG_FILE ../rtl/modulo_principal.v",))
        errors = "\n".join(self.errors())
        self.assertIn("PBL02/legacy source is not allowed", errors)
        self.assertIn("present in quartus/pbl03.qsf but missing from manifest", errors)

    def test_duplicate_manifest_and_qsf_sources_fail(self):
        self.entries.append(dict(self.entries[0]))
        self.write_manifest()
        self.write_qsf(("set_global_assignment -name VERILOG_FILE ../rtl/top/top_pbl03.v",))
        errors = "\n".join(self.errors())
        self.assertIn("duplicate source in verification/pbl03_sources.json", errors)
        self.assertIn("duplicate Verilog source", errors)

    def test_missing_manifest_source_fails(self):
        (self.root / "rtl/top/top_pbl03.v").unlink()
        self.assertIn("source file is missing or unreadable", "\n".join(self.errors()))

    def test_zero_or_multiple_modules_fail(self):
        self.write("rtl/top/top_pbl03.v", "module first; endmodule module second; endmodule\n")
        self.assertIn("expected exactly one module, found 2", "\n".join(self.errors()))

    def test_source_without_module_fails(self):
        self.write("rtl/top/top_pbl03.v", "wire output_signal;\n")
        self.assertIn("expected exactly one module, found 0", "\n".join(self.errors()))

    def test_manifest_source_missing_from_qsf_fails(self):
        self.write("quartus/pbl03.qsf", "set_global_assignment -name VERILOG_FILE ../rtl/top/top_pbl03.v\n")
        errors = "\n".join(self.errors())
        self.assertIn("vendor/vga/vga_sync.v: present in manifest but missing from quartus/pbl03.qsf", errors)

    def test_wrong_module_name_fails(self):
        self.write("rtl/top/top_pbl03.v", "module another_name; endmodule\n")
        self.assertIn("expected top_pbl03 from manifest", "\n".join(self.errors()))

    def test_structural_forbidden_token_fails(self):
        self.write("rtl/top/top_pbl03.v", "module top_pbl03; assign x = y; endmodule\n")
        self.assertIn("token 'assign' is forbidden", "\n".join(self.errors()))

    def test_comments_and_strings_do_not_trigger_token_errors(self):
        source = 'module top_pbl03; // assign always if else\n string message = "for generate begin end"; /* buf initial */ endmodule\n'
        self.write("rtl/top/top_pbl03.v", source)
        self.assertEqual([], self.errors())

    def test_fsm_category_allows_behavioral_control_tokens(self):
        self.entries[0]["category"] = "fsm"
        self.write_manifest()
        self.write("rtl/top/top_pbl03.v", "module top_pbl03; always @(*) begin if (x) y = 1; else y = 0; end endmodule\n")
        self.assertEqual([], self.errors())

    def test_manifest_path_cannot_escape_root(self):
        self.entries[0]["path"] = "../outside.v"
        self.write_manifest()
        errors = "\n".join(self.errors())
        self.assertIn("path escapes the repository root", errors)

    def test_qsf_path_cannot_escape_root(self):
        self.write_qsf(("set_global_assignment -name VERILOG_FILE ../../outside.v",))
        self.assertIn("Verilog source escapes the repository root", "\n".join(self.errors()))

    def test_numeric_vector_index_is_allowed_only_in_location_target(self):
        self.write_qsf(("set_location_assignment PIN_C10 -to SW[0]",))
        self.assertEqual([], self.errors())

        self.write_qsf((
            'set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to SW[0]',
        ))
        self.assertEqual([], self.errors())

        self.write_qsf(("set_global_assignment -name SEARCH_PATH SW[0]",))
        self.assertIn("Tcl command substitution with square brackets is unsupported", "\n".join(self.errors()))

    def test_unsupported_qsf_source_assignments_fail_with_type_and_path(self):
        for assignment, path in (
            ("SYSTEMVERILOG_FILE", "../rtl/extra.sv"),
            ("VHDL_FILE", "../rtl/extra.vhd"),
            ("QIP_FILE", "../ip/legacy.qip"),
            ("VERILOG_INCLUDE_FILE", "../rtl/include_defs.vh"),
            ("IP_FILE", "../ip/extra.ip"),
        ):
            with self.subTest(assignment=assignment):
                self.write_qsf((f"set_global_assignment -name {assignment} {path}",))
                errors = "\n".join(self.errors())
                self.assertIn(f"unsupported source assignment {assignment}", errors)
                self.assertIn(path, errors)

    def test_qsf_source_command_is_rejected_as_unvalidated_include(self):
        self.write_qsf(("source ../quartus/legacy_sources.qsf",))
        errors = "\n".join(self.errors())
        self.assertIn("unsupported source inclusion 'source'", errors)
        self.assertIn("../quartus/legacy_sources.qsf", errors)

    def test_nested_tcl_source_inside_if_is_rejected(self):
        line = "if {1} { source ../quartus/legacy.qsf }"
        self.write_qsf((line,))
        errors = "\n".join(self.errors())
        self.assertIn("quartus/pbl03.qsf:3: unsupported Tcl command 'if'", errors)
        self.assertIn("source ../quartus/legacy.qsf", errors)

    def test_tcl_command_substitution_is_rejected_inside_or_outside_quotes(self):
        for line in (
            "set_global_assignment -name SEARCH_PATH [source ../quartus/legacy.qsf]",
            'set_global_assignment -name SEARCH_PATH "[source ../quartus/legacy.qsf]"',
        ):
            with self.subTest(line=line):
                self.write_qsf((line,))
                errors = "\n".join(self.errors())
                self.assertIn("Tcl command substitution with square brackets is unsupported", errors)
                self.assertIn("../quartus/legacy.qsf", errors)

    def test_qsf_comment_and_quoted_text_do_not_trigger_tcl_command_errors(self):
        self.write_qsf((
            '# if {1} { source [../quartus/legacy.qsf] }',
            'set_global_assignment -name SEARCH_PATH "if {1} { source ../quartus/legacy.qsf }"',
        ))
        errors = "\n".join(self.errors())
        self.assertNotIn("unsupported Tcl command", errors)
        self.assertNotIn("unsupported source inclusion", errors)

    def test_vga_hash_mismatch_fails(self):
        self.write("vendor/vga/vga_sync.v", "module vga_sync; endmodule\n")
        self.assertIn("SHA-256 differs from vendor/vga/UPSTREAM.md", "\n".join(self.errors()))


if __name__ == "__main__":
    unittest.main()
