# 步骤9-10: 布线阶段 (Routing)

本文档涵盖全局布线和详细布线两个步骤

## 如何运行

```bash
# 步骤9: 全局布线
openroad scripts/09_global_route.tcl

# 步骤10: 详细布线
openroad scripts/10_detail_route.tcl
```

## 输入与输出

### 步骤9: 全局布线
**输入**: `results/cts.odb`  
**输出**: `results/global_route.odb` (包含routing guides)

**关键指标**:
```
Total nets: 445
Overflow: 0 (所有gcell)
Wire length: 2752um (估算)
Congestion: 7.53% (max)
```

### 步骤10: 详细布线
**输入**: `results/global_route.odb`  
**输出**: `results/detail_route.odb` (实际金属wire)

**关键指标**:
```
Wire length: 1730um (实际)
Vias: 4343个
DRC violations: 0 ✓
Antenna violations: 0 ✓
Iterations: 4轮 (141→14→2→0)
```

## 涉及的EDA概念

### 1. Routing（布线）概述
**定义**: 用金属线连接所有网络(nets)，实现电气连通。

**两阶段布线**:
```
Global Routing (全局布线)
    ↓
  生成routing guides（导引）
    ↓
Detailed Routing (详细布线)
    ↓
  生成actual wires（实际金属线）
```

**为什么分两阶段**:
- 问题规模太大（几十万nets × 几千tracks）
- 先粗略规划（global）→ 避免拥挤
- 再精细实现（detailed）→ 满足DRC

### 2. Global Routing（全局布线）
**定义**: 在粗粒度网格上规划布线路径，生成导引。

**GCell（全局单元）**:
```
将芯片分割成矩形网格:
本项目: 28×28 gcell网格，每个570nm×570nm

┌─────┬─────┬─────┬─────┐
│ GC  │ GC  │ GC  │ GC  │  GC = GCell
├─────┼─────┼─────┼─────┤
│     │     │     │     │
└─────┴─────┴─────┴─────┘
```

**每个GCell记录**:
- 可用routing tracks（容量）
- 已使用tracks（需求）
- Overflow = 需求 - 容量

**Routing Guide**:
```
Net "data[0]" 的routing guide:
  GCell(3,5) layer M2
  GCell(4,5) layer M2
  GCell(4,6) layer M2, via to M3
  GCell(4,7) layer M3
  
→ 告诉detailed router大致走哪里
```

**算法**: FastRoute
- 基于迷宫算法（Maze routing）
- 考虑拥挤度（congestion）
- 优化总线长

### 3. Overflow（溢出）
**定义**: GCell中需求超过容量的track数量。

**计算**:
```
Overflow = max(0, Demand - Capacity)

例子:
GCell (5,5):
  Capacity: 10 tracks (M2垂直)
  Demand: 12 tracks (经过此gcell的nets)
  Overflow = 12 - 10 = 2
  
含义: 有2条net找不到track，需要绕路
```

**全局目标**: 
```
Total Overflow = Σ(所有GCell的overflow)

理想: 0 overflow ✓ (本项目达成)
可接受: <5% gcells有overflow
危险: >10% gcells有overflow → 可能无法布通
```

**Overflow = 0的意义**:
- 所有nets都有路径
- 不需要绕路
- Detailed routing很可能成功

### 4. Congestion（拥挤度）
**定义**: routing资源使用率。

**计算**:
```
Congestion = (Demand / Capacity) × 100%

例子:
某GCell M2层:
  Capacity: 20 tracks
  Demand: 15 tracks
  Congestion = 15/20 = 75%
```

**分级**:
- **< 70%**: 安全（绿色）
- **70-85%**: 警告（黄色）
- **85-95%**: 拥挤（橙色）
- **> 95%**: 严重拥挤（红色）

**本项目**: 最大7.53% → 非常空闲！
（因为utilization只有25%）

### 5. Detailed Routing（详细布线）
**定义**: 在routing guide指导下，分配精确的track和via。

**工具**: TritonRoute

**细粒度**:
```
Global routing: GCell级别 (570nm)
Detailed routing: Track级别 (54nm)

精度提高 10倍！
```

**Track（轨道）**:
```
M2层 (vertical):
  Pitch: 54nm  (track间距)
  Width: 18nm  (最小线宽)
  Spacing: 18nm (最小间距)
  
一个gcell (570nm) 包含约 10条tracks
```

**任务**:
1. 将routing guide细化为exact wires
2. 分配具体track位置
3. 插入vias连接不同层
4. 修复所有DRC violations

### 6. DRC Violations（设计规则违例）
**定义**: 违反制造工艺规则的布线。

**常见DRC类型**:

**1. Minimum Width**:
```
Wire too narrow:
  ───┬───  18nm (OK)
     ┴
  ─┬─┴─┬─  12nm (Violation! < 18nm min)
```

**2. Minimum Spacing**:
```
两线太近:
  ────  ────  30nm间距 (OK)
  
  ────────    10nm间距 (Violation! < 18nm)
```

