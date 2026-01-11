# HƯỚNG DẪN SETUP HỆ THỐNG NHIỀU NHÂN VẬT

## ⚠️ QUAN TRỌNG: Đọc kỹ từng bước

Hệ thống này cho phép mỗi nhân vật có:
- ✅ Scene riêng (player_warrior.tscn, player_rogue.tscn, ...)
- ✅ Hitbox riêng (kích thước khác nhau)
- ✅ Animation riêng (sprite frames khác nhau)
- ✅ Mechanics riêng (scripts khác nhau - nếu cần)

---

## BƯỚC 1: Thêm GameManager vào Autoload

1. Mở Godot Editor
2. **Project → Project Settings → Autoload**
3. Click **Add** (icon folder)
4. Chọn `res://Scripts/game_manager.gd`
5. Node Name: `GameManager`
6. Click **Add**
7. Click **Close**

⚠️ **PHẢI LÀM BƯỚC NÀY TRƯỚC KHI TIẾP TỤC!**

---

## BƯỚC 2: Duplicate Player Scene Cho Từng Nhân vật

### Trong FileSystem (Godot Editor):

1. **Tạo thư mục Player/Scenes** (đã có rồi)

2. **Duplicate player.tscn 4 lần:**
   - Right-click `Player/player.tscn` → **Duplicate**
   - Đổi tên thành `player_warrior.tscn`
   - **Di chuyển vào `Player/Scenes/`**
   
   - Lặp lại cho:
     - `player_rogue.tscn`
     - `player_tank.tscn`
     - `player_mage.tscn`

**Kết quả:**
```
Player/
  player.tscn              # Scene gốc (có thể xóa sau)
  Scenes/
    player_warrior.tscn    ✅
    player_rogue.tscn      ✅
    player_tank.tscn       ✅
    player_mage.tscn       ✅
```

---

## BƯỚC 3: Customize Từng Scene

### A. Thay Đổi Sprite Frames (Tùy chọn)

Hiện tại tất cả đều dùng Wind Hashashin sprite. Nếu muốn thay:

1. Mở `player_warrior.tscn`
2. Chọn node `AnimatedSprite2D`
3. Inspector → Sprite Frames → Click icon → **Save As**
4. Lưu thành `res://Player/Sprites/warrior_sprites.tres`
5. Thay texture trong từng animation frame

**Hoặc giữ nguyên Wind Hashashin cho tất cả** (test trước rồi thay sau)

### B. Thay Đổi Hitbox

Mỗi nhân vật có kích thước hitbox khác nhau:

#### Warrior (Balanced):
1. Mở `player_warrior.tscn`
2. Tìm node `Hitbox` hoặc `Area2D` → `CollisionShape2D`
3. Inspector → Shape → Adjust size
   - Capsule: height ~100, radius ~30
   - Rectangle: ~60x100

#### Rogue (Small, Fast):
1. Mở `player_rogue.tscn`
2. Hitbox nhỏ hơn 30%:
   - Capsule: height ~70, radius ~20
   - Rectangle: ~40x70

#### Tank (Large, Slow):
1. Mở `player_tank.tscn`
2. Hitbox lớn hơn 50%:
   - Capsule: height ~150, radius ~45
   - Rectangle: ~90x150

#### Mage (Medium, Ranged):
1. Mở `player_mage.tscn`
2. Hitbox vừa phải:
   - Capsule: height ~90, radius ~25
   - Rectangle: ~50x90

### C. Thay Đổi Animation Speed (Tùy chọn)

#### Warrior - Normal speed:
- Giữ nguyên FPS mặc định

#### Rogue - Fast attacks:
1. Mở `player_rogue.tscn`
2. AnimatedSprite2D → Animation tab
3. Chọn animation "1_atk", "2_atk", "3_atk"
4. Tăng FPS từ 10 → 15

#### Tank - Slow attacks:
1. Mở `player_tank.tscn`
2. Giảm FPS từ 10 → 7

#### Mage - Normal:
- Giữ nguyên

---

## BƯỚC 4: Gán Scene Path Vào CharacterData

### Cập nhật từng file .tres:

#### 1. warrior.tres:
1. Mở `Player/Characters/warrior.tres` trong Inspector
2. **Player Scene Path** → Click folder icon
3. Chọn `res://Player/Scenes/player_warrior.tscn`
4. **Ctrl+S** để save

#### 2. rogue.tres:
- **Player Scene Path** = `res://Player/Scenes/player_rogue.tscn`

#### 3. tank.tres:
- **Player Scene Path** = `res://Player/Scenes/player_tank.tscn`

