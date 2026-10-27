extends Node2D
var elapsed:=0.0
func _ready() -> void:set_as_top_level(true)
func _process(delta: float) -> void:elapsed+=delta;queue_redraw()
func _draw() -> void:
 for i in range(13):
  var x=790.0+fmod(i*83.0+elapsed*8.0,440.0)
  var y=530.0+fmod(i*37.0,170.0)
  draw_line(Vector2(x,y),Vector2(x+12+sin(elapsed+i)*4,y),Color(.65,.85,.77,.13),1.0)
