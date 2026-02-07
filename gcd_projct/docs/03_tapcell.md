# 步骤3: Tapcell插入 (Well Tap Insertion)

## 如何运行

```bash
cd /home/yuxiangw/github/learning_chip_design/gcd_projct
openroad scripts/03_tapcell.tcl
```

或查看日志：
```bash
openroad scripts/03_tapcell.tcl 2>&1 | tee logs/03_tapcell.log
```

## 输入与输出

### 输入文件
| 文件 | 说明 |
|------|------|
| `results/floorplan.odb` | Floorplan后的数据库 |
| LEF文件 | 包含TAP单元定义 |

### 输出文件
| 文件 | 说明 |
|------|------|
| `results/tapcell.odb` | 插入tapcell后的数据库 |
| `results/tapcell.def` | DEF格式 |

### 关键输出信息
```
Inserted 8 tapcells (TAP_ASAP7_75t_R)
Distance: 25 sites (6.75 um)
```

## 涉及的EDA概念

### 1. Well Tap Cell（阱接触单元）
**定义**: 将N-well和P-substrate连接到电源的特殊标准单元。

**物理结构**:
```
VDD ────────────────────────────── (顶部电源轨)
        ┌──────────┐
        │ N+ 接触  │ ← 连接N-well到VDD
        ├──────────┤
        │ N-well   │
        ├──────────┤
        │ P-sub    │
        ├──────────┤
        │ P+ 接触  │ ← 连接P-substrate到VSS
        └──────────┘
VSS ────────────────────────────── (底部地轨)
```

**作用**:
1. **电源连接**: 为N-well(VDD)和P-substrate(VSS)提供欧姆接触
2. **防止闩锁**: 降低阱电阻，避免寄生PNPN晶闸管导通
3. **噪声抑制**: 稳定衬底电压，减少substrate noise

### 2. 闩锁效应 (Latchup)
**定义**: CMOS电路中寄生PNPN结构被触发导通，形成低阻通路的现象。

**原理**:
在CMOS工艺中，N-well中的PMOS和P-substrate中的NMOS会形成寄生的4层结构：

```
VDD
 │
PMOS (in N-well)
 │
N-well ──────┐ 寄生PNP
 │           │
P-sub ───┐   │
 │       │   │
NMOS     │   │ 寄生NPN
 │       │   │
VSS      └───┘
         闩锁路径
```

**触发条件**:
1. 电源或地过冲/下冲
2. 输入信号超出VDD/VSS范围
3. 衬底电流过大（如ESD、α粒子）

**后果**:
- 大电流从VDD流向VSS（可达几安培）
- 芯片功能失效
- 严重时烧毁芯片

**防止方法**:
1. **Well Tap**: 降低阱电阻（最主要）
2. **Guard Ring**: 隔离敏感电路
3. **合理间距**: 减小寄生晶体管增益
4. **ESD保护**: 钳位输入电压

### 3. Tapcell插入规则

**最大距离规则**:
```
DRC要求: 任何N-well/P-sub点到最近tap的距离 < D_max

典型值:
- 65nm: D_max ≈ 30-50 um
- 28nm: D_max ≈ 15-20 um  
- 7nm:  D_max ≈ 5-10 um (更严格)
```

**ASAP7项目**:
```
TAP间距: 25 sites = 25 × 270nm = 6.75 um
保守设计，远小于最大允许距离
```

**插入策略**:

**方法1: 周期性插入**（本项目采用）
```tcl
tapcell \
    -tapcell_master TAP_ASAP7_75t_R \
    -distance 25  # 每25个site插入一个
```

**方法2: Checkerboard（棋盘式）**
```tcl
tapcell \
    -tapcell_master TAP_ASAP7_75t_R \
    -halo_width_x 10 \
    -halo_width_y 10
```

**方法3: 手动放置**
```tcl
# 在特定位置插入
place_cell -inst TAP_0 -cell TAP_ASAP7_75t_R \
    -origin {5.0 10.0}
```

### 4. TAP单元结构

**LEF定义**:
```lef
MACRO TAP_ASAP7_75t_R
    CLASS CORE WELLTAP ;      # 标记为well tap类型
    SIZE 0.054 BY 0.270 ;     # 1×site
    SYMMETRY X Y ;
    
    PIN VDD
        DIRECTION INOUT ;
        USE POWER ;
        PORT
            LAYER M1 ;
            RECT 0 0.260 0.054 0.270 ;
            # N+ diffusion (隐含)
        END
    END VDD
    
    PIN VSS
        DIRECTION INOUT ;
        USE GROUND ;
        PORT
            LAYER M1 ;
            RECT 0 0 0.054 0.010 ;
            # P+ diffusion (隐含)
        END
    END VSS
    
    # 没有信号pin，只有电源pin
END TAP_ASAP7_75t_R
```

**与标准单元对比**:
| 特性 | 标准单元 | TAP单元 |
|------|---------|---------|
| 信号Pin | 有 | 无 |
| 电源Pin | 有 | 有 |
| 逻辑功能 | 有 | 无 |
| 内部晶体管 | 有 | 无 |
| Diffusion | Active | Tap only |

### 5. Substrate Noise（衬底噪声）
**定义**: 通过衬底传播的电气干扰。

**来源**:
1. **数字开关**: 大量单元同时翻转
2. **时钟缓冲**: 高频大电流
3. **电源完整性**: di/dt引起地弹
4. **耦合**: 相邻电路通过substrate耦合

