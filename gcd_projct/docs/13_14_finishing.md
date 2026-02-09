# 步顲12-14: 收尾阶段 (Finishing)

本文档涵盖Filler插入和最终输出生成两个步骤

## 如何运行

```bash
# 步顲12: Filler Cell插入
openroad scripts/12_filler.tcl

# 步顲13: 最终输出
openroad scripts/13_gdsii.tcl

# 步顲14: 最终SPEF生成 (可选)
openroad scripts/14_spef_final.tcl
```

## 输入与输出

### 步骤12: Filler插入
**输入**: `results/detail_route.odb`  
**输出**: `results/filler.odb`

**关键指标**:
```
原始instances: 516 (逻辑+时钟)
Filler instances: 5039
总instances: 5555
```

### 步骤13: 最终输出
**输入**: `results/filler.odb`  
**输出**: 
- `results/gcd_final.def` (DEF格式)
- `results/gcd_final.odb` (OpenROAD数据库)
- `results/gcd_final.v` (后端netlist)
- `reports/final_timing_*.rpt` (时序报告)
- `reports/final_area.rpt` (面积报告)

### 步骤14: 最终SPEF生成 (可选)
**输入**: `results/filler.odb`  
**输出**: 
- `reports/gcd_final.spef` (最终RC寄生参数)

### 步顲14: 最终SPEF生成 (可选)
**输入**: `results/filler.odb`  
**输出**: 
- `reports/gcd_final.spef` (最终RC寄生参数)

## 涉及的EDA概念

### 1. Filler Cell（填充单元）
**定义**: 填充标准单元行中空隙的特殊单元，无逻辑功能。

**为什么需要Filler**:

**1. N-well/P-well连续性**:
```
没有filler:
Row: [Cell1] [gap] [Cell2]

N-well: ━━━━  断开  ━━━━  ← DRC违例！

有filler:
Row: [Cell1][Filler][Cell2]

N-well: ━━━━━━━━━━━━━━  ← 连续 ✓
```

**2. 电源rail连续性**:
```
VDD rail: ━━━━  gap  ━━━━  ← 高阻抗

加filler后:
VDD rail: ━━━━━━━━━━━━━  ← 低阻抗
```

**3. Metal density规则**:
```
DRC要求: 每个window内金属密度20-80%

空gap → density too low
Filler带有metal shape → 满足density
```

**4. DRC合规**:
- 防止poly spacing违例
- 防止active spacing违例
- 满足implant层规则

### 2. Filler Cell类型

**标准Filler**: FILLER_ASAP7_75t_R (1×site)
```lef
MACRO FILLER_ASAP7_75t_R
    CLASS CORE SPACER ;       # SPACER = filler
    SIZE 0.054 BY 0.270 ;     # 1 site宽
    
    PIN VDD
        USE POWER ;
        SHAPE ABUTMENT ;      # 可拼接
        ...
    END VDD
    
    PIN VSS
        USE GROUND ;
        SHAPE ABUTMENT ;
        ...
    END VSS
    
    # 注意: 无信号pin!
    # 只有电源pin
    # 内部可能有poly/metal shapes满足density
END FILLER_ASAP7_75t_R
```

**Half-Width Filler**: FILLERxp5_ASAP7_75t_R (0.5×site)
```
用途: 填充更小的gap
示例: [Cell1] [0.5 gap] [Cell2]
      ↓
      [Cell1][FILLERxp5][Cell2]
```

**Decap Filler**: DCAP_ASAP7_75t_R
```
作用: Filler + 去耦电容
内部: MOS capacitor连接VDD-VSS
功能: 提供local charge reservoir
```

### 3. Filler插入策略

**Greedy Algorithm（贪心算法）**:
```
扫描每一行:
  for each row:
    找到所有gap
    for each gap:
      尝试最大filler (1×)
      如果放不下，用0.5×
      重复直到填满
```

**本项目示例**:
```
Row 0: [Cell][Gap=3.5 sites][Cell]

填充:
  1. 放3个 FILLER (3×site) → 剩0.5
  2. 放1个 FILLERxp5 (0.5×site) → 剩0
  
结果: [Cell][F][F][F][Fxp5][Cell] ✓
```

**统计**:
```
FILLERxp5: ~2000个 (小gap)
FILLER: ~3000个 (标准gap)
总计: 5039个
```

### 4. 面积和Utilization

