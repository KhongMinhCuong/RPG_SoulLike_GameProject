# Hướng Dẫn Tạo Player Scene Cho Từng Nhân Vật

## Bước 1: Duplicate Player Scene Gốc

Bạn đã có `player.tscn` với Wind Hashashin sprite. Giờ sẽ tạo 4 scene riêng:

### Trong Godot Editor:

1. **Tạo Scene cho Warrior:**
   - Right-click `Player/player.tscn` → Duplicate
   - Đổi tên thành `player_warrior.tscn`
   - Di chuyển vào `Player/Scenes/player_warrior.tscn`

2. **Tạo Scene cho Rogue:**
   - Right-click `Player/player.tscn` → Duplicate
   - Đổi tên thành `player_rogue.tscn`
   - Di chuyển vào `Player/Scenes/player_rogue.tscn`

3. **Tạo Scene cho Tank:**
   - Right-click `Player/player.tscn` → Duplicate
   - Đổi tên thành `player_tank.tscn`
   - Di chuyển vào `Player/Scenes/player_tank.tscn`

4. **Tạo Scene cho Mage:**
   - Right-click `Player/player.tscn` → Duplicate
   - Đổi tên thành `player_mage.tscn`
   - Di chuyển vào `Player/Scenes/player_mage.tscn`

## Bước 2: Customize Từng Scene

### A. Thay Đổi Sprites

Mở từng scene và thay sprite set:

**player_warrior.tscn:**
- Chọn node `AnimatedSprite2D`
- Trong Inspector → Sprite Frames → Tạo mới hoặc load sprite riêng
- Có thể giữ nguyên Wind Hashashin hoặc thay bằng sprite khác

**player_rogue.tscn:**
- Sprite nhanh nhẹn, nhỏ gọn hơn
- Animation nhanh hơn (tăng FPS trong Animation)

**player_tank.tscn:**
- Sprite to lớn, chắc nịch
- Animation chậm hơn (giảm FPS)

**player_mage.tscn:**
- Sprite mỏng manh, có hiệu ứng phép thuật
- Animation ưu tiên casting spells

### B. Thay Đổi Hitbox

Mỗi nhân vật có kích thước khác nhau:

**Warrior:**
```gdscript
# Trong Hitbox node (Area2D hoặc CollisionShape2D)
# Shape: Rectangle hoặc Capsule
# Size: Vừa phải, tầm đánh trung bình
```

**Rogue:**
```gdscript
# Shape: Nhỏ, hẹp
# Size: Nhỏ hơn 30% so với warrior
# Tầm đánh ngắn nhưng tốc độ cao
```

**Tank:**
```gdscript
# Shape: To, rộng
# Size: Lớn hơn 50% so với warrior
# Tầm đánh rộng nhưng chậm
```

**Mage:**
```gdscript
# Shape: Vừa
# Size: Tầm đánh xa (projectile-based)
# Có thể có nhiều hitbox cho spells
```

### C. Customize Scripts (Nếu Cần)

**Cách 1: Dùng chung player.gd (Đơn giản)**
- Tất cả scene đều dùng `player.gd`
- Khác biệt chỉ ở stats, sprite, hitbox

**Cách 2: Script riêng cho từng class (Nâng cao)**
```
Player/Scripts/
  player.gd              # Base script
  player_warrior.gd      # extends player.gd
  player_rogue.gd        # extends player.gd
  player_tank.gd         # extends player.gd
  player_mage.gd         # extends player.gd
```

Trong script riêng, override các hàm:
```gdscript
# player_rogue.gd
extends "res://Player/Scripts/player.gd"

func _ready():
	super._ready()
	# Rogue-specific setup
	speed_multiplier = 1.5
	dodge_chance = 0.2

func special_ability():
	# Dash ability cho Rogue
	velocity = get_input_direction() * 1000
```

## Bước 3: Cập Nhật CharacterData

Mở từng file `.tres` và gán scene tương ứng:

**warrior.tres:**
- `player_scene_path` = `res://Player/Scenes/player_warrior.tscn`

**rogue.tres:**
- `player_scene_path` = `res://Player/Scenes/player_rogue.tscn`

**tank.tres:**
- `player_scene_path` = `res://Player/Scenes/player_tank.tscn`

**mage.tres:**
- `player_scene_path` = `res://Player/Scenes/player_mage.tscn`

## Bước 4: Test

1. Chạy `character_selection.tscn`
2. Chọn nhân vật
3. Click START GAME
4. GameManager sẽ tự động load scene tương ứng

## Cấu Trúc File Cuối Cùng

```
Player/
  player.tscn                    # Scene gốc (giữ lại hoặc xóa)
  Scenes/
    player_warrior.tscn          # Scene riêng cho Warrior
    player_rogue.tscn            # Scene riêng cho Rogue
    player_tank.tscn             # Scene riêng cho Tank
    player_mage.tscn             # Scene riêng cho Mage
  Scripts/
    player.gd                    # Base script (dùng chung)
    player_warrior.gd            # (Optional) Script riêng
    player_rogue.gd              # (Optional) Script riêng
    player_tank.gd               # (Optional) Script riêng
    player_mage.gd               # (Optional) Script riêng
  Characters/
    warrior.tres                 # player_scene_path = player_warrior.tscn
    rogue.tres                   # player_scene_path = player_rogue.tscn
    tank.tres                    # player_scene_path = player_tank.tscn
    mage.tres                    # player_scene_path = player_mage.tscn
```

## Lưu Ý Quan Trọng

⚠️ **Stats được apply tự động:**
- Không cần thay đổi `player.gd`
- CharacterData đã được apply trong `_ready()`

⚠️ **Hitbox riêng biệt:**
- Mỗi scene có CollisionShape2D riêng
- Thay đổi shape/size tùy ý

⚠️ **Animation độc lập:**
- Mỗi scene có AnimatedSprite2D riêng
- Có thể thay FPS, frame count, sprite khác nhau