**影响**:
- **模拟电路**: 降低ADC/DAC精度
- **RF电路**: 增加相位噪声
- **PLL**: 抖动增大

**TAP的作用**:
- 提供低阻抗路径到VSS/VDD
- 固定衬底电压
- 隔离不同区域

### 6. Well结构

**CMOS工艺的Well**:

**N-well** (用于PMOS):
```
VDD ─── [N+ tap] ─────────────
        │
        │  N-well (浅掺杂)
        │
        ├── PMOS source/drain (P+)
        │
────────┴──────────────────────
      P-substrate
```

**Twin-well**:
- N-well: 放置PMOS
- P-well: 放置NMOS（在N型衬底上）

**Triple-well**:
- Deep N-well隔离敏感电路（如模拟）

**ASAP7**: 使用N-well in P-substrate

### 7. 寄生电阻
**Well电阻**:
```
R_well = ρ × L / A

ρ: 电阻率（N-well: ~1-10 Ω·cm）
L: 电流路径长度
A: 横截面积
```

**没有TAP时**:
```
Distance to tap = 50 um
R_well ≈ 1kΩ - 10kΩ (高阻抗！)
```

**有TAP时**:
```
Distance to tap = 5 um
R_well ≈ 100Ω - 1kΩ (低很多)
```

**低阻的好处**:
- 快速泄放瞬态电流
- 减小电压降
- 抑制闩锁

### 8. DRC规则示例

**工艺规则**:
```
# N-well最大无tap区域
NWELL.MAX_TAP_DISTANCE = 10 um

# TAP单元最小间距
TAP.SPACING = 0.5 um

# Well edge到tap的距离
NWELL.EDGE_TO_TAP < 5 um
```

**检查方法**:
```bash
# 使用Calibre或Magic检查
calibre -drc tap_check.rule gcd.gds

# 或在OpenROAD中
check_placement -verbose
```

## 常见问题

### Q1: 不插入tapcell会怎样？
**短期**:
- 小设计、低频可能正常工作
- 仿真看不出问题（没有衬底模型）

**长期/生产**:
- 可靠性问题（随机失效）
- 无法通过DRC检查
- 不能tape-out

### Q2: TAP间距如何选择？
**考虑因素**:
```
间距小 → 更好防护，但面积开销大
间距大 → 省面积，但风险高

推荐:
- 保守: 5-10 um
- 平衡: 10-20 um  
- 激进: 20-30 um (需验证)
```

**本项目**: 6.75um（非常保守）

### Q3: TAP会影响布线吗？
**答案**: 会，但影响小

**占用资源**:
- 面积: 1×site per TAP
- M1轨道: 部分阻挡
- 布线: 需要绕开

**优化**:
- TAP通常放在行的两端
- 与endcap共用
- 面积开销 < 1%

### Q4: 不同工艺的TAP要求？
| 工艺节点 | 典型间距 | 严格程度 |
|---------|---------|---------|
| 180nm   | 50 um   | 宽松 |
| 65nm    | 20-30 um | 中等 |
| 28nm    | 10-15 um | 严格 |
| 7nm     | 5-10 um  | 非常严格 |
| 3nm     | <5 um    | 极严格 |

### Q5: TAP和Endcap的区别？
**TAP Cell**:
- 连接well到电源
- 防闩锁
- 可以在行中间

**Endcap Cell**:
- 行的两端
- N-well终结
- 防止DRC违例
- 通常也包含TAP功能

**组合使用**:
```tcl
# 先插入endcap（行端）
tapcell -endcap_master ENDCAP_ASAP7_75t_R

# 再插入中间的tap
tapcell -tapcell_master TAP_ASAP7_75t_R -distance 25
```

## 验证检查清单

Tapcell插入后，检查：

- [ ] TAP单元已插入（数量>0）
- [ ] TAP分布均匀（可视化检查）
- [ ] 符合最大距离规则
- [ ] 未与标准单元重叠
- [ ] 电源连接正确（VDD/VSS）
- [ ] ODB文件已更新
- [ ] Placement仍然合法

## 相关命令参考

### 插入Tapcell
```tcl
# 基本用法
tapcell \
    -tapcell_master TAP_ASAP7_75t_R \
    -distance 25

# 同时插入endcap
tapcell \
    -endcap_master ENDCAP_ASAP7_75t_R \
    -tapcell_master TAP_ASAP7_75t_R \
    -distance 20

# 指定特定区域
tapcell \
    -tapcell_master TAP_ASAP7_75t_R \
    -distance 25 \
    -area {10 10 90 90}  # 只在此区域插入
```

### 查看TAP信息
```tcl
# 统计TAP数量
set taps [get_cells -hierarchical TAP_*]
puts "Total tapcells: [llength $taps]"

# 查看位置
foreach tap $taps {
    set bbox [get_property $tap bbox]
    puts "$tap at $bbox"
}
```

### 可视化检查
```bash
# 在GUI中查看
openroad -gui results/tapcell.odb

# 在GUI中:
# View -> Show -> Instances -> 选择 WELLTAP
```

### 删除TAP（如需重新插入）
```tcl
# 删除所有TAP
delete_cell [get_cells TAP_*]

# 或删除特定类型
delete_cell -of [get_cells -filter "ref_name == TAP_ASAP7_75t_R"]
```

## 下一步

Tapcell插入完成后，进入 **电源分配网络 (PDN)** 阶段：
→ 参见: [04_pdn.md](04_pdn.md)