**最终统计**:
```
Design area: 50 um² (标准单元总面积)
Core area: 228.61 um² (15.12×15.12)
Utilization: 50/228.61 = 21.9% ≈ 25%

逻辑单元: 516个 (占50 um²)
Filler: 5039个 (填充gaps)

Total instances: 5555个
```

**面积组成**:
```
逻辑门: ~45 um² (90%)
时钟buffer: ~5 um² (10%)
Filler: 不占placement area（填充空隙）

25% utilization → 75% core是filler/空白
```

### 5. 最终DEF文件
**定义**: 工业标准的物理设计交换格式。

**内容结构**:
```def
VERSION 5.8 ;
DESIGN gcd ;
UNITS DISTANCE MICRONS 2000 ;

DIEAREA ( 0 0 ) ( 32400 32400 ) ;

ROW ROW_0 asap7sc7p5t 540 540 N DO 56 BY 1 STEP 270 0 ;
...

COMPONENTS 5555 ;
  - _419_ INVx1_ASAP7_75t_R + PLACED ( 1080 1350 ) N ;
  - _420_ NAND2x1_ASAP7_75t_R + PLACED ( 1350 1350 ) N ;
  - FILLER_0 FILLER_ASAP7_75t_R + PLACED ( 540 540 ) N ;
  - FILLER_1 FILLER_ASAP7_75t_R + PLACED ( 810 540 ) N ;
  ...
END COMPONENTS

SPECIALNETS 2 ;
  - VDD ( * VDD )
    + ROUTED M2 ( 540 * ) ( * * )
    + NEW M5 ( * 1080 ) ( * * )
    + NEW M7 ( * * ) ( * * ) ;
  - VSS ( * VSS )
    + ROUTED M2 ( 540 * ) ( * * )
    + NEW M5 ( * 1080 ) ( * * ) ;
END SPECIALNETS

NETS 447 ;
  - _000_ ( _419_ Y ) ( _420_ A )
    + ROUTED M1 ( 1100 1380 ) ( 1350 * )
    + NEW M2 ( 1100 1380 ) ( * 1450 )
    + NEW M3 ( 1250 1450 ) ( 1350 * ) ;
  ...
END NETS

END DESIGN
```

**关键sections**:
- DIEAREA: 芯片边界
- ROW: 标准单元行定义
- COMPONENTS: 所有单元实例及位置
- SPECIALNETS: 电源网络（含geometry）
- NETS: 信号网络（含布线路径）

### 6. ODB vs DEF
**对比**:

**ODB** (OpenROAD Database):
- 二进制格式
- 读写快速（几秒）
- 包含所有OpenROAD内部信息
- 不可人类阅读
- OpenROAD工具间传递

**DEF** (Design Exchange Format):
- 文本格式（ASCII）
- 读写较慢（几十秒对大设计）
- 工业标准，广泛兼容
- 可人类阅读/编辑
- 与Cadence/Synopsys等工具交换

**使用场景**:
```
OpenROAD流程内: 用ODB (快)
导出到其他工具: 用DEF (兼容)
调试/检查: DEF可文本查看
```

### 7. 后端Netlist
**定义**: 包含placement和routing信息的网表。

**与综合网表对比**:

**综合网表** (synth.v):
```verilog
module gcd (...);
  wire _000_;
  wire _001_;
  
  INVx1 _419_ (.A(in), .Y(_000_));
  NAND2x1 _420_ (.A(_000_), .B(in2), .Y(_001_));
  DFF _759_ (.D(_001_), .CLK(clk), .Q(out));
endmodule
```

**后端网表** (gcd_final.v):
```verilog
module gcd (...);
  wire _000_;
  wire _001_;
  
  INVx1 _419_ (.A(in), .Y(_000_));
  NAND2x1 _420_ (.A(_000_), .B(in2), .Y(_001_));
  DFF _759_ (.D(_001_), .CLK(clk), .Q(out));
  
  // 新增: 时钟buffer
  BUFx4 clkbuf_0_clk (.A(clk), .Y(clknet_0_clk));
  BUFx4 clkbuf_2_0__f_clk (.A(clknet_0_clk), .Y(clknet_2_0_clk));
  
  // 新增: Filler cells (可能包含，也可能不包含)
  FILLER FILLER_0 ();
  FILLER FILLER_1 ();
  ...
endmodule
```

