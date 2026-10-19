class_name Tuning
const TILE := 16
const BASE_SIZE := Vector2i(320, 180)
# 移动
const RUN_SPEED := 120.0
const GROUND_ACCEL := 900.0
const GROUND_DECEL := 1200.0      # 松手刹停、反向输入都用这个
const AIR_ACCEL := 600.0
const AIR_DECEL := 400.0
# 跳跃
const JUMP_VELOCITY := -300.0
const GRAVITY_UP := 900.0         # vy < 0
const GRAVITY_DOWN := 1300.0      # vy >= 0
const MAX_FALL_SPEED := 320.0
const JUMP_CUT := 0.5             # 上升中松开 jump：vy *= 0.5，每次跳只触发一次
const COYOTE_TIME := 0.10
const JUMP_BUFFER := 0.10
const CORNER_CORRECTION := 4      # 顶头重叠 ≤ 4 px 时水平推开
const DROP_THROUGH_TIME := 0.2
# 敌人
const WALKER_SPEED := 30.0
const SPIKY_SPEED := 24.0
const ENEMY_GRAVITY := 1300.0
const ENEMY_MAX_FALL := 320.0
const ENEMY_GROUND_PROBE := Vector2(8, 2)   # (facing*8, +2) 处向下 4px
const ENEMY_GROUND_PROBE_LEN := 4.0
# 踩踏
const STOMP_TOLERANCE := 6.0      # 玩家脚底 y <= 敌人碰撞顶 y + 6，且玩家 vy > 0
const STOMP_BOUNCE := -220.0
const STOMP_BOUNCE_HELD := -300.0
const STOMP_PITCH_STEP := 1.0595
const WALKER_SQUASH_TIME := 0.4
const SPIKY_BOUNCE := -200.0      # 踩 Spiky：受伤并被弹起
# 受伤
const MAX_HP := 3
const START_LIVES := 3
const KNOCKBACK := Vector2(140, -160)   # x 方向远离伤害源
const HURT_LOCK := 0.25
const IFRAMES := 1.0
const IFRAME_BLINK := 0.08
const HURT_FLASH := 0.1
# 死亡 / 过关
const DEATH_POP_VY := -260.0      # 之后只受 GRAVITY_UP 影响
const DEATH_FADE_AT := 1.0
const DEATH_FADE := 0.35
const PIT_MARGIN := 16            # 玩家 y > limit_bottom + 16 (=208) → 死亡
const FLAG_RAISE := 0.6
const COMPLETE_PANEL_DELAY := 0.8
const JINGLE_DELAY := 0.2
# 重生
const RESPAWN_IFRAMES := 1.0       # §9.6: 重生无敌 1.0 s（复用受击闪烁节奏）
# 相机
const CAMERA_SMOOTHING := true
const CAMERA_SMOOTHING_SPEED := 7.0
const CAMERA_Y_OFFSET := -16
const LOOK_AHEAD := 24.0
const LOOK_AHEAD_MIN_VX := 60.0
const LOOK_AHEAD_RATE := 4.0      # look_ahead = lerp(look_ahead, target, 1 - exp(-4*dt))
const DRAG_LR := 0.10
const DRAG_TOP := 0.30
const DRAG_BOTTOM := 0.10
# 震屏 / hitstop（振幅 px, 时长 s, hitstop s）
const SHAKE_STOMP := [2, 0.12, 0.05]
const SHAKE_HURT := [3, 0.20, 0.08]
const SHAKE_DEATH := [5, 0.30, 0.12]
const SHAKE_HARD_LAND := [1, 0.08, 0.0]   # 下落速度 >= 300
const HITSTOP_TIME_SCALE := 0.05
const SHAKE_RESAMPLE := 1.0 / 30.0
# 金币
const COIN_RISE := 10.0
const COIN_RISE_TIME := 0.25
const COIN_FADE_TIME := 0.15
const COIN_BOB_AMPL := 1
const COIN_BOB_PERIOD := 1.2       # 相位 = c * 0.3，结果取整
const COIN_PITCH_STEP := 0.05
const COIN_PITCH_MAX := 1.3
const COIN_PITCH_WINDOW := 0.5
# 动画阈值
const ANIM_JUMP_VY := -40.0        # vy < -40 → jump 帧；vy > 40 → fall 帧；中间用 jump
const ANIM_FALL_VY := 40.0
const DUST_MIN_VX := 100.0
const LAND_PUFF_MIN_VY := 200.0
# UI
const MENU_INPUT_GRACE := 0.25
const RESULT_INPUT_GRACE := 0.6    # Game Over、关卡完成
const FADE_TIME := 0.3
