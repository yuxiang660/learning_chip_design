# 步骤11: SPEF生成 (Parasitic Extraction)

## 如何运行

```bash
openroad scripts/11_spef.tcl
```

或查看日志：
```bash
openroad scripts/11_spef.tcl 2>&1 | tee logs/11_spef.log
```

**注意**: 此步骤为**可选步骤**，如果失败不会影响后续流程。

## 输入与输出

### 输入文件
| 文件 | 说明 |
|------|------|
| `results/detail_route.odb` | 详细布线后的设计 |
| LEF文件 | 金属层RC信息 |
| Liberty文件 | 时序信息 |

### 输出文件
| 文件 | 说明 |
|------|------|
| `reports/detail_route.spef` | SPEF格式的寄生参数文件 |

### 关键输出信息
```
SPEF file size: ~50-100 KB
Contains RC parasitics for all signal nets
Ready for timing analysis
```

## 涉及的EDA概念

### 1. SPEF (Standard Parasitic Exchange Format)
**定义**: 工业标准的寄生参数交换格式文件。

**包含信息**:
- **电阻 (R)**: 金属线的欧姆电阻
- **电容 (C)**: 对地电容和耦合电容
- **网络拓扑**: 互连结构
- **坐标信息**: 物理位置（可选）

**SPEF文件结构**:
```spef
*SPEF "IEEE 1481-1998"
*DESIGN "gcd"
*DATE "Feb 09 2026"
*VENDOR "OpenROAD"
*PROGRAM "OpenRCX"
*VERSION "1.0"
*DESIGN_FLOW "NETLIST_TYPE_VERILOG"
*DIVIDER /
*DELIMITER :
*BUS_DELIMITER [ ]
*T_UNIT 1 PS
*C_UNIT 1 FF
*R_UNIT 1 OHM
*L_UNIT 1 HENRY

*NAME_MAP
*1 clk
*2 rst
*3 req_val
...

*PORTS
*1 I
*2 I
*3 I
...

*D_NET *1 0.523
*CONN
*P *1 I
*I *inst1:CK I *C 0.012 0.0
*I *inst2:CK I *C 0.012 0.0
...
*CAP
1 *1:1 0.105
2 *1:2 0.089
3 *1:1 *2:1 0.023
...
*RES
1 *1:1 *1:2 12.5
2 *1:2 *1:3 8.7
...
*END

*D_NET *2 0.234
...
```

### 2. RC寄生参数提取
**定义**: 从物理版图中计算互连线的电阻和电容。

**提取方法**:

**方法1: 基于规则的提取** (OpenROAD使用)
```
根据LEF中的RC参数 + 实际走线长度/宽度
R = ρ × L / (W × T)
C = ε × A / d + C_coupling
```

**方法2: 场求解器提取** (商业工具)
```
使用2D/3D电磁场仿真
更精确但计算量大
工具: Calibre xRC, StarRC
```

**本项目使用**:
- OpenROAD内置提取引擎
- 基于LEF的RC参数
- 考虑实际布线的长度、层次、宽度

### 3. 电阻提取 (Resistance Extraction)
**来源**:
1. **金属线电阻**: 
   ```
   R_wire = ρ × L / (W × T)
   ρ: 金属电阻率 (Ω·m)
   L: 线长
   W: 线宽
   T: 金属厚度
   ```

2. **Via电阻**:
   ```
   R_via ≈ 0.5-2Ω (典型值)
   多个via并联降低电阻
   ```

3. **接触电阻**:
   ```
   R_contact ≈ 50-200Ω
   标准单元pin到M1的接触
   ```

**ASAP7工艺典型值**:
```
M1: ~500 Ω/um
M2: ~200 Ω/um  
M3-M5: ~100 Ω/um
M6-M9: ~50 Ω/um
```

### 4. 电容提取 (Capacitance Extraction)
**类型**:

