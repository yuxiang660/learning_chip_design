# 步骤8: 时钟树综合 (Clock Tree Synthesis, CTS)

## 如何运行

```bash
openroad scripts/08_cts.tcl
```

或查看日志：
```bash
openroad scripts/08_cts.tcl 2>&1 | tee logs/08_cts.log
```

## 输入与输出

### 输入文件
| 文件 | 说明 |
|------|------|
| `results/detail_place_fixed.odb` | 详细布局后的数据库 |
| Clock buffer库 | BUFx2/3/4/5_ASAP7_75t_R |

### 输出文件
| 文件 | 说明 |
|------|------|
| `results/cts.odb` | 插入时钟树后的数据库 |
| `reports/cts_skew.rpt` | 时钟偏斜报告 |

### 关键输出信息
```
Inserted 5 clock buffers
Clock tree levels: 2 (root → leaf)
Total clock buffers: 29 (含时钟门控)
Clock net fanout: 35 (registers)
Max skew: < 5ps
Clock latency: ~51ps (propagated)
```

## 涉及的EDA概念

### 1. 时钟树综合 (CTS)
**定义**: 构建从时钟源到所有时序单元的平衡分布网络。

**目标**:
- **低偏斜**: 所有寄存器时钟到达时间相近
- **低延迟**: 时钟传播延迟小
- **低功耗**: 时钟网络功耗占总功耗30-40%
- **低抖动**: 减少时钟边沿的不确定性

**没有CTS的问题**:
```
                Clock Source
                      │
    ┌────────────┬────┴────┬────────────┐
    │            │         │            │
  FF1(0ps)    FF2(0ps)  FF3(0ps)     FF4(0ps)

理想时钟 → 所有FF同时收到
```

**现实情况**:
```
长线 + 大fanout → 延迟不均 + RC延迟大

                Clock Source
                      │
    ┌────────────┬────┴────┬────────────┐
    │            │         │            │
  FF1(15ps)  FF2(25ps)  FF3(8ps)   FF4(32ps)

Skew = 32 - 8 = 24ps (很差!)
```

### 2. Clock Skew (时钟偏斜)
**定义**: 时钟到达不同寄存器的时间差。

**公式**:
```
Skew = |T_arrival(FF_i) - T_arrival(FF_j)|

Global Skew = T_max - T_min (所有FF中)
Local Skew = 特定路径间的skew
```

**影响**:

**Setup时序**:
```
T_period ≥ T_logic + T_setup + Skew

有skew → 可用时间减少
```

**Hold时序**:
```
T_hold ≤ T_logic - Skew

Skew过大 → Hold违例!
```

**规范**:
- **优秀**: < 5% T_period (< 15ps @310ps)
- **良好**: < 10% T_period (< 31ps)
- **可接受**: < 15% T_period
- **本项目**: < 5ps (优秀!)

### 3. Clock Tree 拓扑结构

**类型1: H-Tree** ← 本项目使用
```
                    Root
                      │
            ┌─────────┴─────────┐
            │                   │
        Buffer1             Buffer2
            │                   │
      ┌─────┴─────┐       ┌─────┴─────┐
      │           │       │           │
     FF1-9      FF10-18  FF19-27    FF28-35

特点:
- 几何对称 → 低skew
- 路径长度相等
- 适合矩形芯片
```

**类型2: X-Tree**
```
                    Root
                  /  |  \
                 /   |   \
              Buf1  Buf2  Buf3
              /|\   /|\   /|\
            ... ... ... ... ...

特点:
- 树形分支
- 不完全对称
- 适合不规则形状
```

**类型3: Fishbone**
```
Root ─┬─┬─┬─┬─┬─┬─┬─ (主干)
      │ │ │ │ │ │ │ │
      FF FF FF ...   (鱼骨)

特点:
- 简单
- Skew可能较大
- 适合一维布局（如SRAM）
```

### 4. Clock Buffer
**作用**:
1. **驱动能力**: 单个clock port无法驱动几十个FF
2. **延迟匹配**: 通过插入buffer平衡路径
3. **负载隔离**: 避免后级负载影响前级

**选择标准**:

**驱动强度**:
```
BUFx2: 小驱动，低功耗，用于小fanout
BUFx3: 中等
BUFx4: 大驱动，用于主干
BUFx5: 最大，用于root附近

本项目: 组合使用 x2/x3/x4/x5
```

**Delay vs Power**:
```
大buffer: 低延迟，高功耗
小buffer: 高延迟，低功耗

CTS算法自动平衡
```

