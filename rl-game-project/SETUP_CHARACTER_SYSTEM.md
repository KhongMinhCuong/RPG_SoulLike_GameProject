# 🎮 HƯỚNG DẪN SETUP HỆ THỐNG CHỌN NHÂN VẬT

## ✅ Đã có sẵn:

1. ✅ **4 nhân vật mẫu** trong `Player/Characters/`:
   - `warrior.tres` - Chiến binh (STR + VIT)
   - `rogue.tres` - Sát thủ (DEX + MOV + LCK)
   - `tank.tres` - Xe tăng (VIT cao)
   - `mage.tres` - Pháp sư (Balanced)

2. ✅ **Character Selection Scene**: `Scenes/character_selection.tscn`

3. ✅ **Scripts**: character_data.gd, game_manager.gd, character_selection.gd

---

## 🚀 SETUP NHANH (5 BƯỚC)

### Bước 1: Add GameManager vào Autoload

1. Mở **Project → Project Settings**
2. Tab **Autoload**
3. Click icon **folder** bên cạnh "Path"
4. Chọn `res://Scripts/game_manager.gd`
5. Node Name: `GameManager`
6. Click **Add**
7. Click **Close**

### Bước 2: Load Character Data vào Scene

1. Mở scene `Scenes/character_selection.tscn`
2. Click vào node root **CharacterSelection**
3. Trong **Inspector**, tìm **Script Variables**
4. Tìm **Available Characters** (Array[Resource])
5. Click mũi tên để expand
6. Set **Size** = `4`
7. Kéo thả các file vào từng slot:
   - **Element 0**: Kéo `Player/Characters/warrior.tres`
   - **Element 1**: Kéo `Player/Characters/rogue.tres`
   - **Element 2**: Kéa `Player/Characters/tank.tres`
   - **Element 3**: Kéo `Player/Characters/mage.tres`
8. **Ctrl+S** để save scene

### Bước 3: Set Main Scene

1. **Project → Project Settings**
2. Tab **Application → Run**
3. **Main Scene**: Click icon folder
4. Chọn `res://Scenes/character_selection.tscn`
5. Click **Close**

### Bước 4: Test

1. Nhấn **F5** hoặc click **Play**
2. Màn hình sẽ hiện 4 nút: Warrior, Rogue, Tank, Mage
3. Click vào 1 nhân vật → Xem thông tin chi tiết bên phải
4. Click **START GAME** → Chuyển sang game scene

### Bước 5: Verify trong Game

1. Sau khi vào game, nhấn **Tab** để mở Stats UI
2. Check **Points**: Phải thấy số points đúng (ví dụ: Warrior có 92 basic points)
3. Check **Base Stats**: Phải có stats ban đầu (ví dụ: Warrior có STR=5, VIT=3)

---

## 🎨 TẠO NHÂN VẬT MỚI

### Cách 1: Duplicate nhân vật có sẵn

1. Trong **FileSystem**, vào `Player/Characters/`
2. Chuột phải vào `warrior.tres` → **Duplicate**
3. Đổi tên thành `assassin.tres`
4. Click vào file mới
5. Trong **Inspector**, chỉnh các giá trị:
   ```
   Character ID: assassin
   Character Name: Assassin
   Description: Sát thủ tối thượng...
   
   Starting Stats:
   - Starting Strength: 3
   - Starting Vitality: 1
   - Starting Dexterity: 7
   - Starting Movement Speed: 5
   - Starting Luck: 4
   
   Starting Points:
   - Starting Basic Points: 80
   - Starting Special Points: 5
   ```
6. **Ctrl+S** để save

7. Thêm vào Character Selection:
   - Mở `Scenes/character_selection.tscn`
   - Click node **CharacterSelection**
   - Tăng **Available Characters → Size** lên `5`
   - Kéo `assassin.tres` vào **Element 4**
   - Save scene

### Cách 2: Tạo mới từ đầu

1. **FileSystem** → `Player/Characters/`
2. Chuột phải → **Create New → Resource**
3. Trong dialog, gõ `CharacterData` → Chọn **CharacterData**
4. Lưu với tên `berserker.tres`
5. Click vào file, điền thông tin trong **Inspector**
6. Thêm vào scene như cách 1

