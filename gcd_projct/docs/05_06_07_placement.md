# 步骤5-7: 布局阶段 (Placement)

本文档涵盖三个相关步骤：全局布局、IO布局、详细布局

## 如何运行

```bash
# 步骤5: 全局布局
openroad scripts/05_global_place_skip_io.tcl

# 步骤6: IO布局（修复版）
openroad scripts/06_io_place_fixed.tcl

# 步骤7: 详细布局（修复版）
openroad scripts/07_detail_place_fixed.tcl
```

## 输入与输出

### 步骤5: 全局布局
**输入**: `results/pdn.odb`  
**输出**: `results/global_place_skip_io.odb`

### 步骤6: IO布局
**输入**: `results/global_place_skip_io.odb`  
**输出**: `results/io_place_fixed.odb` (56个IO pins,所有BPins已创建)

### 步骤7: 详细布局
**输入**: `results/io_place_fixed.odb`  
**输出**: `results/detail_place_fixed.odb` (508/508单元合法化)

## 涉及的EDA概念

### 1. Placement（布局）概述
**定义**: 确定标准单元在芯片核心区域中具体位置的过程。

**层次**:
```
Floorplan → 定义边界和行
    ↓
Global Placement → 粗略位置（可重叠）
    ↓
Detailed Placement → 精确位置（合法化）
```

**优化目标**:
- **HPWL**: Half-Perimeter Wire Length（线长）
- **Timing**: 关键路径延迟
- **Congestion**: 布线拥挤度
- **Power**: 功耗

### 2. Global Placement（全局布局）
**定义**: 将单元放置到大致位置，允许重叠，主要优化线长。

**算法**: 
- **RePlAce** (OpenROAD的全局布局器)
- 基于解析布局（Analytical Placement）
- 使用非线性优化

**特点**:
- **快速**: 利用GPU加速
- **允许重叠**: 多个单元可能占据同一site
- **优化HPWL**: 最小化半周长线长

**HPWL计算**:
```
对于一个net连接的所有pin:
HPWL = |X_max - X_min| + |Y_max - Y_min|

例如:
Net A连接3个pin: (0,0), (10,5), (8,12)
X: 0 to 10 → 10
Y: 0 to 12 → 12
HPWL = 10 + 12 = 22
```

**输出信息**:
```
Initial HPWL: 5234.0 um
Final HPWL:   3156.0 um
Improvement:  39.7%
Density:      0.35 (目标0.25，允许膨胀)
Overflow:     15% (单元重叠程度)
```

### 3. Legalization（合法化）
**定义**: 将重叠的单元调整到合法site上，消除所有重叠。

**约束**:
1. **行对齐**: 单元必须在标准单元行上
2. **Site对齐**: X坐标必须是site宽度的整数倍
3. **无重叠**: 单元之间不能重叠
4. **方向**: 遵循行的放置方向(N或FN)

**示例**:
```
Before Legalization:
Row 0: [    cell1 overlaps cell2    ]
        ^^^^^^^^^^^^^
        重叠区域

After Legalization:
Row 0: [cell1][gap][cell2][  empty  ]
        ^         ^
      moved    separated
```

**指标**:
```
Total displacement: 77.8 um (所有单元移动距离总和)
Average displacement: 0.15 um per cell
Max displacement: 2.34 um
HPWL delta: +6% (相对global placement)
```

### 4. Detailed Placement（详细布局）
**定义**: 在合法位置基础上，通过局部优化进一步改善QoR。

**操作**:
1. **Cell swapping**: 交换相邻单元
2. **Re-ordering**: 重新排序一行内的单元
3. **Vertical移动**: 单元移到相邻行
4. **Gate sizing**: 改变单元驱动强度(可选)

**算法**:
- Window-based optimization（窗口优化）
- 每次优化几个到几十个单元
- 迭代直到收敛

**本项目结果**:
```
[INFO DPL-0001] Placed 508 instances
[INFO DPL-0002]   Average displacement 0.2 um
[INFO DPL-0003]   HPWL = 3347.0 um
[INFO DPL-0004]   All instances placed
```

### 5. IO Placement（IO布局）
**定义**: 确定芯片输入/输出引脚在die边缘的位置。