**LEF定义**:
```lef
MACRO BUFx4_ASAP7_75t_R
    CLASS CORE ;
    SIZE 0.216 BY 0.270 ;  # 4×site宽
    PIN A
        DIRECTION INPUT ;
        CAPACITANCE 2.6 ;   # 大输入电容
    END A
    PIN Y
        DIRECTION OUTPUT ;
        MAX_LOAD 50.0 ;     # 可驱动50fF
    END Y
END BUFx4_ASAP7_75t_R
```

### 5. Clock Latency (时钟延迟)
**定义**: 从时钟源到寄存器的传播延迟。

**组成**:
```
T_latency = T_source + T_network

T_source: 外部时钟到芯片pad的延迟
T_network: CTS插入的buffer链延迟
```

**Ideal vs Propagated Clock**:

**Ideal Clock** (综合/placement时):
```tcl
create_clock -period 310 [get_ports clk]
# 假设时钟瞬间到达所有FF
```

**Propagated Clock** (CTS后):
```tcl
set_propagated_clock [all_clocks]
# 考虑实际buffer延迟
```

**时序影响**:
```
Ideal clock:
  Setup slack = +15.62ps

Propagated clock (CTS后):
  Setup slack = -41.77ps  (变差了!)
  
原因: 真实时钟延迟占用了一部分周期
```

### 6. Clock Tree Levels (层数)
**定义**: Root到leaf的最大buffer级数。

**本项目**: 2层
```
Level 0: Clock input port
Level 1: clkbuf_0_clk (root buffer)
Level 2: clkbuf_2_0__f_clk, clkbuf_2_1__f_clk, ...
Level 3: Registers (35个DFF)
```

**Trade-off**:
```
层数少(1-2层):
  + 延迟小
  + 简单
  - 每层fanout大 → skew可能大

层数多(3-5层):
  + Skew小（每层fanout小）
  - 延迟大
  - 面积/功耗大
```

**自动确定**:
```
CTS算法根据:
- FF数量
- 目标skew
- Buffer驱动能力
自动决定层数
```

### 7. Clock Net
**特殊性**: 时钟网络与普通信号网不同

**特点**:
1. **高fanout**: 一个net连接几十上百FF
2. **高翻转率**: 每周期都翻转
3. **大电容**: 驱动大量负载
4. **对称布线**: 减少skew

**布线要求**:
```tcl
# 时钟用更高层金属(低电阻)
set_routing_layers -clock -min M4 -max M7

# 更宽的线（降低RC）
set_wire_rc -clock -layer M5 \
    -resistance 0.05 \
    -capacitance 0.1

# 专用时钟层（可选）
# 如M5只给时钟用
```

### 8. Useful Skew (有益偏斜)
**概念**: 故意引入skew来改善时序。

**原理**:
```
Setup critical path:
  FF1 → logic → FF2
  
如果让FF2的clk晚到一点:
  FF2有更多时间接收数据
  → Setup slack改善

但要确保Hold不违例!
```

**示例**:
```
原始: Skew = 0, Setup slack = -10ps

Useful skew: 
  FF1 clk: 50ps
  FF2 clk: 60ps (晚10ps)
  → Setup slack = 0ps (刚好满足)
```

**OpenROAD支持**:
```tcl
clock_tree_synthesis \
    -sink_clustering_enable \   # 分簇优化
    -sink_clustering_size 10 \
    -num_static_layers 1        # useful skew优化
```

### 9. Clock Gating (时钟门控)
**定义**: 当部分电路不工作时，关闭其时钟以节省功耗。

**实现**:
```verilog
// RTL层：条件时钟
always @(posedge clk)
    if (enable)
        data <= new_value;

// 综合后：插入时钟门控单元
ICGx1 icg (.CLK(clk), .E(enable), .GCLK(gated_clk));
DFF ff (.CLK(gated_clk), .D(new_value), .Q(data));
```

**ICG单元结构**:
```
        CLK ──┐
              ├─ AND ── GCLK (门控时钟)
    Enable ─>┘
       ↑
     Latch (防止毛刺)
```

**功耗节省**:
```
时钟网络功耗 ≈ C × V² × f × α

α: 翻转率
时钟门控 → α降低 → 功耗↓ 30-50%
```

### 10. Clock Tree报告解读

**示例报告**:
```
Clock Tree Synthesis Report
===========================

Clock: core_clock
  Period: 310ps
  Source: clk (port)

Buffer insertion summary:
  Level 1: 1 buffer  (clkbuf_0_clk)
  Level 2: 4 buffers (clkbuf_2_*__f_clk)
  Total: 5 buffers

Clock distribution:
  Fanout: 35 (registers)
  Total capacitance: 12.5 fF
  Total wire length: 125 um

Skew analysis:
  Global skew: 4.2ps
  Worst local skew: 2.1ps
  
Latency:
  Min: 48.3ps
  Max: 52.5ps
  Average: 50.6ps
```

