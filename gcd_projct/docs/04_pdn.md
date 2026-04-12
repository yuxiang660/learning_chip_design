# 步骤4: 电源分配网络 (Power Distribution Network, PDN)

## 如何运行

```bash
openroad scripts/04_pdn.tcl
```

或查看日志：
```bash
openroad scripts/04_pdn.tcl 2>&1 | tee logs/04_pdn.log
```

## 输入与输出

### 输入文件
| 文件 | 说明 |
|------|------|
| `results/tapcell.odb` | 插入tapcell后的数据库 |
| PDN配置 | 电源网络拓扑定义 |

### 输出文件
| 文件 | 说明 |
|------|------|
| `results/pdn.odb` | 包含PDN的数据库 |
| `results/pdn.def` | DEF格式 |

### 关键输出信息
```
Power nets: VDD, VSS
Grid layers: M2 (stripes), M5 (stripes), M7 (trunk)
Stripe pitch: 7.56um (M2), 15.12um (M5)
Width: 0.072um (M2), 0.144um (M5)
```

## 涉及的EDA概念

### 1. 电源分配网络 (PDN)
**定义**: 将电源从外部pad分配到芯片内所有标准单元的金属网络。

**目标**:
- 低阻抗路径（减小IR drop）
- 充足电流容量
- 低电感（减小Ldi/dt噪声）
- 均匀分布（每个单元都能获得稳定电源）

**拓扑结构**:
```
External Pads (C4 bumps / Wire bonds)
    ↓
Top Metal (M7-M9) - Global Grid/Trunk
    ↓
Middle Metal (M4-M6) - Stripes/Rings  
    ↓
Lower Metal (M2-M3) - Local Distribution
    ↓
M1 Rails - Standard Cell Power
```

### 2. 分层PDN结构

**三层结构**（本项目）:

**Layer 1: M1 Rails** (标准单元电源轨)
```
Row 0: [VDD]──[cell]──[cell]──[cell]──[VSS]
Row 1: [VSS]──[cell]──[cell]──[cell]──[VDD] (翻转)
Row 2: [VDD]──[cell]──[cell]──[cell]──[VSS]
```
- 宽度: ~50nm
- 间距: 行高(270nm)
- 电流: 每单元 µA级

**Layer 2: M2/M3 Stripes** (局部分配)
```
    │ M2 │ M2 │ M2 │ M2 │  (垂直条纹)
    VDD  VSS  VDD  VSS
    
─────────────────────────  M3横向(可选)
```
- 宽度: 72nm (M2)
- 间距: 7.56um
- 电流: 几十mA per stripe

**Layer 3: M5/M7 Grid** (全局分配)
```
M7横向 ═══════════════════════ VDD trunk
       ║         ║         ║
M5纵向 ║ M5 VDD  ║ M5 VSS  ║
       ║         ║         ║
M7横向 ═══════════════════════ VSS trunk
```
- 宽度: 144nm+ (M5), 更宽(M7)
- 间距: 15.12um+
- 电流: 数百mA per trunk

### 3. IR Drop（欧姆压降）
**定义**: 电流流过电源网络电阻导致的电压降低。

**公式**:
```
V_drop = I × R

R = ρ × L / (W × T)
  ρ: 金属电阻率
  L: 电流路径长度
  W: 金属宽度
  T: 金属厚度
```

**影响**:
```
理想VDD = 0.7V
实际V_cell = 0.7V - IR_drop

IR_drop过大 → 单元速度变慢 → 时序违例
IR_drop过大 → 功能失效
```

**典型规范**:
- **良好**: IR drop < 5% VDD (< 35mV @ 0.7V)
- **可接受**: IR drop < 10% VDD (< 70mV)
- **危险**: IR drop > 10% VDD

**优化方法**:
1. 加宽金属线
2. 使用更多金属层
3. 减小stripe间距
4. 使用更粗的trunk

### 4. Ldi/dt噪声
**定义**: 电流快速变化时，电源网络电感引起的电压波动。

**公式**:
```
V_noise = L × di/dt

L: 电源网络电感
di/dt: 电流变化率
```

**产生原因**:
- 大量门同时翻转（时钟边沿）
- 总线驱动
- IO切换

**影响**:
```
VDD_actual = VDD_ideal - L × di/dt

瞬态噪声 → 逻辑故障
地弹(Ground Bounce) → 误触发
电源弹(Power Bounce) → 时序抖动
```

**降低方法**:
1. 使用网格结构（降低电感）
2. 去耦电容（decap）吸收瞬态电流
3. 多层PDN（并联降低等效电感）
4. 分散时钟树（避免同时翻转）