**3. Short**:
```
不同nets短路:
  Net A: ────┐
             ├── 短路点
  Net B: ────┘
```

**4. Via Enclosure**:
```
Via必须被上下层金属充分包围:
  
  M2: ┌─────────┐  Enclosure OK
      │  ┌───┐  │
  Via │  │   │  │
      │  └───┘  │
  M1: └─────────┘
  
  M2: ┌──┐        Too small! Violation
  Via │┌─┐│
  M1: └──┘
```

**5. EOL (End-of-Line)**:
```
线端需要额外间距:
  ────┐
      │ ← line end
      └───  需要更大空间
  
  ────     另一条线不能太近
```

**6. Metal Density**:
```
每个window内金属密度必须在范围内:
  Min: 20%
  Max: 80%

过少 → CMP (化学机械抛光)不均
过多 → 应力问题
```

### 7. Antenna Effect（天线效应）
**定义**: 制造过程中，长金属线累积等离子体电荷，可能击穿晶体管栅极。

**机理**:
```
Plasma etching过程:
  长金属线像天线收集电荷
    ↓
  大量电荷累积在metal上
    ↓
  连接到gate时，通过薄氧化层放电
    ↓
  Gate oxide被击穿 → 晶体管损坏
```

**Antenna Ratio**:
```
AR = (Gate Area Connected) / (Metal Area)

AR过大 → 违例

典型规范:
  M1: AR < 400
  M2: AR < 800
  M5: AR < 5000  (高层更宽容)
```

**修复方法**:

**1. Diode Insertion**:
```verilog
Metal ──┬── Gate
        │
       diode  ← 提供泄放路径
        │
       VSS
```

**2. Layer Jumping**:
```
原来: M1很长 ──────────── Gate

改为: M1 ─ via ─ M3短 ─ via ─ M1 ─ Gate
              ↑
         高层AR限制更宽松
```

**3. Router Breaking**:
在长线中间break，分段连接

**本项目**: 0 antenna violations ✓

### 8. Wire Length（线长）
**Global vs Detailed**:
```
Global routing: 2752um (估算，走gcell中心)
Detailed routing: 1730um (实际，优化后更短)

减少 37% !

原因:
- Global是粗略估计
- Detailed优化了实际路径
- 避免了不必要的绕路
```

**分层线长**:
```
M1:   8 um   (0.5%)  - 仅cell内部
M2: 580 um  (33.5%)  - 主要信号层
M3: 687 um  (39.7%)  - 主要信号层
M4: 271 um  (15.7%)  - 次要层
M5: 131 um   (7.6%)  - 时钟+长信号
M6:  36 um   (2.1%)  - 长距离
M7-M9: 13 um (0.7%)  - 很少使用

规律: 低层用得多（local routing）
```

### 9. Via（通孔）
**定义**: 连接不同金属层的垂直连接。

**类型**:
```
VIA12: M1 ↔ M2
VIA23: M2 ↔ M3
VIA34: M3 ↔ M4
...
```

**结构**:
```
M2层: ▓▓▓▓▓▓▓
      ░░░░░░░  Via12 (tungsten plug)
M1层: ▓▓▓▓▓▓▓
```

**本项目统计**:
```
Total vias: 4343

分布:
  M1→M2: 1609 (37%)  最多！
  M2→M3: 2199 (51%)  最多！
  M3→M4: 357
  M4→M5: 124
  M5+: 54

为什么M2↔M3最多？
- M2/M3是主要signal层
- 需要频繁切换vertical/horizontal
```

**Via可靠性**:
- Via是薄弱点（易断线、高阻）
- 关键信号用double via
- 时钟和电源用via array

### 10. Rip-up and Reroute
**定义**: 发现DRC后，拆除部分布线重新布线的优化策略。

**TritonRoute的迭代过程**:
```
Iteration 0: 初始布线
  → 141 violations (短路、间距等)
  
Iteration 1: 修复大部分违例
  识别violation区域 → rip-up → reroute
  → 14 violations (减少90%)
  
Iteration 2: 进一步优化
  → 2 violations
  
Iteration 3 (Stubborn tiles): 顽固区域
  用更大搜索空间、更多时间
  → 0 violations ✓ Success!
```

**Stubborn Tiles**:
- 最后几个最难修复的区域
- 需要特殊算法
- 本项目用了45秒完成

### 11. Panel Routing
**定义**: 将芯片分成多个panel并行布线。

**过程**:
```
┌──────┬──────┬──────┐
│Panel1│Panel2│Panel3│
├──────┼──────┼──────┤
│Panel4│Panel5│Panel6│
└──────┴──────┴──────┘

每个panel独立布线（可并行）
然后处理panel边界的连接
```

**进度显示**:
```
Completing 10% with 0 violations.
Completing 20% with 0 violations.
...
Completing 100% with 72 violations.

Panel-by-panel完成
```

### 12. Track Assignment
**定义**: 将routing guide分配到具体的track。