**关键指标**:
- Skew < 5ps ✓
- Latency ~50ps (合理，2层buffer)
- Wire length 125um (还好，不算长)

## 常见问题

### Q1: CTS后setup timing变差？
**原因**: 
```
Ideal clock → Propagated clock
实际时钟延迟占用了时钟周期

Before CTS (ideal):
  Data path: 200ps
  Clock period: 310ps
  Slack = 310 - 200 = +110ps

After CTS (propagated):
  Data path: 200ps
  Clock latency: 50ps (占用!)
  Effective period: 310 - 50 = 260ps
  Slack = 260 - 200 = +60ps (变差50ps)
```

**正常吗**: 是的，完全正常

**解决**: 
- 后续优化（buffer insertion, gate sizing）
- 或降低时钟频率

### Q2: Buffer库中没有某个buffer？
**错误**:
```
Error: Buffer 'BUFx6_ASAP7_75t_R' not found in LEF
```

**解决**:
```bash
# 查看LEF中实际有哪些buffer
grep "^MACRO BUF" platforms/asap7/lef/*.lef

# 修改脚本使用存在的buffer
set clock_buffer_list {
    BUFx2_ASAP7_75t_R
    BUFx3_ASAP7_75t_R
    BUFx4_ASAP7_75t_R
    BUFx5_ASAP7_75t_R
}
```

### Q3: Skew很大(>50ps)怎么办？
**原因**:
1. FF分布不均（某些很远）
2. Buffer库不合适
3. Placement质量差

**解决**:
```tcl
# 方法1: 更严格的skew约束
clock_tree_synthesis \
    -target_skew 10  # 目标skew 10ps

# 方法2: 增加buffer选择
set clock_buffer_list {... 更多buffer ...}

# 方法3: 重新placement
# 使用-timing_driven改善关键路径
```

### Q4: CTS失败，无法收敛？
**错误**:
```
Error: Cannot meet skew target
```

**检查**:
1. Placement是否合法？
2. Buffer库是否足够？
3. 时钟约束是否正确？

**Workaround**:
```tcl
# 放宽skew要求
clock_tree_synthesis -target_skew 50

# 或增加迭代次数
clock_tree_synthesis -max_iterations 100
```

### Q5: 如何可视化clock tree？
```bash
# OpenROAD GUI
openroad -gui results/cts.odb

# 在GUI中:
# 1. Tools -> Clock Tree Viewer
# 2. 选择clock domain
# 3. 显示tree结构

# 或查看report
report_clock_skew > reports/cts_skew.rpt
report_clock_tree > reports/cts_tree.rpt
```

## 验证检查清单

CTS完成后，检查：

- [ ] Clock buffers已插入(>0)
- [ ] 所有FF都有clock连接
- [ ] Skew在规范内(<10ps)
- [ ] Latency合理(一般几十ps)
- [ ] 时序报告已生成
- [ ] `set_propagated_clock`已设置
- [ ] ODB文件已保存
- [ ] 单元总数增加(原508 → 现516)

## 相关命令参考

### CTS基本用法
```tcl
# 设置buffer列表
set_clock_buffer_list {
    BUFx2_ASAP7_75t_R
    BUFx3_ASAP7_75t_R
    BUFx4_ASAP7_75t_R
}

# 执行CTS
clock_tree_synthesis \
    -root_buf BUFx4_ASAP7_75t_R \  # root用大buffer
    -buf_list $clock_buffer_list \
    -sink_clustering_enable \       # 分簇优化
    -distance_between_buffers 100   # buffer间距(um)
```

### 设置传播时钟
```tcl
# CTS后必须调用！
set_propagated_clock [all_clocks]

# 然后重新时序分析
report_checks -path_delay max
report_checks -path_delay min
```

### 报告命令
```tcl
# 时钟树报告
report_clock_tree

# Skew报告
report_clock_skew > reports/cts_skew.rpt

# 时序（传播后）
report_checks -path_delay max > reports/cts_timing.rpt
```

### 查询CTS结果
```tcl
# 统计插入的buffer
set clock_buffers [get_cells clkbuf_*]
puts "Clock buffers: [llength $clock_buffers]"

# 查看时钟net
set clock_nets [get_nets -of_objects [get_pins -of_objects [get_cells clkbuf_*] -filter "direction==out"]]
puts "Clock nets: [llength $clock_nets]"
```

### 删除CTS（重做）
```tcl
# 移除所有clock buffers
remove_buffers

# 重新运行
clock_tree_synthesis ...
```

## 下一步

CTS完成后，进入 **全局布线 (Global Routing)** 阶段：
→ 参见: [09_10_routing.md](09_10_routing.md)
