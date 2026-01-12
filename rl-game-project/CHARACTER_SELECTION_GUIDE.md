# Hướng dẫn tạo hệ thống chọn nhân vật

## ✅ Cấu trúc files:

```
rl-game-project/
├── Scripts/
│   └── game_manager.gd          # Singleton quản lý game state
├── Player/
│   ├── Scripts/
│   │   └── character_data.gd    # Resource class định nghĩa nhân vật
│   └── Characters/              # [TẠO MỚI] Chứa các .tres files
│       ├── warrior.tres
│       ├── rogue.tres
│       └── tank.tres
└── Scenes/
    ├── character_selection.tscn # [TẠO MỚI] Scene UI chọn nhân vật
    └── character_selection.gd   # Script cho scene trên
```

## 📋 Các bước tiếp theo:

### Bước 1: Tạo GameManager Autoload

1. Mở **Project → Project Settings → Autoload**
2. Click **Add**:
   - **Path**: `res://Scripts/game_manager.gd`
   - **Node Name**: `GameManager`
   - Check **Enable**
3. Click **Add** → **Close**

### Bước 2: Tạo CharacterData resources cho từng nhân vật

**Ví dụ tạo Warrior:**

1. Trong FileSystem, tạo folder: `Player/Characters/`
2. Click chuột phải → **Create New → Resource**
3. Tìm và chọn **CharacterData**
4. Lưu với tên: `warrior.tres`
5. Click vào file `warrior.tres` trong Inspector:
   - **Character ID**: `warrior`
   - **Character Name**: `Warrior`
   - **Description**: `Chiến binh mạnh mẽ với sức tấn công cao`
   - **Starting Stats**:
     - Starting Strength: `5`
     - Starting Vitality: `3`
     - Starting Dexterity: `0`
     - Starting Movement Speed: `0`
     - Starting Luck: `0`
   - **Starting Points**:
     - Starting Basic Points: `92` (100 - 8 đã dùng)
     - Starting Special Points: `3`
   - **Character Portrait**: Kéo texture vào (optional)
   - **Sprite Frames**: Kéo SpriteFrames vào (optional)

**Tạo thêm các nhân vật khác:**

**Rogue (Sát thủ nhanh nhẹn):**
- Starting Strength: `0`
- Starting Vitality: `0`
- Starting Dexterity: `5`
- Starting Movement Speed: `5`
- Starting Luck: `2`
- Starting Basic Points: `88`

**Tank (Phòng thủ cao):**
- Starting Strength: `2`
- Starting Vitality: `8`
- Starting Dexterity: `0`
- Starting Movement Speed: `0`
- Starting Luck: `0`
- Starting Basic Points: `90`

**Mage (Cân bằng):**
- Starting Strength: `0`
- Starting Vitality: `2`
- Starting Dexterity: `3`
- Starting Movement Speed: `2`
- Starting Luck: `3`
- Starting Basic Points: `90`

### Bước 3: Tạo Character Selection Scene

1. Tạo scene mới: **Scene → New Scene**
2. Root node: **Control** (rename thành `CharacterSelection`)
3. Thêm UI structure:

```
CharacterSelection (Control)
├─ VBox (VBoxContainer)
│  ├─ TitleLabel (Label) - "SELECT YOUR CHARACTER"
│  ├─ CharacterList (VBoxContainer) - Chứa buttons
│  ├─ DetailPanel (PanelContainer)
│  │  └─ VBox (VBoxContainer)
│  │     ├─ PortraitRect (TextureRect)
│  │     ├─ NameLabel (Label)
│  │     ├─ DescriptionLabel (Label)
│  │     └─ StatsLabel (Label)
│  └─ StartButton (Button) - "START GAME"
```

4. Attach script: `res://Scenes/character_selection.gd`
5. Trong Inspector của root node **CharacterSelection**:
   - **Available Characters**: Click **Array[CharacterData]**
   - Set size = 3 (hoặc số nhân vật bạn có)
   - Kéo các file `.tres` vào từng slot:
     - Element 0: `warrior.tres`
     - Element 1: `rogue.tres`
     - Element 2: `tank.tres`
6. Lưu scene: `res://Scenes/character_selection.tscn`

### Bước 4: Test hệ thống

**Option A: Set Character Selection làm scene khởi động**
1. **Project → Project Settings → Application → Run**
2. **Main Scene**: Chọn `res://Scenes/character_selection.tscn`
3. Chạy game (F5) → Chọn nhân vật → Click START GAME

**Option B: Tạo nút test trong game scene hiện tại**
Thêm vào player.gd để test:
```gdscript
func _input(event):
    if event.is_action_pressed("ui_select"):  # Space key
        GameManager.goto_character_selection()
```

### Bước 5: Tùy chỉnh UI (Optional)

**Làm đẹp Character Selection:**
- Thêm background image
- Thêm portraits cho từng nhân vật
- Animations khi hover/select
- Thêm sound effects
- Thêm preview animation của nhân vật

**Thêm vào DetailPanel:**
```gdscript
@onready var preview_sprite: AnimatedSprite2D = $VBox/DetailPanel/VBox/PreviewSprite

func _update_detail_panel(character: CharacterData):
    # ... existing code ...
    
    # Preview animation
    if preview_sprite and character.sprite_frames:
        preview_sprite.sprite_frames = character.sprite_frames
        preview_sprite.play("idle")
```

## 🎮 Cách sử dụng:

### Trong game:
```gdscript
# Lấy nhân vật đã chọn
var character = GameManager.get_selected_character()
if character:
    print("Playing as: ", character.character_name)

# Save game
GameManager.save_game(player.base_stats)

# Load game
var save_data = GameManager.load_game()
if save_data:
    player.base_stats.load_from_dict(save_data["stats"])
```

### Tạo nhân vật mới:
1. Tạo file `.tres` mới
2. Set stats và thông tin
3. Thêm vào `available_characters` array trong character_selection scene

## 🔧 Debug:

**Nếu không có nhân vật trong list:**
- Check `available_characters` array có đủ elements không
- Check các file `.tres` có tồn tại không
- Xem console log: `[CharacterSelection] Loaded X characters`

**Nếu stats không apply:**
- Check GameManager có được add vào Autoload chưa
- Check `character_data.apply_to_stats()` có được gọi không
- Xem console: `[Player] Loaded character: XXX`

## 📝 Mở rộng:

**Thêm abilities riêng cho từng nhân vật:**
1. Thêm vào CharacterData:
```gdscript
@export var special_abilities: Array[String] = []
@export var passive_bonuses: Dictionary = {}
```

2. Apply trong Player:
```gdscript
if character_data.special_abilities.has("double_jump"):
    enable_double_jump()
```

**Save/Load character đã chọn:**
- Đã implement trong GameManager
- Gọi `GameManager.save_game(player_stats)` khi muốn save
- Gọi `GameManager.load_game()` để load

Xong! Hệ thống chọn nhân vật đã sẵn sàng! 🎉
