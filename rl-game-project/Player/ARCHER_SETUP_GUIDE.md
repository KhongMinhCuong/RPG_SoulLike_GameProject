# CHARACTER ABILITIES SYSTEM GUIDE

## 1. Tổng quan Hệ thống

### Tank - Undying Fortress
| Type | Name | Description |
|------|------|-------------|
| **Passive** | Undying Will | Hồi máu tự động: 0.5%/s khi HP > 90%, tăng dần lên 5%/s khi HP < 30% |
| **Active** | Fortify | Tăng 30% giáp + tăng hiệu quả hồi máu trong 5s. Mỗi level: +10% hiệu ứng, +0.5s duration, +0.5s CD |

### Warrior - Blood Berserker
| Type | Name | Description |
|------|------|-------------|
| **Passive** | Bloodthirst | Hút máu khi gây damage: 1% khi HP > 90%, tăng dần lên 15% khi HP < 30% |
| **Active** | Battle Fury | Tăng 30% damage + giảm 30% CD trong 10s. Mỗi level: +2.5% hiệu ứng, +0.5s duration, +0.5s CD |

### Archer - Swift Hunter
| Type | Name | Description |
|------|------|-------------|
| **Passive** | Rapid Fire | Hoàn thành combo (3_atk) tăng 10% attack speed. Max 10 stacks (200% speed) |
| **Active** | Arrow Switch | Chuyển đổi 3 loại tên (CD: 0.5s) |

## 2. Archer Arrow Types

### Normal Arrow (Tên Thường)
- **Damage**: 150% base damage
- **Effect**: Sát thương đơn target
- **Scene**: `normal_arrow.tscn`

### AOE Arrow (Tên Nổ)
- **Damage**: 80% base damage
- **Hit Enemy**: Gây nổ bán kính 80px, damage AoE cho enemies xung quanh
- **Hit Wall**: Tạo bẫy tồn tại 3s, gây 50% damage cho enemies đi qua
- **Scene**: `aoe_arrow.tscn`

### Poison Arrow (Tên Độc)
- **Damage**: 30% base damage (trực tiếp)
- **Poison DoT**: 
  - Stack 1: 10% base damage/s
  - Stack 2: 20% base damage/s
  - Stack 3-5: tối đa 50% base damage/s
  - Duration: 5s (refresh khi hit lại)
- **Scene**: `poison_arrow.tscn`

## 3. File Structure

```
Player/Scripts/
├── Abilities/
│   ├── ability_base.gd           # Base class Active
│   ├── passive_base.gd           # Base class Passive
│   ├── ability_manager.gd        # Manager
│   ├── ClassAbilities/
│   │   ├── tank_heal_ability.gd      # Tank Fortify
│   │   ├── warrior_damage_boost.gd   # Warrior Battle Fury
│   │   └── archer_piercing_shot.gd   # Archer Arrow Switch
│   └── Passives/
│       ├── tank_regeneration.gd      # Tank Undying Will
│       ├── warrior_lifesteal.gd      # Warrior Bloodthirst
│       └── archer_crit_passive.gd    # Archer Rapid Fire
├── Projectiles/
│   ├── player_projectile.gd      # Base projectile
│   ├── normal_arrow.gd           # 150% damage
│   ├── aoe_arrow.gd              # 80% + explosion/trap
│   ├── poison_arrow.gd           # 30% + DoT
│   ├── projectile_spawner.gd     # Spawner từ hitbox center
│   └── Effects/
│       ├── poison_effect.gd      # Poison DoT component
│       └── arrow_trap.gd         # Ground trap
└── States/
    ├── archer_attack_state.gd    # Archer combo attack
    └── archer_air_attack_state.gd # Archer air attack

Player/Scenes/Projectiles/
├── normal_arrow.tscn
├── aoe_arrow.tscn
├── poison_arrow.tscn
└── piercing_arrow.tscn
```

## 4. Setup Archer Scene

### Thêm nodes vào player_archer.tscn:
```
Player (root)
├── ... (existing nodes)
├── AbilityManager (Node)
│   └── Script: ability_manager.gd
├── ProjectileSpawner (Node2D)
│   └── Script: projectile_spawner.gd
│   └── use_hitbox_center = true
└── StateMachine
    └── Thay AttackState bằng ArcherAttackState
    └── Thay AirAttackState bằng ArcherAirAttackState
```

## 5. Input Actions

Thêm vào Project Settings → Input Map:
- `ability_1` → Key: Q (Arrow Switch cho Archer)

## 6. Gameplay Flow

### Archer Combo:
1. Attack (1_atk) → Spawn arrow từ hitbox center
2. Attack (2_atk) → Spawn arrow 
3. Attack (3_atk) → Spawn arrow + Trigger Rapid Fire passive (+10% speed)
4. Repeat để stack speed lên tối đa 200%

### Arrow Switching:
1. Nhấn Q để cycle: Normal → AOE → Poison → Normal
2. Arrows tiếp theo sẽ dùng type mới
3. SP_ATK (chiêu đặc biệt) vẫn dùng hitbox thường, không spawn arrow

## 7. Scaling Formulas

### Tank Fortify (Level scaling):
```
Armor Bonus = 30% + (Level - 1) * 10%
Heal Bonus = 30% + (Level - 1) * 10%
Duration = 5s + (Level - 1) * 0.5s
Cooldown = 10s + (Level - 1) * 0.5s
```

### Warrior Battle Fury (Level scaling):
```
Damage Bonus = 30% + (Level - 1) * 2.5%
CD Reduction = 30% + (Level - 1) * 2.5%
Duration = 10s + (Level - 1) * 0.5s
Cooldown = 20s + (Level - 1) * 0.5s
```

### HP-based Scaling (Tank/Warrior):
```
# Linear interpolation từ high_threshold đến low_threshold
t = (high_threshold - current_hp_ratio) / (high_threshold - low_threshold)
value = lerp(low_value, high_value, t)
```
