extends GutTest

func before_all():
	gut.p("Runs once before all tests")
	# When getting errors about overriding methods in these base Godot classes, just ignore them
	# Ex:
	var HolderClass = load("res://Scripts/Holder.gd")
	for method in Area3D.new().get_method_list():
		ignore_method_when_doubling(HolderClass, method.name)

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
