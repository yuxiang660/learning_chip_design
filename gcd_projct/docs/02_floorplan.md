# 步骤2: 布图规划 (Floorplan)

## 如何运行

```bash
openroad scripts/02_floorplan.tcl
```

或查看日志：
```bash
openroad scripts/02_floorplan.tcl 2>&1 | tee logs/02_floorplan.log
```

## 输入与输出

### 输入文件
| 文件 | 说明 |
|------|------|
| `results/synth.v` | 综合后的门级网表 |
| LEF文件 | 工艺和标准单元物理信息 |
| Liberty文件 | 时序库 |

### 输出文件
| 文件 | 说明 |
|------|------|
| `results/floorplan.odb` | OpenROAD数据库（含floorplan信息） |
| `results/floorplan.def` | 标准DEF格式 |
| `reports/floorplan_timing.rpt` | 时序报告 |

### 关键输出信息
```
Die area:           16.2 × 16.2 um (262.44 um²)
Core area:          15.12 × 15.12 um (228.61 um²)
Rows:               52
Utilization:        25%
Sites per row:      56
```

## 涉及的EDA概念

### 1. Floorplan（布图规划）
**定义**: 定义芯片的物理边界、核心区域、标准单元行的过程。

**目的**:
- 确定芯片尺寸
- 规划标准单元放置区域
- 预留IO pad区域
- 定义电源域

**层次结构**:
```
┌─────────────────────────────────┐
│  Die Area (芯片区域)              │
│  ┌───────────────────────────┐  │
│  │ Core Area (核心区域)       │  │
│  │                           │  │
│  │  [Standard Cell Rows]     │  │
│  │  [Standard Cell Rows]     │  │
│  │  [Standard Cell Rows]     │  │
│  │                           │  │
│  └───────────────────────────┘  │
│                                 │
└─────────────────────────────────┘
   ↑ IO Ring (IO环，可选)
```

### 2. Die vs Core Area
**Die Area（芯片面积）**:
- 整个芯片的物理边界
- 包含IO pad、seal ring等
- 决定最终制造成本

**Core Area（核心面积）**:
- 标准单元可放置区域
- 不包含IO环
- 实际逻辑电路所在区域

**关系**:
```
Core Area = Die Area - IO Ring - Margins
```

**本项目数据**:
```
Die:  16.2 × 16.2 = 262.44 um²
Core: 15.12 × 15.12 = 228.61 um²
占比: 228.61/262.44 = 87.1%
```

### 3. Utilization（利用率）
**定义**: 标准单元实际占用面积与核心区域面积的比率。

**计算公式**:
```
Utilization = (标准单元总面积) / (Core Area) × 100%
```

**典型值**:
- **10-30%**: 低密度，布线容易，时序优化空间大（适合学习/验证）
- **40-60%**: 中等密度，工业界常用
- **70-80%**: 高密度，布线拥挤，需要精细优化
- **>85%**: 极高密度，难以收敛，不推荐

**本项目**: 25% 利用率
- 优点: 布线容易，时序余量大
- 缺点: 芯片面积较大（成本高）

### 4. Standard Cell Row（标准单元行）
**定义**: 标准单元放置的水平行，具有固定高度和site结构。

**特点**:
- 固定高度（如ASAP7: 1行 = 270nm = 5个M1 track）
- 水平延伸，填满核心区域宽度
- 相邻行电源VDD/VSS交替（或共享）
- N-well和P-well在行间对齐

**结构**:
```
Row 0:  [VDD]──────────────────── (power rail)
        [P-substrate, PMOS区]
        [────── Site ──────]
        [N-substrate, NMOS区]
        [VSS]──────────────────── (ground rail)
        
Row 1:  [VSS]──────────────────── 
        [N-substrate, NMOS区]
        [────── Site ──────]
        [P-substrate, PMOS区]
        [VDD]──────────────────── (翻转放置)
```

**本项目**:
- 52行标准单元行
- 每行56个site
- Site尺寸: 270nm × 270nm

### 5. Site（放置格点）
**定义**: 标准单元放置的最小单位格点。

**特性**:
- 固定尺寸（如ASAP7: 270nm × 270nm）
- 所有标准单元宽度必须是site宽度的整数倍
- 定义了metal track的对齐

**示例**:
```
INVx1:  1个site宽
NAND2:  2个site宽
BUFx4:  4个site宽
```