**示例**:
```
Routing guide说: "M2垂直走过gcell (3,5)"

Track assignment决定:
  具体走第7条track (在gcell的10条track中)
  
从 gcell级别 → track级别
```

**输出**:
```
[INFO DRT-0184] Done with 2227 vertical wires in 1 frboxes 
                and 1508 horizontal wires in 1 frboxes.
                
frbox: Fine routing box (详细布线区域)
```

## 常见问题

### Q1: Global routing有overflow怎么办？
**原因**:
- Utilization太高
- Placement拥挤
- 某些区域nets太密集

**解决**:
```tcl
# 方法1: 调整layer范围
set_global_routing_layer_adjustment M2-M6 0.5
# 减少50%容量 → 强制用其他层

# 方法2: 增加routing layers
set_routing_layers -signal M1-M7  # 原来M1-M5

# 方法3: 重新placement
# 降低density或使用routability-driven
```

### Q2: Detailed routing有大量DRC怎么办？
**分析违例类型**:
```
看报告中的 Viol/Layer 表:

如果某层特别多违例:
→ 可能那层routing太拥挤
→ 减少使用那层，或加宽线

如果主要是Short:
→ 检查是否有net连接错误
```

**调整参数**:
```tcl
detailed_route \
    -bottom_routing_layer M2 \  # 不用M1
    -top_routing_layer M7 \
    -verbose 1
```

### Q3: Antenna violations如何修复？
**自动修复**:
```tcl
# 检测antenna
check_antennas -report report.txt

# 自动修复（插入diode）
repair_antennas -iterations 3
```

**手动优化**:
- 高层金属AR限制更宽松 → 优先用高层长距离走线
- 关键nets手动布线

### Q4: Via太多会有问题吗？
**数量**: 4343个via是合理的（445 nets）

**问题**:
- Via是可靠性弱点
- Via有电阻（~5-10Ω each）

**优化**:
```
减少层间切换 → 减少via数
使用double/triple via增加可靠性（关键nets）
```

### Q5: 布线后线长显著增加？
**对比**:
```
Placement后HPWL: 3347um (直线距离)
Actual wire: 1730um

Actual < HPWL ?!
```

**解释**: HPWL是bounding box，实际可以走更短

**如果线长远大于HPWL**:
- 说明绕路很多
- 检查congestion
- 可能需要重新placement

### Q6: 如何可视化布线结果？
```bash
# OpenROAD GUI
openroad -gui results/detail_route.odb

# 在GUI中:
# View -> Layers -> 选择显示的metal层
# 不同层用不同颜色:
#   M1: 紫色
#   M2: 蓝色
#   M3: 绿色
#   M4-M9: 其他颜色

# Heatmap:
# View -> Heatmap -> Routing Congestion
```

## 验证检查清单

### Global Routing检查
- [ ] Overflow = 0 (理想) 或 <5%
- [ ] Congestion < 90% (所有gcell)
- [ ] Wire length合理（~数千um）
- [ ] 无error或warning
- [ ] Routing guides已生成

### Detailed Routing检查
- [ ] DRC violations = 0 ✓
- [ ] Antenna violations = 0 ✓
- [ ] 所有nets已布线(447/447)
- [ ] Wire length < 2×HPWL
- [ ] Via数量合理
- [ ] 各层line长分布合理
- [ ] 可视化检查无明显错误

## 相关命令参考

### Global Routing
```tcl
# 基本用法
global_route

# 带参数
global_route \
    -guide_file routes.guide \     # 输出guide文件
    -overflow_iterations 100 \     # 最多迭代次数
    -verbose \                     # 详细输出
    -congestion_iterations 30      # 拥挤优化迭代
```

### Detailed Routing
```tcl
# 基本用法
detailed_route

# 带参数
detailed_route \
    -output_maze maze.log \              # 搜索日志
    -output_drc violations.rpt \         # DRC报告
    -output_guide modified.guide \       # 修改后的guide
    -bottom_routing_layer M2 \           # 最低层
    -top_routing_layer M7 \              # 最高层
    -verbose 1                           # 详细度
```

### DRC和Antenna检查
```tcl
# DRC检查
check_drc -verbose

# Antenna检查
check_antennas \
    -report reports/antenna.rpt

# 自动修复antenna
repair_antennas \
    -diode_cell ANTENNA_ASAP7_75t_R \
    -iterations 3
```

### 报告
```tcl
# 布线统计
report_design_area
report_net_length

# 检查完整性
set unrouted [get_nets -filter "!is_routed"]
if {[llength $unrouted] == 0} {
    puts "All nets routed!"
}
```

### 可视化相关
```bash
# 生成congestion map
openroad -exit <<EOF
read_lef ...
read_db global_route.odb
report_congestion -file congestion.rpt
EOF

# GUI查看
openroad -gui results/detail_route.odb
```

## 下一步

Routing完成后，进入 **Filler插入和最终输出** 阶段：
→ 参见: [11_12_finishing.md](11_12_finishing.md)
