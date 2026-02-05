# GCD项目 - ASIC设计流程帮助文档

本文件夹包含完整ASIC设计流程各步骤的详细帮助文档。每个文档包括运行命令、输入输出、以及相关EDA概念的深入解释。

## 📚 文档列表

### 前端阶段

| # | 文档 | 步骤 | 说明 |
|---|------|------|------|
| 1 | [01_synthesis.md](01_synthesis.md) | 综合 | RTL→门级网表，时序约束，标准单元映射 |
| 2 | [02_floorplan.md](02_floorplan.md) | 布图规划 | Die/Core定义，标准单元行，利用率 |
| 3 | [03_tapcell.md](03_tapcell.md) | Tapcell插入 | Well tap，防闩锁，衬底连接 |
| 4 | [04_pdn.md](04_pdn.md) | 电源分配网络 | Power grid，IR drop，Ldi/dt |

### 布局阶段

| # | 文档 | 步骤 | 说明 |
|---|------|------|------|
| 5-7 | [05_06_07_placement.md](05_06_07_placement.md) | 布局 | 全局布局，IO布局，详细布局，BPin |

### 时钟树

| # | 文档 | 步骤 | 说明 |
|---|------|------|------|
| 8 | [08_cts.md](08_cts.md) | 时钟树综合 | Clock tree，Skew，Buffer插入，H-tree |

### 布线阶段

| # | 文档 | 步骤 | 说明 |
|---|------|------|------|
| 9-10 | [09_10_routing.md](09_10_routing.md) | 布线 | 全局布线，详细布线，DRC，Via，Antenna |

### 收尾阶段

| # | 文档 | 步骤 | 说明 |
|---|------|------|------|
| 11-12 | [11_12_finishing.md](11_12_finishing.md) | 收尾 | Filler插入，DEF/ODB输出，GDSII，Sign-off |

## 🎯 快速导航

### 按问题查找

