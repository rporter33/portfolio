extends SceneTree
## Headless test runner:
##   godot --headless --path game -s res://tests/run_tests.gd
## Runs every test_*.gd in tests/unit/ and exits non-zero on any failure.

const DIR := "res://tests/unit/"


func _initialize() -> void:
	var total_checks := 0
	var total_tests := 0
	var failures: Array[String] = []
	var files := Array(DirAccess.get_files_at(DIR))
	files.sort()
	for f in files:
		if not (f.begins_with("test_") and f.ends_with(".gd")):
			continue
		var script: GDScript = load(DIR + f)
		if script == null:
			failures.append("%s: failed to load" % f)
			continue
		var suite = script.new()
		var methods: Array = suite.get_method_list()
		for m in methods:
			var mname: String = m["name"]
			if not mname.begins_with("test_"):
				continue
			total_tests += 1
			suite.current = "%s::%s" % [f.get_basename(), mname]
			suite.call(mname)
		total_checks += suite.checks
		failures.append_array(suite.failures)
		print("  %-28s %3d checks%s" % [f.get_basename(), suite.checks,
			"" if suite.failures.is_empty() else "  (%d FAILED)" % suite.failures.size()])
	print("")
	for msg in failures:
		print("FAIL  " + msg)
	print("%d tests, %d checks, %d failures" % [total_tests, total_checks, failures.size()])
	quit(1 if not failures.is_empty() else 0)