**1. 地电容 (Ground Capacitance)**:
```
C_ground = ε × A / d
ε: 介电常数
A: 金属面积
d: 到地平面距离

作用: 影响RC延迟
```

**2. 耦合电容 (Coupling Capacitance)**:
```
C_coupling: 相邻net之间的电容

作用:
- 串扰 (Crosstalk)
- 信号完整性影响
- 时序不确定性
```

**3. 总电容**:
```
C_total = C_ground + Σ(C_coupling_i)
```

**ASAP7工艺典型值**:
```
M1: ~0.2 fF/um (wire cap)
M2: ~0.15 fF/um
M5: ~0.1 fF/um
Coupling: ~30-40% of total
```

### 5. RC延迟模型
**Elmore延迟模型**:
```
t_d = Σ(R_i × C_downstream_i)

例子: 简单RC链
      R1    R2    R3
  o---###---###---###---o
       |     |     |
      C1    C2    C3

t_d = R1×(C1+C2+C3) + R2×(C2+C3) + R3×C3
```

**影响时序**:
```
Setup time = t_clk→q + t_logic + t_wire + t_setup

t_wire 由寄生RC决定！

长线/细线 → 大RC → 慢速度
短线/粗线 → 小RC → 快速度
```

### 6. 为什么需要SPEF?

**1. 精确时序分析**:
```
综合时估算: Wire Load Model (不准确)
布线后实际: SPEF (准确)

典型差异: 10-30% timing slack变化
```

**2. Sign-off时序验证**:
```
Tape-out前必须用SPEF进行final STA
确保芯片能在目标频率工作
```

**3. 后仿真 (Post-layout Simulation)**:
```
门级网表 + SPEF → 准确仿真
验证功能 + 时序
发现glitch、setup/hold违例
```

**4. 功耗分析**:
```
动态功耗 ∝ C × V² × f
C从SPEF提取 → 准确功耗
```

### 7. SPEF vs SDF
**区别**:

| 特性 | SPEF | SDF |
|------|------|-----|
| 内容 | RC寄生参数 | 时序延迟/约束 |
| 用途 | STA输入 | 仿真backannotation |
| 生成时机 | 布线后提取 | STA计算后生成 |
| 文件大小 | 较大(几MB) | 较小(几百KB) |

**工作流**:
```
Layout → RC Extraction → SPEF
                          ↓
                         STA → SDF
                          ↓
                    Gate Simulation
```

### 8. 提取精度与性能权衡

**Level 1: Wire-based**
```
只考虑wire长度和层次
速度: 快 (秒级)
精度: 70-80%
用途: 早期评估
```

**Level 2: Detailed extraction** (本项目)
```
考虑实际geometry
速度: 中 (分钟级)
精度: 85-95%
用途: 详细时序分析
```

**Level 3: Field solver**
```
2D/3D电磁场仿真
速度: 慢 (小时级)
精度: 95-99%
用途: Sign-off, 关键nets
```

### 9. OpenROAD的寄生提取

**提取引擎**: OpenRCX

**支持的模式**:
1. `estimate_parasitics -placement`: 快速估算
2. `estimate_parasitics -global_routing`: 基于global route
3. `extract_parasitics`: 基于detailed route (最准确)

**本脚本使用**:
```tcl
# 优先使用extraction rules (如果存在)
extract_parasitics -ext_model_file <rules>

# 否则使用估算
estimate_parasitics -placement
```

### 10. SPEF在时序分析中的使用

**无SPEF (综合时)**:
```tcl
# 使用wire load model (估算)
set_wire_load_model -name "small"
```

**有SPEF (布线后)**:
```tcl
# 读取精确寄生参数
read_spef reports/detail_route.spef

# 重新进行时序分析
report_checks -path_delay max
```

**典型结果对比**:
```
综合时预测: Setup slack = +50ps
布线后实际: Setup slack = +15ps (更紧！)

差异原因:
- 实际wire更长
- 更多coupling
- Via电阻
```

## 常见问题

