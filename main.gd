extends Control

# Nós de Interface (Labels)
@onready var board_label: Label = get_node("Board")
@onready var status_label: Label = get_node("Status")
@onready var end_game_screen: Label = get_node("EndGame")

# Nós Visuais da Cena (Carregados com verificação para evitar erros)
@onready var food_sprite: TextureRect = get_node_or_null("FoodDisplay")
@onready var boy_animated_sprite: AnimatedSprite2D = get_node_or_null("BoySprite")
@onready var monster_shadow: Sprite2D = get_node_or_null("MonsterShadow")

# Variáveis do estado do jogo
var monster_distance: int = 0
const MAX_MONSTER_DISTANCE: int = 4 # 4 erros = Game Over

var rounds_left: int = 5 # Rodadas restantes até a avó voltar
var game_over: bool = false

var foods_list: Array = []
var current_food: Food = null


func generate_foods() -> Array:
	var list = []
	# Comidas Saudáveis
	list.append(Food.new("Tapioca recheada com queijo coalho", true, "Forte e nutritiva!", "res://assets/foods/tapioca.png"))
	list.append(Food.new("Cuscuz quentinho", true, "Sustenta o menino na noite.", "res://assets/foods/cuscuz.png"))
	list.append(Food.new("Macaxeira cozida", true, "Energia pura do sertão.", "res://assets/foods/macaxeira.png"))
	list.append(Food.new("Baião de Dois equilibrado", true, "Mistura perfeita de feijão e arroz.", "res://assets/foods/baiao.png"))
	
	# Comidas Não Saudáveis / Biscoitos / Doces
	list.append(Food.new("Rapadura em excesso", false, "Muito açúcar de uma vez só!", "res://assets/foods/rapadura.png"))
	list.append(Food.new("Refrigerante ultraprocessado", false, "Não mata a sede de verdade.", "res://assets/foods/refrigerante.png"))
	list.append(Food.new("Biscoito recheado", false, "Cheio de gordura e conservantes.", "res://assets/foods/biscoito.png"))
	return list


func _ready() -> void:
	# Mantido com button_up e get_node conforme sua preferência exata
	get_node("Comer").button_up.connect(_on_comer_button_up)
	get_node("Recusar").button_up.connect(_on_recusar_button_up)
	get_node("Resetar").button_up.connect(_on_resetar_button_up)
	
	reset_game()


func reset_game() -> void:
	game_over = false
	monster_distance = 0
	rounds_left = 5
	
	end_game_screen.text = ""
	status_label.text = "Escolha se o menino deve comer ou recusar usando o mouse!"
	
	foods_list = generate_foods()
	foods_list.shuffle()
	
	update_boy_visual("idle")
	update_monster_visual()
	next_round()


func next_round() -> void:
	if game_over:
		return
		
	if rounds_left <= 0:
		win_game()
		return
		
	if foods_list.is_empty():
		foods_list = generate_foods()
		foods_list.shuffle()
		
	current_food = foods_list.pop_front()
	update_food_display()
	update_board()


func update_board() -> void:
	var text = "--- O BICHO TE PEGA ---\n"
	text += "A vovó volta em: " + str(rounds_left) + " rodadas\n"
	text += "Proximidade do Bicho-Papão: " + get_monster_indicator() + "\n\n"
	
	if current_food != null and not game_over:
		text += "Na mesa apareceu: [ " + current_food.name + " ]\n"
		if current_food.description != "":
			text += current_food.description + "\n"
	elif game_over:
		text += "Fim das rodadas!\n"
	
	board_label.text = text


func get_monster_indicator() -> String:
	match monster_distance:
		0:
			return "Longe (Silêncio no quintal...)"
		1:
			return "Nível 1 (Barulho de galhos lá fora...)"
		2:
			return "Nível 2 (Olhos brilhando na janela!)"
		3:
			return "Nível 3 (Passos pesados na porta!!)"
		_:
			return "O Bicho te pegou!"


func register_choice(ate_food: bool) -> void:
	if game_over:
		return
		
	if ate_food:
		update_boy_visual("eating")
		if current_food.is_healthy:
			status_label.text = "Boa escolha! " + current_food.name + " te deu energia."
			if monster_distance > 0:
				monster_distance -= 1
		else:
			status_label.text = "Xi... " + current_food.name + " fez mal! O Bicho se aproximou!"
			monster_distance += 1
	else:
		if current_food.is_healthy:
			status_label.text = "Recusou comida boa! Fazer desfeita atraiu o Bicho."
			monster_distance += 1
		else:
			status_label.text = "Sábia decisão! Recusou algo que faria mal."

	rounds_left -= 1
	update_monster_visual()

	if monster_distance >= 2 and monster_distance < MAX_MONSTER_DISTANCE:
		update_boy_visual("scared")

	if monster_distance >= MAX_MONSTER_DISTANCE:
		trigger_game_over()
	else:
		await get_tree().create_timer(1.0).timeout
		if not game_over:
			update_boy_visual("idle")
			next_round()


func trigger_game_over() -> void:
	game_over = true
	update_board()
	update_boy_visual("scared")
	end_game_screen.text = "GAME OVER! O Bicho-Papão pegou o menino antes da vovó chegar!"


func win_game() -> void:
	game_over = true
	update_board()
	end_game_screen.text = "VITÓRIA! A vovó chegou do culto e o menino está seguro!"


# --- Funções de Atualização dos Mídias Visuais ---

func update_food_display() -> void:
	if food_sprite != null and current_food != null and current_food.icon_texture != null:
		food_sprite.texture = current_food.icon_texture
		food_sprite.visible = true


func update_boy_visual(state: String) -> void:
	if boy_animated_sprite != null and boy_animated_sprite.sprite_frames != null:
		boy_animated_sprite.play(state)


func update_monster_visual() -> void:
	if monster_shadow != null:
		monster_shadow.modulate.a = float(monster_distance) / float(MAX_MONSTER_DISTANCE)


# --- Conexões dos Botões (Mantidas Exatamente como Solicitado) ---

func _on_comer_button_up() -> void:
	register_choice(true)

func _on_recusar_button_up() -> void:
	register_choice(false)

func _on_resetar_button_up() -> void:
	reset_game()