### 5. PDN拓扑类型

**类型1: Ring（环形）**
```
┌─────────────────────┐
│ VDD Ring            │
│  ┌───────────────┐  │
│  │ Core Area     │  │
│  │               │  │
│  └───────────────┘  │
│ VSS Ring            │
└─────────────────────┘
```
- 优点: 低电阻，均匀分配
- 缺点: 占用较多routing资源

**类型2: Stripes（条纹）**
```
│ │ │ │ │ │ │ │
V V V V V V V V
D S D S D S D S
D S D S D S D S
│ │ │ │ │ │ │ │
```
- 优点: 简单，容易实现
- 缺点: 边缘电阻较大

**类型3: Grid/Mesh（网格）** ← 本项目
```
═══╬═══╬═══╬═══  M7横向
   ║   ║   ║
───╫───╫───╫───  M5纵向
   ║   ║   ║
═══╬═══╬═══╬═══  M7横向
```
- 优点: 最低阻抗和电感，冗余路径
- 缺点: 复杂，多层金属

### 6. Via Array（通孔阵列）
**定义**: 连接不同金属层的通孔群。

**为什么需要多个via**:
```
单个via电阻: ~5-10Ω
电流容量: ~0.5mA

需要100mA → 需要200个via!
```

**Via array示例**:
```
M2层:  ████████████
       ┊┊┊┊┊┊┊┊┊┊┊┊  Via阵列 (5×5 = 25个)
M1层:  ████████████
```

**PDN中via数量**:
```
M1→M2: 每个intersection ~10-50 vias
M2→M3: ~20-100 vias  
M5→M7: ~50-200 vias (更大电流)
```

### 7. 金属层特性

**不同金属层对比**:
| 层 | 方向 | 宽度 | 厚度 | 电阻(Ω/□) | 用途 |
|----|------|------|------|-----------|------|
| M1 | V | 18nm | 36nm | ~50 | Cell rails |
| M2 | H | 18nm | 36nm | ~50 | Local routing |
| M3 | V | 18nm | 36nm | ~50 | Local routing |
| M4 | H | 36nm | 72nm | ~15 | Power stripes |
| M5 | V | 72nm | 144nm | ~5 | Power grid |
| M7 | H | 288nm | 576nm | ~1 | Power trunk |

**趋势**: 
- 上层金属更宽更厚 → 低电阻
- 用于长距离、大电流传输

### 8. Decoupling Capacitor（去耦电容）
**定义**: 放置在芯片中用于稳定电源的电容。

**作用机理**:
```
快速翻转时:
  单元需要突发电流 → Decap提供
  
  Decap充当本地"电池"
  ┌──C──┐
  │     │
VDD    VSS

响应速度: pico秒级
PDN响应:   nano秒级
```

**类型**:

**Explicit Decap**:
```verilog
// 专用decap单元
DCAP_ASAP7_75t_R decap_0 (.VDD(VDD), .VSS(VSS));
DCAP_ASAP7_75t_R decap_1 (.VDD(VDD), .VSS(VSS));
```

**Implicit Decap**:
- 标准单元的寄生电容
- Filler cell的gate电容
- 未使用晶体管的gate

**插入策略**:
```tcl
# 在filler阶段自动插入
filler_placement \
    -decap_cell DCAP_ASAP7_75t_R \
    -prefix DECAP_
```

### 9. PDN设计规则

**Metal Width规则**:
```
I_max = W × J_max

J_max: 电流密度限制 (~1-2 mA/um for Cu)
W: 金属宽度

例: 需要100mA电流
W = 100mA / 1mA/um = 100um宽！
→ 用多条stripe并联
```

**Minimum Spacing**:
```
不同电源网络必须保持最小间距
VDD stripe <---> VSS stripe: ≥ 2× min spacing
防止短路
```

**Via Redundancy**:
```
关键路径: 至少2×计算所需via数
冗余 → 可靠性
```

### 10. PDN验证

**IR Drop分析**:
```tcl
# OpenROAD中
analyze_power_grid \
    -net VDD \
    -voltage 0.7 \
    -current_map current.map

# 输出: IR drop热图
# 红色区域 → 高IR drop → 需优化
```

**EM (Electromigration)检查**:
```
长期大电流 → 金属原子迁移 → 断线

J < J_max (电流密度限制)

J_max(Cu): ~1-2 mA/um² @ 85°C
```

**Short检查**:
```
DRC验证:
- VDD和VSS无短路
- 满足间距规则
- Via充分
```

## 常见问题

### Q1: PDN占用多少芯片面积？
**答案**: 不占placement面积，但占routing资源