### Q1: SPEF生成失败怎么办?
**A**: SPEF是可选步骤，不影响后续流程。
- 原因: OpenROAD的extraction可能需要工艺的extraction rules文件
- 解决: 
  1. 如果有extraction rules，在脚本中指定路径
  2. 使用`estimate_parasitics`进行内部时序分析
  3. 使用外部工具(Calibre xRC)提取SPEF

### Q2: SPEF文件很大，正常吗?
**A**: 正常。
- 小设计(本项目): 50-100KB
- 中等设计: 几MB到几十MB  
- 大设计: 几百MB到GB级

包含每个net的详细RC信息。

### Q3: 什么时候使用SPEF?
**A**: 
- **必须**: Sign-off时序验证、Tape-out前
- **推荐**: 后仿真、功耗分析
- **可选**: P&R迭代优化

### Q4: detail_route.spef vs gcd_final.spef有何区别?
**A**: 
- `detail_route.spef`: 详细布线后，filler插入前
- `gcd_final.spef`: 最终版本，包含filler
- 理论区别: <1% (filler不改变信号走线)
- 用途: detail版用于分析，final版用于归档

### Q5: SPEF可以用于什么工具?
**A**:
- **STA工具**: PrimeTime, Tempus, OpenSTA
- **仿真器**: VCS, ModelSim, Xcelium (通过SDF转换)
- **功耗工具**: PowerArtist, Voltus
- **形式验证**: Formality, Conformal

### Q6: 如何检查SPEF的质量?
**A**:
```bash
# 检查文件大小
du -h reports/detail_route.spef

# 查看头部信息
head -50 reports/detail_route.spef

# 统计net数量
grep "\*D_NET" reports/detail_route.spef | wc -l

# 检查RC数值是否合理
grep "^\*CAP" -A 20 reports/detail_route.spef
```

## 验证检查清单

完成SPEF生成后，检查：

- [ ] SPEF文件存在: `reports/detail_route.spef`
- [ ] 文件大小合理: 50-100KB (本项目)
- [ ] 包含正确的头部信息 (*SPEF, *DESIGN等)
- [ ] 包含所有信号nets (grep "*D_NET")
- [ ] RC数值在合理范围内
- [ ] 可以被STA工具读取 (如果有工具)

## 相关命令参考

### OpenROAD寄生提取命令

```tcl
# 快速估算 (用于内部timing)
estimate_parasitics -placement
estimate_parasitics -global_routing

# 精确提取 (用于SPEF输出)
define_process_corner -ext_model_index 0 typical
extract_parasitics -ext_model_file <rules_file>

# 写出SPEF
write_spef <filename>
write_spef -net <net_name> <filename>  # 单个net

# 设置RC参数
set_wire_rc -signal -layer M2
set_wire_rc -clock -layer M5
```

### SPEF读取 (其他工具)

```tcl
# PrimeTime
read_parasitics reports/detail_route.spef

# OpenSTA
read_spef reports/detail_route.spef
```

## 下一步

完成SPEF生成后：

1. **继续流程**: 
   ```bash
   openroad scripts/12_filler.tcl  # Filler插入
   ```

2. **使用SPEF进行精确时序分析** (可选):
   ```bash
   sta
   read_liberty ...
   read_verilog results/detail_route.v  
   link_design gcd
   read_spef reports/detail_route.spef
   read_sdc constraints.sdc
   report_checks -path_delay max
   ```

3. **对比filler前后SPEF** (步骤14后):
   ```bash
   diff reports/detail_route.spef reports/gcd_final.spef
   # 应该差异很小
   ```

## 参考资料

- IEEE 1481-1998: SPEF标准规范
- OpenROAD文档: Parasitic Extraction
- Elmore Delay Model论文
- RC Extraction技术综述

---

**总结**: SPEF是从物理版图到精确时序的桥梁。虽然是可选步骤，但对于准确的时序分析和后仿真至关重要。