#### 4. mage.tres:
- **Player Scene Path** = `res://Player/Scenes/player_mage.tscn`

⚠️ **QUAN TRỌNG:** Nhớ save từng file .tres!

---

## BƯỚC 5: Setup Character Selection Scene

### Nếu chưa có Scenes/character_selection.tscn:

1. **Tạo scene mới:**
   - Scene → New Scene
   - Root: Control
   - Save as `res://Scenes/character_selection.tscn`

2. **Thêm script:**
   - Attach script: `res://Scenes/character_selection.gd` (đã có sẵn)

3. **Tạo UI structure:**
   ```
   Control (Root)
   └── VBoxContainer
       ├── Label (Title: "SELECT CHARACTER")
       ├── CharacterList (VBoxContainer)
       ├── DetailPanel (VBoxContainer)
       │   ├── Portrait (TextureRect)
       │   ├── Name (Label)
       │   ├── Description (Label)
       │   └── Stats (Label)
       └── StartButton (Button)
   ```

4. **Load character data:**
   - Chọn root node (Control)
   - Inspector → Script Variables
   - **Available Characters** → Size: 4
   - Element 0: Kéo `warrior.tres` vào
   - Element 1: Kéo `rogue.tres` vào
   - Element 2: Kéo `tank.tres` vào
   - Element 3: Kéo `mage.tres` vào

5. **Ctrl+S** save scene

### Nếu đã có character_selection.tscn:

- Chỉ cần load 4 file .tres vào array `available_characters`

---

## BƯỚC 6: Test

### Test Character Selection:

1. **Set làm Main Scene:**
   - Right-click `Scenes/character_selection.tscn`
   - **Set as Main Scene**

2. **Chạy game (F5):**
   - Sẽ thấy danh sách 4 nhân vật
   - Click chọn 1 nhân vật
   - Xem thông tin stats
   - Click **START GAME**

### Kiểm tra:

✅ Scene chuyển đến player scene tương ứng
✅ Stats được apply đúng
✅ Hitbox khác nhau (test bằng debug draw)
✅ Animation phù hợp

---

## BƯỚC 7: Tùy Chỉnh Thêm (Optional)

### A. Tạo Script Riêng Cho Từng Class

Nếu muốn mỗi class có mechanics khác nhau:

1. **Tạo script mới:**
   ```
   Player/Scripts/
     player_warrior.gd
     player_rogue.gd
     player_tank.gd
     player_mage.gd
   ```

2. **Extend base player:**
   ```gdscript
   # player_warrior.gd
   extends "res://Player/Scripts/player.gd"
   
   func _ready():
       super._ready()
       # Warrior-specific setup
   
   func special_ability():
       # Warrior special: Power Strike
       pass
   ```

3. **Attach script vào scene:**
   - Mở `player_warrior.tscn`
   - Chọn root node
   - Inspector → Script → Load `player_warrior.gd`

### B. Thêm Portrait

1. Tạo 4 hình 60x60:
   - `warrior_portrait.png`
   - `rogue_portrait.png`
   - `tank_portrait.png`
   - `mage_portrait.png`

2. Gán vào từng .tres:
   - `warrior.tres` → Character Portrait → load `warrior_portrait.png`

### C. Thêm Special Abilities

Trong từng CharacterData:
- **Special Ability Name**: "Power Strike"
- **Special Ability Description**: "Deal 200% damage"

---

## Troubleshooting

### ❌ "GameManager not found":
- Kiểm tra Project Settings → Autoload
- Phải có `GameManager` enabled

### ❌ "Character has no player scene":
- Kiểm tra .tres file → Player Scene Path phải có giá trị
- Path phải đúng: `res://Player/Scenes/player_warrior.tscn`

### ❌ Scene không chuyển:
- Kiểm tra console log
- Đảm bảo path scene tồn tại

### ❌ Stats không apply:
- Kiểm tra `player.gd` → `_ready()` có load character không
- Log debug: `print(GameManager.selected_character)`

---

## Checklist Hoàn Thành

- [ ] GameManager trong Autoload
- [ ] 4 player scenes đã duplicate
- [ ] Hitbox của từng scene đã thay đổi
- [ ] 4 file .tres đã gán player_scene_path
- [ ] character_selection.tscn đã load 4 .tres vào array
- [ ] Test chọn nhân vật thành công
- [ ] Test game chạy với mỗi nhân vật

---

**Hoàn thành! 🎉**

Bạn đã có hệ thống chọn nhân vật với:
- 4 nhân vật khác nhau
- Mỗi nhân vật có scene riêng
- Hitbox tùy chỉnh
- Sẵn sàng mở rộng (thêm sprites, abilities, mechanics)
