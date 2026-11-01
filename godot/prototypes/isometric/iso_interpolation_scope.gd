extends RefCounted
## Runtime scope shared only by district/room. Never writes project settings.
## Reference counting also handles freeing the district while its room is open.
static var users=0
static var previous=false
static func acquire(tree: SceneTree) -> void:
 if users==0:
  previous=tree.physics_interpolation
  tree.physics_interpolation=true
 users+=1
static func release(tree: SceneTree) -> void:
 users-=1
 if users==0:tree.physics_interpolation=previous