**策略**:

**Uniform Distribution（均匀分布）**: 
```tcl
place_pins -hor_layers M5 -ver_layers M4 \
    -random  # 或 -uniform
```

**Constraint-based（约束驱动）**:
```tcl
# 指定某些IO在特定边
set_io_pin_constraint -pin_names {clk rst} \
    -region bottom:* \
    -spacing 5.0
```

**本项目**: 均匀分布在die四边

### 6. BPin (Boundary Pin)
**定义**: IO pad的物理几何形状（金属shape）。

**重要性**: 
- **没有BPin** → 后续详细布局失败！
- BPin是详细布局的hard obstacle
- 布线需要从BPin位置连接

**BPin vs BTerm**:
```
BTerm (逻辑端口)
    ↓ 需要几何shape
BPin (物理形状，在特定metal layer上的矩形)
```

**检查BPin**:
```tcl
foreach pin [get_bterms *] {
    set bpin_count [llength [$pin getBPins]]
    if {$bpin_count == 0} {
        puts "ERROR: Pin [$pin getName] has no BPin!"
    }
}
```

**本项目修复**:
原始io_place.tcl没有正确创建BPin →  
使用io_place_fixed.tcl直接调用place_pins → 所有56 pins有BPin ✅

### 7. 密度 (Density)
**定义**: 局部区域内单元占用面积的比率。

**全局密度**:
```
Global Density = 总单元面积 / Core Area
              = Utilization
```

**局部密度**:
```
将芯片分成bin（如100×100的网格）
每个bin的density = bin内单元面积 / bin面积

高密度bin → 可能拥挤 → 布线困难
```

**Global Placement中的密度控制**:
```tcl
global_placement \
    -density 0.35  # 允许局部密度达35%
                   # 即使全局utilization只有25%

目的: 预留布线空间
```

### 8. Displacement（位移）
**定义**: 单元从初始位置到最终位置的距离。

**计算**:
```
Displacement = |X_final - X_initial| + |Y_final - Y_initial|

Manhattan距离
```

**意义**:
- **小位移**: placement质量好，优化器没怎么移动
- **大位移**: 可能有问题（如timing-driven狂拉）

**本项目**:
```
Average displacement: 0.2 um
(很小，说明global placement质量高)
```

### 9. 布局质量指标

**HPWL (Half-Perimeter Wire Length)**:
```
越小越好
但不是唯一目标（还有timing, congestion）
```

**Overflow**:
```
Global placement中单元重叠的程度
0% = 完全合法（不常见）
< 5% = 优秀
< 15% = 良好
> 20% = 可能有拥挤问题
```

**Timing**:
```
WNS (Worst Negative Slack): 最坏负时序余量
TNS (Total Negative Slack): 总负时序余量

理想: WNS > 0, TNS = 0
可接受: WNS小量负值（后续可优化）
```

**Routing Congestion**:
```
预测布线资源使用率
> 90% → 可能无法布通
< 80% → 安全
```

### 10. Placement约束

**Blockage（阻挡）**:
```tcl
# 禁止某区域放置
create_placement_blockage \
    -area {10 10 20 20}  # 矩形区域

# 部分阻挡（允许50%密度）
create_placement_blockage \
    -area {30 30 40 40} \
    -partial 0.5
```

**Region Constraint**:
```tcl
# 限制特定模块在某区域
create_region region1 {5 5 15 15}
assign_cells_to_region region1 [get_cells mem_*]
```

**Halo**:
```tcl
# 单元周围保持距离
set_halo [get_cells critical_cell] \
    -left 1.0 -right 1.0 \
    -top 1.0 -bottom 1.0
```

### 11. 时序驱动布局
**定义**: 在placement时考虑timing，优化关键路径。

**方法**:
```tcl
global_placement \
    -timing_driven  # 启用timing-driven模式

# 需要先设置时序约束
read_sdc constraints.sdc
```

**效果**:
- 关键路径上的单元会放得更近
- 非关键路径可能HPWL增加
- 整体WNS改善

**权衡**:
```
Pure wirelength → 最小HPWL，timing可能差
Timing-driven → WNS好，HPWL可能大
```