**用途**:
- 后仿真（Post-layout simulation）
- 形式验证（vs RTL）
- 文档记录

### 8. SDF (Standard Delay Format)
**定义**: 标准延迟格式，包含实际时序信息。

**内容**:
```sdf
(DELAYFILE
  (SDFVERSION "3.0")
  (DESIGN "gcd")
  (DATE "2026-01-15")
  (VENDOR "OpenROAD")
  (PROGRAM "OpenSTA")
  (VERSION "2.0")
  (TIMESCALE 1ps)
  
  (CELL
    (CELLTYPE "INVx1")
    (INSTANCE _419_)
    (DELAY
      (ABSOLUTE
        (IOPATH A Y (25:30:35) (20:25:30))  // (min:typ:max)
      )
    )
  )
  
  (CELL
    (CELLTYPE "DFF")
    (INSTANCE _759_)
    (DELAY
      (ABSOLUTE
        (IOPATH CLK Q (50:55:60) (45:50:55))
      )
    )
    (TIMINGCHECK
      (SETUP D (posedge CLK) (15))
      (HOLD D (posedge CLK) (5))
    )
  )
  
  // Interconnect delays (from routing)
  (INTERCONNECT _419_/Y _420_/A (2:3:4))  // wire delay
)
```

**用途**:
```bash
# 后仿真时back-annotate
vcs +sdf_file=gcd_final.sdf gcd_tb.v gcd_final.v
```

### 9. GDSII格式
**定义**: 图形数据系统二进制格式，包含所有版图几何信息。

**层次**:
```
DEF/ODB (抽象物理描述)
    ↓
  需要PDK的GDS库
    ↓
GDSII (完整版图)
    ↓
  发送给Foundry制造
```

**为什么OpenROAD不直接生成GDS**:
- 标准单元的详细geometry在LEF中只是抽象
- 实际polygon在PDK的GDS文件中
- 需要"merge"设计GDS和单元库GDS

**生成方法**:

**方法1: KLayout** (开源)
```bash
klayout -zz -r write_gds.py \
  -rd input_def=gcd_final.def \
  -rd output_gds=gcd_final.gds \
  -rd tech_file=asap7.lyt \
  -rd cell_gds=asap7_cells.gds
```

**方法2: Calibre** (商业)
```bash
calibre -drc -runset gds_export.runset
```

**方法3: Magic** (学术)
```tcl
magic -T asap7.tech
load gcd_final.def
gds write gcd_final.gds
```

### 10. 最终时序分析

**Propagated Clock**:
```
综合时(ideal clock):
  Setup slack: +15.62ps

CTS后(propagated):
  Setup slack: -41.77ps
  
最终(with filler):
  Setup slack: -41.77ps (no change)
  Hold slack: +2.31ps
```

**Slack解读**:
```
Setup slack = -41.77ps
  含义: 违例41.77ps
  原因: 真实时钟延迟+线延迟
  影响: 此频率无法满足时序
  
解决办法:
  1. 降低时钟频率: 310ps → 350ps
  2. 时序优化: buffer insertion
  3. 重新综合: 更严格约束
  
Hold slack = +2.31ps ✓
  含义: 满足，有2.31ps余量
  Hold通常容易满足
```

### 11. Sign-off检查清单
**物理验证**:
- [ ] DRC: 0 violations ✓
- [ ] LVS: Layout vs Schematic (需外部工具)
- [ ] Antenna: 0 violations ✓
- [ ] Density: 满足min/max要求
- [ ] Metal fill: 如需要

**时序验证**:
- [ ] Setup timing: 记录violation
- [ ] Hold timing: MET ✓
- [ ] Clock skew: < 5ps ✓
- [ ] Multi-corner: 需测试各corner

**功耗验证**:
- [ ] IR drop: < 10% VDD
- [ ] EM: 满足电流密度限制
- [ ] Power: 在预算内

**可制造性**:
- [ ] OPC: 光学临近修正 (Foundry处理)
- [ ] DFM: 可制造性设计检查
- [ ] Fill patterns: 金属填充图案

### 12. Tape-out流程
**完整流程**:
```
1. 设计完成
   ↓
2. 内部Sign-off
   - 时序、功耗、物理验证
   ↓
3. 生成GDSII
   - 包含所有层的polygon
   ↓
4. Foundry检查
   - DRC、LVS、EM
   - 通常2-4周
   ↓
5. 修复issues (如有)
   ↓
6. 最终Tape-out
   - 提交给Foundry
   ↓
7. 制造
   - 晶圆制造: 2-3个月
   - 封装测试: 1个月
   ↓
8. 芯片回片
```