### 6. LEF文件（Library Exchange Format）
**定义**: 描述工艺层和标准单元物理信息的ASCII格式文件。

**分类**:

**Technology LEF** (工艺LEF):
```lef
VERSION 5.8 ;
NAMESCASESENSITIVE ON ;
UNITS
    DATABASE MICRONS 2000 ;  # 1微米 = 2000 DBU
END UNITS

LAYER M1
    TYPE ROUTING ;
    DIRECTION VERTICAL ;      # M1垂直走线
    PITCH 0.054 ;             # track间距54nm
    WIDTH 0.018 ;             # 最小线宽18nm
    SPACING 0.018 ;           # 最小间距18nm
END M1

SITE asap7sc7p5t
    CLASS CORE ;
    SIZE 0.054 BY 0.270 ;     # site尺寸
END asap7sc7p5t
```

**Standard Cell LEF** (单元LEF):
```lef
MACRO INVx1_ASAP7_75t_R
    CLASS CORE ;
    FOREIGN INVx1_ASAP7_75t_R 0 0 ;
    ORIGIN 0 0 ;
    SIZE 0.054 BY 0.270 ;      # 1×site
    SYMMETRY X Y ;
    SITE asap7sc7p5t ;
    
    PIN A
        DIRECTION INPUT ;
        USE SIGNAL ;
        PORT
            LAYER M1 ;
            RECT 0.010 0.050 0.030 0.100 ;  # pin几何形状
        END
    END A
    
    PIN Y
        DIRECTION OUTPUT ;
        USE SIGNAL ;
        PORT
            LAYER M1 ;
            RECT 0.024 0.050 0.044 0.100 ;
        END
    END Y
    
    PIN VDD
        DIRECTION INOUT ;
        USE POWER ;
        SHAPE ABUTMENT ;          # 可拼接的电源
        PORT
            LAYER M1 ;
            RECT 0 0.260 0.054 0.270 ;
        END
    END VDD
    
    PIN VSS
        DIRECTION INOUT ;
        USE GROUND ;
        SHAPE ABUTMENT ;
        PORT
            LAYER M1 ;
            RECT 0 0 0.054 0.010 ;
        END
    END VSS
    
    OBS  # Obstruction - 禁止布线区域
        LAYER M1 ;
        RECT 0.005 0.120 0.049 0.150 ;
    END
END INVx1_ASAP7_75t_R
```

### 7. DEF文件（Design Exchange Format）
**定义**: 描述设计物理实现（布局、布线）的标准格式。

**内容结构**:
```def
VERSION 5.8 ;
DESIGN gcd ;
UNITS DISTANCE MICRONS 2000 ;

DIEAREA ( 0 0 ) ( 32400 32400 ) ;  # 16.2um × 16.2um

ROW ROW_0 asap7sc7p5t 540 540 N 
    DO 56 BY 1 STEP 270 0 ;         # 56个site，间距270nm

COMPONENTS 508 ;
    - _419_ INVx1_ASAP7_75t_R 
        + PLACED ( 1080 1350 ) N ;  # 位置和方向
    - _420_ NAND2x1_ASAP7_75t_R 
        + PLACED ( 1350 1350 ) N ;
END COMPONENTS

NETS 447 ;
    - _000_ ( _419_ Y ) ( _420_ A ) ;  # 网络连接
END NETS

END DESIGN
```

### 8. ODB（OpenROAD Database）
**定义**: OpenROAD的内部二进制数据库格式。

**特点**:
- 二进制格式（快速读写）
- 包含完整设计信息（网表+物理+时序）
- OpenROAD工具间的标准交换格式
- 支持增量更新

**与DEF对比**:
| 特性 | ODB | DEF |
|------|-----|-----|
| 格式 | 二进制 | 文本 |
| 速度 | 快 | 慢 |
| 可读性 | 需工具 | 人类可读 |
| 兼容性 | OpenROAD专用 | 工业标准 |
| 信息完整性 | 全面 | 有限 |

### 9. 核心区域计算
**给定**:
- 标准单元总面积: A_cells
- 目标利用率: U

**计算步骤**:

1. **核心面积**:
```
Core Area = A_cells / U
```

2. **核心尺寸**（假设正方形）:
```
Core Width = Core Height = √(Core Area)
```

3. **Die尺寸**（加IO环和margin）:
```
Die Width = Core Width + 2 × IO_width + 2 × margin
```