---

## 🎯 CUSTOM STATS CHO NHÂN VẬT

### Công thức phân phối điểm:

**Tổng điểm ban đầu**: 100 basic points
**Mỗi stat = 1 point**

```
Điểm đã dùng = STR + VIT + DEX + MOV + LCK
Điểm còn lại = 100 - Điểm đã dùng
```

**Ví dụ**:
- Warrior: 5+3+0+0+0 = 8 → Còn 92 points
- Rogue: 0+0+5+5+2 = 12 → Còn 88 points
- Tank: 2+8+0+0+0 = 10 → Còn 90 points

### Gợi ý build nhân vật:

**Glass Cannon** (Damage cực cao, HP thấp):
```
STR: 10, VIT: 0, DEX: 5, MOV: 3, LCK: 2
Points: 80
```

**Speedster** (Siêu tốc, tránh damage):
```
STR: 2, VIT: 2, DEX: 8, MOV: 10, LCK: 3
Points: 75
```

**Lucky Tank** (HP cao + drop rate):
```
STR: 3, VIT: 10, DEX: 0, MOV: 0, LCK: 7
Points: 80
```

**Balanced** (Toàn diện):
```
STR: 5, VIT: 5, DEX: 5, MOV: 3, LCK: 2
Points: 80
```

---

## 🖼️ THÊM PORTRAIT CHO NHÂN VẬT

1. Chuẩn bị ảnh portrait (PNG, 256x256 hoặc 512x512)
2. Import vào Godot (kéo vào FileSystem)
3. Mở file `.tres` của nhân vật
4. Trong **Inspector**:
   - **Character Portrait**: Kéo file ảnh vào
5. Portrait sẽ hiện trong Character Selection UI

---

## 🎨 THÊM SPRITE RIÊNG CHO NHÂN VẬT

1. Tạo **SpriteFrames** resource cho nhân vật
2. Add animations: idle, run, attack, etc.
3. Mở file `.tres` của nhân vật
4. **Sprite Frames**: Kéa SpriteFrames resource vào
5. Khi chọn nhân vật, sprite sẽ tự động apply vào Player

---

## 🔧 DEBUG & TROUBLESHOOT

### Không thấy nhân vật trong list:
- Check `available_characters` có đủ elements không
- Check các file `.tres` có load được không (click thử)
- Xem Console: `[CharacterSelection] Loaded X characters`

### Stats không đúng khi vào game:
- Check GameManager đã add vào Autoload chưa
- Check Console: `[Player] Loaded character: XXX`
- Xem `[CharacterData] Applied 'XXX' to stats`

### START GAME bị disable:
- Phải click chọn 1 nhân vật trước
- Check Console có lỗi không

### Lỗi "CharacterData not found":
- Restart Godot Editor (Ctrl+R)
- Hoặc dùng `Array[Resource]` thay vì `Array[CharacterData]`

---

## 🎮 TIPS & TRICKS

### Tạo nhân vật unlock dần:
```gdscript
# Trong character_selection.gd
func _populate_character_list():
	for i in range(available_characters.size()):
		var character = available_characters[i]
		var button = Button.new()
		
		# Lock nhân vật theo điều kiện
		if character.character_id == "assassin" and not GameManager.has_unlocked("assassin"):
			button.disabled = true
			button.text = "??? (Locked)"
		else:
			button.text = character.character_name
```

### Random stats mỗi run:
```gdscript
# Trong character_data.gd
func randomize_stats():
	var total = 100
	starting_strength = randi() % 10
	starting_vitality = randi() % 10
	# ... phân phối random
```

### Stat modifiers:
Sử dụng các modifiers trong CharacterData:
- `damage_modifier = 1.2` → Tăng 20% damage
- `health_modifier = 0.8` → Giảm 20% HP
- `speed_modifier = 1.5` → Tăng 50% tốc độ

---

## ✨ HOÀN THÀNH!

Hệ thống chọn nhân vật đã sẵn sàng!

**Test ngay**: F5 → Chọn nhân vật → START GAME → Tab để xem stats!