### 12. GPU加速
**RePlAce支持GPU**:
```
CPU only: 30-60秒 (本项目)
GPU加速: 5-10秒 (3-6×加速)

对大设计效果更明显:
100K instances: 10分钟 → 2分钟
```

**启用**:
```bash
# 检查是否有GPU支持
openroad -version
# 看到 "+GPU" 表示支持

# 自动使用GPU（如果可用）
global_placement  # 默认会用GPU
```

## 常见问题

### Q1: Global placement overflow很高怎么办？
**原因**: 
- Utilization太高（>80%）
- 某些区域有大量nets连接

**解决**:
```tcl
# 降低目标密度
global_placement -density 0.30  # 从0.40降到0.30

# 增加padding
global_placement -pad_left 2 -pad_right 2

# 增加core area
# 重新做floorplan with lower utilization
```

### Q2: 为什么IO placement后detail placement失败？
**原因**: IO pins没有BPin shapes

**检查**:
```tcl
# 数BPin数量
set pin [lindex [get_bterms] 0]
set bpins [$pin getBPins]
if {[llength $bpins] == 0} {
    puts "ERROR: No BPin!"
}
```

**修复**: 使用本项目的io_place_fixed.tcl

### Q3: Legalization后HPWL增加很多？
**正常现象**: 6-15%增加可接受

**异常情况**:
- HPWL增加>30% → Global placement质量差
- 考虑调整global placement参数

### Q4: 某些单元无法放置？
**可能原因**:

1. **单元太大**: 
```
单元宽度 > 行宽度
→ 检查大macro，可能需要特殊处理
```

2. **Blockage太多**:
```
可放置区域不足
→ 减少blockage或增大core
```

3. **固定单元冲突**:
```
手动放置的单元占据了空间
→ 检查fixed cells
```

### Q5: 如何查看placement结果？
```bash
# GUI可视化
openroad -gui results/detail_place_fixed.odb

# 在GUI中:
# - 'f' 键: 适应视图
# - 鼠标滚轮: 缩放
# - 点击单元: 查看属性
# - View -> Heatmap -> Density: 查看密度分布
```

## 验证检查清单

### Global Placement检查
- [ ] Overflow < 20%
- [ ] 密度分布均匀（无极端热点）
- [ ] HPWL在合理范围
- [ ] 运行时间合理(< 5分钟对小设计)

### IO Placement检查
- [ ] 所有56个IO pins已放置
- [ ] 每个pin都有BPin (关键!)
- [ ] Pins均匀分布在四边
- [ ] 无pins重叠

### Detailed Placement检查
- [ ] 所有508单元已放置(100%)
- [ ] check_placement通过
- [ ] 平均位移小(< 1um)
- [ ] HPWL增加合理(< 15%)
- [ ] 无DRC违例(overlap)
- [ ] 可视化检查：单元对齐到行

## 相关命令参考

### Global Placement
```tcl
# 基本用法
global_placement

# 带参数
global_placement \
    -skip_io \               # 跳过IO (本项目用)
    -density 0.35 \          # 目标密度
    -pad_left 2 \            # 左侧padding (sites)
    -pad_right 2 \
    -timing_driven \         # 时序驱动
    -routability_driven      # 考虑布线性
```

### IO Placement
```tcl
# 均匀分布（本项目用）
place_pins -hor_layers M5 -ver_layers M4

# 指定特定边
set_io_pin_constraint \
    -pin_names {clk rst} \
    -region bottom:0:100

# 手动放置
place_pin -pin clk -layer M4 \
    -location {50.0 0} \
    -force_to_die_boundary
```

### Detailed Placement
```tcl
# 标准用法
detailed_placement

# 检查结果
check_placement -verbose

# 报告统计
report_design_area
```

### 查询信息
```tcl
# 统计单元数
set insts [get_cells -hierarchical *]
puts "Total instances: [llength $insts]"

# 统计已放置
set placed 0
foreach inst $insts {
    if {[get_property $inst status] == "PLACED"} {
        incr placed
    }
}
puts "Placed: $placed"

# 报告HPWL
report_net_length
```

## 下一步

Placement完成后，进入 **时钟树综合 (CTS)** 阶段：
→ 参见: [08_cts.md](08_cts.md)