**时序相关**:
- Setup/Hold timing → [01_synthesis.md](01_synthesis.md#7-时序分析-static-timing-analysis-sta)
- Clock skew → [08_cts.md](08_cts.md#2-clock-skew-时钟偏斜)
- Propagated clock → [08_cts.md](08_cts.md#5-clock-latency-时钟延迟)

**物理设计**:
- Floorplan规划 → [02_floorplan.md](02_floorplan.md#1-floorplan布图规划)
- Utilization → [02_floorplan.md](02_floorplan.md#3-utilization利用率)
- Placement → [05_06_07_placement.md](05_06_07_placement.md#1-placement布局概述)

**电源相关**:
- PDN结构 → [04_pdn.md](04_pdn.md#1-电源分配网络-pdn)
- IR drop → [04_pdn.md](04_pdn.md#3-ir-drop欧姆压降)
- Decap → [04_pdn.md](04_pdn.md#8-decoupling-capacitor去耦电容)

**布线相关**:
- Global routing → [09_10_routing.md](09_10_routing.md#2-global-routing全局布线)
- DRC violations → [09_10_routing.md](09_10_routing.md#6-drc-violations设计规则违例)
- Antenna effect → [09_10_routing.md](09_10_routing.md#7-antenna-effect天线效应)

**可靠性**:
- Latchup → [03_tapcell.md](03_tapcell.md#2-闩锁效应-latchup)
- Well tap → [03_tapcell.md](03_tapcell.md#1-well-tap-cell阱接触单元)

**文件格式**:
- LEF → [02_floorplan.md](02_floorplan.md#6-lef文件library-exchange-format)
- DEF → [02_floorplan.md](02_floorplan.md#7-def文件design-exchange-format)
- ODB → [02_floorplan.md](02_floorplan.md#8-odbopenroad-database)
- Liberty → [01_synthesis.md](01_synthesis.md#4-liberty文件-lib)
- SDF → [11_12_finishing.md](11_12_finishing.md#8-sdf-standard-delay-format)
- GDSII → [11_12_finishing.md](11_12_finishing.md#9-gdsii格式)

## 📖 如何使用本文档

### 学习路径

**初学者** (按顺序阅读):
```
01 → 02 → 03 → 04 → 05-07 → 08 → 09-10 → 11-12
```
每个步骤都有完整的概念解释和示例。

**有经验者** (按需查阅):
- 遇到问题时，直接查找相关文档的"常见问题"章节
- 需要理解某个概念时，查找"涉及的EDA概念"章节
- 需要命令参考时，查看"相关命令参考"章节

### 文档结构

每个文档包含以下标准章节：

1. **如何运行**: 具体命令和日志查看方法
2. **输入与输出**: 文件清单和关键指标
3. **涉及的EDA概念**: 10-12个核心概念的详细解释
4. **常见问题**: Q&A格式的实际问题解答
5. **验证检查清单**: 完成后的验证要点
6. **相关命令参考**: Tcl命令和选项说明
7. **下一步**: 指向下一个步骤的文档

## 🔍 概念索引

### A-C
- Antenna Effect → [09_10_routing.md](09_10_routing.md#7-antenna-effect天线效应)
- BPin (Boundary Pin) → [05_06_07_placement.md](05_06_07_placement.md#6-bpin-boundary-pin)
- Clock Gating → [08_cts.md](08_cts.md#9-clock-gating-时钟门控)
- Clock Skew → [08_cts.md](08_cts.md#2-clock-skew-时钟偏斜)
- Clock Tree Synthesis → [08_cts.md](08_cts.md#1-时钟树综合-cts)
- Congestion → [09_10_routing.md](09_10_routing.md#4-congestion拥挤度)
- CTS → [08_cts.md](08_cts.md)

### D-F
- Decap → [04_pdn.md](04_pdn.md#8-decoupling-capacitor去耦电容)
- DEF → [02_floorplan.md](02_floorplan.md#7-def文件design-exchange-format)
- Density → [05_06_07_placement.md](05_06_07_placement.md#7-密度-density)
- Detailed Placement → [05_06_07_placement.md](05_06_07_placement.md#4-detailed-placement详细布局)
- Detailed Routing → [09_10_routing.md](09_10_routing.md#5-detailed-routing详细布线)
- DRC → [09_10_routing.md](09_10_routing.md#6-drc-violations设计规则违例)
- Filler Cell → [11_12_finishing.md](11_12_finishing.md#1-filler-cell填充单元)
- Floorplan → [02_floorplan.md](02_floorplan.md#1-floorplan布图规划)

### G-L
- GCell → [09_10_routing.md](09_10_routing.md#2-global-routing全局布线)
- GDSII → [11_12_finishing.md](11_12_finishing.md#9-gdsii格式)
- Global Placement → [05_06_07_placement.md](05_06_07_placement.md#2-global-placement全局布局)
- Global Routing → [09_10_routing.md](09_10_routing.md#2-global-routing全局布线)
- H-tree → [08_cts.md](08_cts.md#3-clock-tree-拓扑结构)
- HPWL → [05_06_07_placement.md](05_06_07_placement.md#2-global-placement全局布局)
- IO Placement → [05_06_07_placement.md](05_06_07_placement.md#5-io-placement-io布局)
- IR Drop → [04_pdn.md](04_pdn.md#3-ir-drop欧姆压降)
- Latchup → [03_tapcell.md](03_tapcell.md#2-闩锁效应-latchup)
- Ldi/dt Noise → [04_pdn.md](04_pdn.md#4-ldidt噪声)
- LEF → [02_floorplan.md](02_floorplan.md#6-lef文件library-exchange-format)
- Legalization → [05_06_07_placement.md](05_06_07_placement.md#3-legalization合法化)
- Liberty → [01_synthesis.md](01_synthesis.md#4-liberty文件-lib)
- Logic Synthesis → [01_synthesis.md](01_synthesis.md#2-逻辑综合-logic-synthesis)

### O-R
- ODB → [02_floorplan.md](02_floorplan.md#8-odbopenroad-database)
- Overflow → [09_10_routing.md](09_10_routing.md#3-overflow溢出)
- Panel Routing → [09_10_routing.md](09_10_routing.md#11-panel-routing)
- PDN → [04_pdn.md](04_pdn.md#1-电源分配网络-pdn)
- Placement → [05_06_07_placement.md](05_06_07_placement.md)
- Power Distribution Network → [04_pdn.md](04_pdn.md)
- Rip-up and Reroute → [09_10_routing.md](09_10_routing.md#10-rip-up-and-reroute)
- Routing → [09_10_routing.md](09_10_routing.md)
- RTL → [01_synthesis.md](01_synthesis.md#1-rtl-register-transfer-level)

### S-Z
- SDF → [11_12_finishing.md](11_12_finishing.md#8-sdf-standard-delay-format)
- SDC → [01_synthesis.md](01_synthesis.md#5-sdc约束-synopsys-design-constraints)
- Site → [02_floorplan.md](02_floorplan.md#5-site放置格点)
- Standard Cell → [01_synthesis.md](01_synthesis.md#3-标准单元-standard-cell)
- Standard Cell Row → [02_floorplan.md](02_floorplan.md#4-standard-cell-row标准单元行)
- Static Timing Analysis → [01_synthesis.md](01_synthesis.md#7-时序分析-static-timing-analysis-sta)
- Tapcell → [03_tapcell.md](03_tapcell.md#1-well-tap-cell阱接触单元)
- Track → [09_10_routing.md](09_10_routing.md#5-detailed-routing详细布线)
- Useful Skew → [08_cts.md](08_cts.md#8-useful-skew-有益偏斜)
- Utilization → [02_floorplan.md](02_floorplan.md#3-utilization利用率)
- Via → [09_10_routing.md](09_10_routing.md#9-via通孔)
- Via Array → [04_pdn.md](04_pdn.md#6-via-array通孔阵列)
- Well → [03_tapcell.md](03_tapcell.md#6-well结构)

## 🚀 快速参考卡片

### 完整流程命令
```bash
cd /home/yuxiangw/github/learning_chip_design/gcd_projct

# 一键运行完整流程
./run_all.sh

# 或手动逐步运行
yosys scripts/01_synth.tcl                 # 注意：综合用 yosys
openroad scripts/02_floorplan.tcl
openroad scripts/03_tapcell.tcl
openroad scripts/04_pdn.tcl
openroad scripts/05_global_place_skip_io.tcl
openroad scripts/06_io_place_fixed.tcl
openroad scripts/07_detail_place_fixed.tcl
openroad scripts/08_cts.tcl
openroad scripts/09_global_route.tcl
openroad scripts/10_detail_route.tcl
openroad scripts/11_filler.tcl
openroad scripts/12_gdsii.tcl
```

### 关键文件位置
```
rtl/gcd.v                      # RTL源代码
scripts/*.tcl                  # 流程脚本
results/*.odb                  # 各阶段数据库
results/gcd_final.def          # 最终DEF
reports/*.rpt                  # 各阶段报告
logs/*.log                     # 运行日志
docs/help/*.md                 # 本帮助文档
```

### 可视化GUI
```bash
# 查看任意阶段的布局
openroad -gui results/<stage>.odb

# 常用快捷键
# f: 适应视图
# z: 放大
# Shift+z: 缩小
# 鼠标滚轮: 缩放
```

## 📝 学习建议

1. **理论+实践结合**: 
   - 先阅读文档理解概念
   - 然后运行脚本观察结果
   - 用GUI可视化验证

2. **循序渐进**:
   - 从简单概念开始（如Standard Cell）
   - 逐步到复杂主题（如CTS算法）
   - 遇到不懂的术语，用索引查找

3. **主动实验**:
   - 修改参数观察影响（如utilization）
   - 故意制造问题学习调试（如降低core area）
   - 对比不同配置的结果

4. **记录笔记**:
   - 记录遇到的问题和解决方法
   - 总结关键概念的理解
   - 建立自己的知识体系

## 🔗 相关资源

**OpenROAD文档**:
- [OpenROAD官方文档](https://openroad.readthedocs.io/)
- [OpenROAD-flow-scripts](https://github.com/The-OpenROAD-Project/OpenROAD-flow-scripts)

**ASAP7 PDK**:
- [ASAP7 GitHub](https://github.com/The-OpenROAD-Project/asap7)
- [ASAP7 Paper](https://ieeexplore.ieee.org/document/7942093)

**EDA基础知识**:
- Weste & Harris: "CMOS VLSI Design"
- Kahng et al.: "VLSI Physical Design"

## 💡 贡献

如果发现文档有误或需要补充，欢迎：
- 在项目issue中提出
- 直接修改markdown文件
- 添加更多示例和图表

---

**版本**: v1.0  
**更新日期**: 2026-01-15  
**作者**: GitHub Copilot  
**项目**: GCD ASIC Design Flow
