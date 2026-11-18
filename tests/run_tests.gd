extends SceneTree
## Minimal test runner, no external framework.
## Usage: godot --headless --path . -s res://tests/run_tests.gd [-- suite_name]
## Each suite is a script with test_* methods. A test fails if it calls fail().

const SUITES := {
	"combat": "res://tests/test_combat.gd",
}


func _initialize() -> void:
	var only: Array = []
	for arg in OS.get_cmdline_user_args():
		only.append(arg)
	var passed := 0
	var failed := 0
	for suite_name: String in SUITES:
		if not only.is_empty() and not only.has(suite_name):
			continue
		var suite: Object = load(SUITES[suite_name]).new()
		for m in suite.get_method_list():
			var mname: String = m["name"]
			if not mname.begins_with("test_"):
				continue
			suite.set("failures", [])
			suite.call(mname)
			var failures: Array = suite.get("failures")
			if failures.is_empty():
				passed += 1
				print("PASS  %s.%s" % [suite_name, mname])
			else:
				failed += 1
				print("FAIL  %s.%s" % [suite_name, mname])
				for f in failures:
					print("        - %s" % f)
	print("---- %d passed, %d failed" % [passed, failed])
	quit(1 if failed > 0 else 0)