**本项目示例**:
```
A_cells = 50 um²（假设）
U = 0.25 (25%)
Core Area = 50 / 0.25 = 200 um²
但实际设置为 228.61 um² (15.12×15.12)

Die = Core + 2×margin
16.2 = 15.12 + 2×0.54
margin = 0.54um
```

### 10. 布图规划策略

**矩形核心**:
```tcl
initialize_floorplan \
    -die_area "0 0 100 150" \     # 矩形：宽100, 高150
    -core_area "10 10 90 140"
```

**Aspect Ratio（宽高比）**:
- 1:1 (正方形) - 布线距离均衡
- 2:1 或 1:2 - 适配长条形封装
- 4:1+ - 极端比例，可能导致布线不均

**本项目**: 1:1 正方形（最优布线）

## 常见问题

### Q1: 如何选择合适的utilization？
**建议**:
- **学习项目**: 20-30%（易于收敛）
- **原型验证**: 30-50%
- **量产芯片**: 50-70%（成本优化）
- **极限设计**: 70-80%（需专家级优化）

### Q2: Floorplan失败，提示core area太小？
**解决方法**:
```tcl
# 方法1: 降低utilization
set target_util 0.20  # 从0.30降到0.20

# 方法2: 手动指定更大的core
initialize_floorplan \
    -die_area "0 0 20000 20000" \
    -core_area "1000 1000 19000 19000"

# 方法3: 让工具自动计算
initialize_floorplan \
    -utilization 0.25 \
    -aspect_ratio 1.0 \
    -core_space 1.0  # 1um margin
```

### Q3: 标准单元行数量如何确定？
**计算**:
```
行高 = Site Height = 270nm (ASAP7)
核心高度 = 15.12 um = 15120 nm
行数 = 15120 / 270 ≈ 56行

但实际可能少几行（预留macro区域）
本项目: 52行
```

### Q4: 为什么需要die area和core area之间的margin？
**原因**:
1. **IO pad放置**: 如果有IO环
2. **密封环**: Seal ring防止湿气侵入
3. **切割道**: Dicing channel（晶圆切割）
4. **DRC要求**: 边缘必须有最小距离

**本项目**: 0.54um margin（2 × site width）

### Q5: 什么是DBU（Database Unit）？
**定义**: 数据库的最小坐标单位。

**示例**:
```
UNITS DISTANCE MICRONS 2000 ;
表示: 1微米 = 2000 DBU
因此: 1 DBU = 1/2000 um = 0.5 nm

坐标 (32400, 32400) DBU 
= (32400/2000, 32400/2000) um 
= (16.2, 16.2) um
```

## 验证检查清单

Floorplan完成后，检查：

- [ ] Die area和core area已定义
- [ ] 核心区域在die内部
- [ ] Utilization在合理范围(20-80%)
- [ ] 标准单元行已创建（ROW定义存在）
- [ ] 行数匹配计算值（±几行正常）
- [ ] ODB/DEF文件已生成
- [ ] 可用OpenROAD GUI查看
- [ ] 无DRC错误（overlap等）

## 相关命令参考

### 初始化Floorplan
```tcl
# 方法1: 自动计算（推荐）
initialize_floorplan \
    -utilization 0.30 \
    -aspect_ratio 1.0 \
    -core_space 2.0

# 方法2: 手动指定坐标
initialize_floorplan \
    -die_area "0 0 100 100" \
    -core_area "5 5 95 95"

# 方法3: 指定行列
initialize_floorplan \
    -utilization 0.40 \
    -aspect_ratio 1.0 \
    -core_space 1.0 \
    -site asap7sc7p5t
```

### 插入标准单元行
```tcl
# 自动插入（initialize_floorplan已包含）
make_tracks

# 或手动定义行
make_row ROW_0 asap7sc7p5t \
    540 540 N \           # 起始位置(x,y)和方向
    do 56 by 1 \          # 56列, 1行
    step 270 0            # 水平间距270nm
```

### 查看Floorplan信息
```tcl
# 报告die和core面积
report_design_area

# 查看行信息
set rows [ord::get_db_rows]
puts "Total rows: [llength $rows]"
```

### 可视化
```bash
# GUI查看
openroad -gui results/floorplan.odb

# 在GUI中:
# - 按 'f' 键适应视图
# - 鼠标滚轮缩放
# - 右键菜单选择显示内容
```

## 下一步

Floorplan完成后，进入 **Tapcell插入** 阶段：
→ 参见: [03_tapcell.md](03_tapcell.md)
