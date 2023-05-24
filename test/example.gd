extends GutTest

func example_stubbing():
	# double removes implementation details of all functions in the scripts
	# partial_double retains the functionality of the source code
	
	# DOUBLE_STRATEGY.INCLUDE_SUPER includes base classes like CharacterBody3D which is undesirable
	# because it gives you errors about overriding functions in base Godot classes
	# DOUBLE_STRATEGY.SCRIPT_ONLY includes just the scripts you've defined, which is desirable
	# allowing you to stub/spy methods on scripts that inherit base Godot classes
	
	var HolderClass = load("res://Scripts/Holder.gd")
	var holder = partial_double(HolderClass, DOUBLE_STRATEGY.SCRIPT_ONLY).new()
	stub(holder, "is_enabled").to_return(true)
	
func before_all():
	gut.p("Runs once before all tests")

func before_each():
	gut.p("Runs before each test.")

func after_each():
	gut.p("Runs after each test.")

func after_all():
	gut.p("Runs once after all tests")

func test_assert_eq_number_not_equal():
	assert_eq(1, 2, "Should fail.  1 != 2")

func test_assert_eq_number_equal():
	assert_eq('asdf', 'asdf', "Should pass")

func test_does_something_each_loop():
	var node = Node3D.new()
	add_child_autofree(node)
	# calls _physics_process and _process on object, x times, delta time
	gut.simulate(node, 20, .1)
	assert_eq(1, 1, 'Since a_number is incremented in _process, it should be 20 now')

class TestSomeAspects:
	extends GutTest

	func test_assert_eq_number_not_equal():
		assert_eq(1, 2, "Should fail.  1 != 2")

	func test_assert_eq_number_equal():
		assert_eq('asdf', 'asdf', "Should pass")