**资源占用**:
- M1: ~20% (power rails)
- M2-M3: ~5-10% (stripes)
- M5-M7: ~10-20% (grid)

**对布线影响**:
- 信号布线需绕过power stripes
- 但多层金属足够用

### Q2: 如何选择stripe宽度和间距？
**经验公式**:
```
Stripe pitch ≈ √(芯片面积) / 10

16.2um × 16.2um 芯片:
pitch ≈ 16.2 / 10 ≈ 1.6um

但我们用7.56um (更保守)
```

**宽度选择**:
```
W_min = I_total / (J_max × n_stripes)

假设:
- 总电流: 10mA
- J_max: 1mA/um
- 10条stripes

W_min = 10 / (1 × 10) = 1um
安全系数2× → 用2um

但ASAP7最小线宽限制 → 实际用0.072um
需要更多stripes补偿
```

### Q3: IR drop过大怎么优化？
**方法**:

1. **加宽stripe**:
```tcl
add_pdn_stripe -layer M2 -width 0.144  # 从0.072加倍
```

2. **减小间距**:
```tcl
add_pdn_stripe -layer M2 -pitch 3.78  # 从7.56减半
```

3. **增加层数**:
```tcl
add_pdn_stripe -layer M4 ...  # 新增M4 stripes
```

4. **优化placement**:
- 高功耗模块靠近power trunk
- 分散功耗热点

### Q4: PDN生成失败怎么办？
**常见错误**:

**Error 1: Layer not found**
```
解决: 检查LEF是否定义了ROUTING层
```

**Error 2: Width violates min/max**
```tcl
# 查询LEF中的限制
grep "WIDTH" tech.lef

# 调整到合法值
add_pdn_stripe -width 0.072  # 符合LEF规则
```

**Error 3: Grid not aligned**
```tcl
# 确保offset是track pitch的倍数
add_pdn_stripe \
    -offset [expr 0.054 * 10]  # 10× M1 pitch
```

### Q5: 需要几层金属做PDN？
**最少**: 2层 (M1+M2)
- 小设计(< 1mm²)
- 低功耗(< 10mW)

**推荐**: 3-4层 (M1+M2+M5+M7)
- 中等设计
- 本项目采用

**复杂**: 5+层
- 大芯片(> 100mm²)
- 高功耗(> 1W)
- 多电压域

## 验证检查清单

PDN完成后，检查：

- [ ] VDD和VSS网络都已创建
- [ ] M1 rails连接到标准单元
- [ ] Stripes和grid已生成
- [ ] Via arrays连接各层
- [ ] 无DRC违例（spacing, width）
- [ ] IR drop < 10% VDD（理想<5%）
- [ ] 无VDD-VSS短路
- [ ] DEF/ODB已保存

## 相关命令参考

### PDN基本配置
```tcl
# 定义电源网络
add_global_connection -net VDD -pin_pattern {^VDD$} -power
add_global_connection -net VSS -pin_pattern {^VSS$} -ground

# 定义电压域
set_voltage_domain -power VDD -ground VSS
```

### 创建Grid
```tcl
# M1 standard cell rails (自动)
define_pdn_grid -name "Core"

# M2 stripes (垂直)
add_pdn_stripe \
    -layer M2 \
    -width 0.072 \
    -pitch 7.56 \
    -offset 0.54 \
    -followpins

# M5 stripes (横向)
add_pdn_stripe \
    -layer M5 \
    -width 0.144 \
    -pitch 15.12 \
    -offset 1.08

# M7 trunk (横向)
add_pdn_stripe \
    -layer M7 \
    -width 0.288 \
    -pitch 30.24
```

### 连接各层
```tcl
# M1 → M2
add_pdn_connect -layers {M1 M2}

# M2 → M5
add_pdn_connect -layers {M2 M5}

# M5 → M7
add_pdn_connect -layers {M5 M7}
```

### PDN生成
```tcl
# 执行PDN生成
pdngen
```

### 分析IR Drop
```tcl
# 读取功耗信息(可选)
read_power_activities activities.vcd

# 分析
analyze_power_grid \
    -net VDD \
    -voltage 0.7 \
    -output ir_drop.rpt
```

### 可视化
```bash
# GUI查看PDN
openroad -gui results/pdn.odb

# 在GUI中:
# View -> Layers -> 选择 M2, M5, M7
# 红色: VDD, 蓝色: VSS
```

## 下一步

PDN完成后，进入 **全局布局 (Global Placement)** 阶段：
→ 参见: [05_global_placement.md](05_global_placement.md)