## 常见问题

### Q1: Filler插入失败？
**错误**: No space for filler

**原因**:
- Utilization = 100% (无gap)
- 已有fixed cells占满

**解决**: 检查placement，应该有gap

### Q2: 最终netlist很大？
**原因**: 包含5039个filler

**优化**:
```verilog
// 写netlist时排除filler
write_verilog -exclude_fillers gcd_final.v

// 或后处理删除
grep -v "FILLER" gcd_final.v > gcd_clean.v
```

### Q3: DEF文件无法被其他工具读取？
**兼容性问题**:
- DEF版本不匹配
- 某些扩展语法

**解决**:
```bash
# 转换DEF版本
def_convert -from 5.8 -to 5.7 input.def output.def

# 或简化DEF（去掉扩展）
```

### Q4: 如何生成SDF？
```tcl
# OpenROAD中
read_lef ...
read_liberty ...
read_db gcd_final.odb

# 提取寄生参数
extract_parasitics -ext_model_file asap7.extmodel

# 写SDF
write_sdf gcd_final.sdf
```

### Q5: Setup timing违例怎么办？
**选项**:

**1. 降频** (最简单):
```tcl
# 310ps → 350ps
create_clock -period 350 [get_ports clk]
```

**2. 时序优化**:
```tcl
# OpenROAD的timing repair
repair_timing -setup

# 插入buffer，resize gates
```

**3. 重新综合**:
```tcl
# 更紧的约束
create_clock -period 280  # over-constraint
```

## 验证检查清单

### Filler插入检查
- [ ] Filler数量>0 (5039)
- [ ] 所有行的gap已填充
- [ ] 无placement违例
- [ ] 电源连接完整

### 最终输出检查
- [ ] gcd_final.def存在
- [ ] gcd_final.odb存在
- [ ] gcd_final.v存在
- [ ] 时序报告已生成
- [ ] 面积报告正确
- [ ] 文件可被其他工具读取
- [ ] 设计统计信息正确

## 相关命令参考

### Filler插入
```tcl
# 基本用法
filler_placement {FILLER_ASAP7_75t_R}

# 多种filler
filler_placement {
    FILLERxp5_ASAP7_75t_R
    FILLER_ASAP7_75t_R
}

# 包含decap
filler_placement {
    FILLERxp5_ASAP7_75t_R
    FILLER_ASAP7_75t_R
    DCAP_ASAP7_75t_R
}

# 指定前缀
filler_placement -prefix FILL_ {FILLER_ASAP7_75t_R}
```

### 输出文件
```tcl
# 写DEF
write_def results/gcd_final.def

# 写ODB
write_db results/gcd_final.odb

# 写Verilog
write_verilog results/gcd_final.v

# 写SDF (需先提取parasitics)
write_sdf results/gcd_final.sdf
```

### 报告生成
```tcl
# 时序报告
report_checks -path_delay max \
    -format full_clock_expanded \
    -fields {input_pin slew capacitance} \
    > reports/final_timing.rpt

# 面积报告
report_design_area > reports/final_area.rpt

# 功耗报告 (如有activities)
report_power > reports/final_power.rpt
```

### 设计统计
```tcl
# 实例统计
set insts [get_cells -hierarchical *]
puts "Total instances: [llength $insts]"

# 按类型统计
set fillers [get_cells FILLER_*]
puts "Fillers: [llength $fillers]"

# 网络统计
set nets [get_nets *]
puts "Total nets: [llength $nets]"
```

## 完成！

恭喜！您已完成完整的ASIC设计流程：

✅ 综合 → ✅ Floorplan → ✅ Tapcell → ✅ PDN  
✅ Placement → ✅ CTS → ✅ Routing  
✅ Filler → ✅ 最终输出

**最终交付物**:
- gcd_final.def - 完整物理设计
- gcd_final.odb - OpenROAD数据库
- gcd_final.v - 后端网表
- 完整的报告文件

**下一步**:
1. 使用商业工具做sign-off验证
2. 生成GDSII (KLayout/Calibre)
3. 提交Foundry tape-out

或者，将这套流程应用到更复杂的设计！
