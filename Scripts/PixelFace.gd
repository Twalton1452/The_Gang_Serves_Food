extends Sprite3D
class_name PixelFace

enum Face {
	Satisfied = 0,
	Shifty = 1,
	Sad = 2,
	Frustrated = 3,
	Mad = 4,
	Smile = 5,
	Neutral = 6,
	Smirk = 7,
	Love = 8,
	Crying = 9,
	Gasm = 10,
	Cute = 11
}

func change_expression_to(expression: Face):
	frame = expression

func random_expression():
	frame = randi_range(0, hframes * vframes - 1)
