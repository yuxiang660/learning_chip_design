# 步骤1: 综合 (Synthesis)

## 如何运行

```bash
cd /home/yuxiangw/github/learning_openroad/gcd_project
yosys scripts/01_synth.tcl
```

或查看日志：
```bash
yosys scripts/01_synth.tcl 2>&1 | tee logs/01_synth.log
```

**注意**：综合使用 `yosys` 命令而不是 `openroad`。这是因为综合脚本需要在 Yosys shell 中运行，脚本开头有 `yosys -import` 导入 Yosys 命令。

## 输入与输出

### 输入文件
| 文件 | 说明 |
|------|------|
| `rtl/gcd.v` | RTL设计源代码（Verilog） |
| `constraints/synth.sdc` | 综合约束文件（时钟、IO延迟） |
| Liberty文件 (`.lib`) | 标准单元时序库 |

### 输出文件
| 文件 | 说明 |
|------|------|
| `results/synth.v` | 门级网表（映射到标准单元后的网表） |
| `reports/synth_area.rpt` | 面积报告 |
| `reports/synth_timing.rpt` | 时序报告 |
| `logs/01_synth.log` | 详细日志 |

### 关键输出信息
```
Number of cells:        508
Number of registers:    35
Number of gates:        473
Clock period:           310ps (3.2 GHz)
Worst slack:            +15.62ps (MET)
```

## 涉及的EDA概念

### 1. RTL (Register Transfer Level)
**定义**: 寄存器传输级，使用硬件描述语言（HDL）描述电路行为的抽象层次。

**特点**:
- 描述数据在寄存器间的流动和逻辑运算
- 与具体工艺无关
- 易于仿真和验证

**示例**:
```verilog
always @(posedge clk) begin
    if (rst) 
        counter <= 0;
    else
        counter <= counter + 1;
end
```

### 2. 逻辑综合 (Logic Synthesis)
**定义**: 将RTL描述转换为门级网表的过程。

**主要步骤**:
1. **翻译**: 将HDL转换为布尔逻辑表达式
2. **优化**: 最小化逻辑面积/延迟/功耗
3. **映射**: 将优化后的逻辑映射到标准单元库

**工具**: Yosys (开源), Synopsys Design Compiler (商业)

### 3. 标准单元 (Standard Cell)
**定义**: 预先设计和验证的基本逻辑单元（如门电路、触发器）。

**特性**:
- 固定高度（如ASAP7中1行 = 270nm）
- 可变宽度（1x, 2x, 4x等驱动强度）
- 包含物理版图（GDSII）和逻辑模型（Liberty）

**常见单元类型**:
- **组合逻辑**: INVx1（反相器）, NAND2x1, NOR2x1, AOI21x1
- **时序单元**: DFFHQNx1（D触发器）, LATCHx1
- **缓冲**: BUFx2, BUFx4（不同驱动强度）

### 4. Liberty文件 (.lib)
**定义**: 描述标准单元时序、功耗、面积的文本格式文件。

**包含信息**:
- 单元延迟（查找表）
- 输入电容
- 输出转换时间
- 功耗数据
- 时序弧（timing arc）

**示例**:
```liberty
cell (INVx1_ASAP7_75t_R) {
    area : 0.0384;
    pin(A) {
        direction : input;
        capacitance : 0.65;
    }
    pin(Y) {
        direction : output;
        timing() {
            related_pin : "A";
            cell_rise(delay_template) {
                index_1 ("0.01, 0.05, 0.1");  /* input slew */
                index_2 ("0.01, 0.05, 0.1");  /* output load */
                values ("0.02, 0.03, 0.04",
                        "0.03, 0.04, 0.05",
                        "0.04, 0.05, 0.06"); /* delay in ns */
            }
        }
    }
}
```

### 5. SDC约束 (Synopsys Design Constraints)
**定义**: 标准时序约束格式，指定时钟、IO延迟等要求。

**常用命令**:
```tcl
# 定义时钟
create_clock -period 310 -name core_clock [get_ports clk]

# 设置输入延迟（相对于时钟）
set_input_delay -clock core_clock -max 62 [all_inputs]

# 设置输出延迟
set_output_delay -clock core_clock -max 62 [all_outputs]

# 设置负载（驱动能力约束）
set_load 10 [all_outputs]
```

### 6. 门级网表 (Gate-Level Netlist)
**定义**: 综合后的设计，仅包含标准单元实例和连接关系。

**特点**:
- 与工艺相关（映射到具体的标准单元库）
- 可精确进行时序分析
- 用于后续布局布线

**示例**:
```verilog
module gcd (
    input clk,
    input [31:0] req_msg_a,
    output [15:0] resp_msg
);
    wire _000_;
    wire _001_;
    
    INVx1_ASAP7_75t_R _419_ (.A(_759_QN), .Y(_000_));
    NAND2x1_ASAP7_75t_R _420_ (.A(req_msg_a[0]), .B(_000_), .Y(_001_));
    DFFHQNx1_ASAP7_75t_R _759_ (.D(_420_), .CLK(clk), .QN(_759_QN));
endmodule
```

### 7. 时序分析 (Static Timing Analysis, STA)
**定义**: 不需要仿真，通过计算所有路径延迟验证时序约束的方法。

**关键概念**:
- **Setup Time**: 数据在时钟沿前必须稳定的时间
- **Hold Time**: 数据在时钟沿后必须保持的时间
- **Slack**: 裕量，正值表示满足时序，负值表示违例

**Setup检查**:
```
数据到达时间 - 数据要求时间 = Setup Slack
```

**Hold检查**:
```
数据到达时间 - 数据要求时间 = Hold Slack
```

### 8. 时序路径 (Timing Path)
**定义**: 从一个时序起点到终点的信号传播路径。

**路径类型**:
- **Reg2Reg**: 寄存器到寄存器（内部路径）
- **In2Reg**: 输入端口到寄存器
- **Reg2Out**: 寄存器到输出端口
- **In2Out**: 输入到输出（组合逻辑）

**路径组成**:
```
起点(Launch FF) → 组合逻辑云 → 终点(Capture FF)
```

### 9. 优化目标
综合工具在以下目标间权衡：

**面积优化**:
- 减少门数量
- 使用小尺寸单元（x1, x2）

**时序优化**:
- 减少逻辑级数
- 使用大驱动强度单元（x4, x8）
- 插入缓冲器

**功耗优化**:
- 门控时钟
- 减少翻转活动
- 使用低功耗单元

## 常见问题

### Q1: 综合后时序满足，为什么后端又违例？
**原因**: 
- 综合用的是估算的线延迟（Wire Load Model）
- 实际布线后，线长和RC延迟可能更大

**解决**: 
- 综合时留20-30%时序余量
- 使用更紧的时钟约束（over-constraint）

### Q2: 如何选择标准单元库？
**考虑因素**:
- **VT类型**: LVT（快速，高漏电）, RVT（平衡）, HVT（慢速，低漏电）
- **驱动强度**: x1（小面积）, x4（大驱动力）
- **功能**: 简单门 vs 复杂AOI/OAI

**本项目**: 使用RVT（Regular VT）平衡库

### Q3: 综合时内存不够怎么办？
**优化方法**:
- 分层次综合（Hierarchical Synthesis）
- 减小ungroup深度
- 使用compile_ultra代替compile

### Q4: 如何提高综合速度？
```tcl
# 使用多线程（如果工具支持）
set_host_options -max_cores 8

# 减少优化迭代
set compile_effort low

# 禁用部分优化
set_dont_touch [get_cells non_critical_*]
```

## 验证检查清单

综合完成后，检查以下内容：

- [ ] 网表文件已生成（synth.v存在）
- [ ] 无语法错误或未解析的引用
- [ ] 所有输入输出端口存在
- [ ] 时序报告显示slack为正（或接近0）
- [ ] 门数量合理（未出现异常膨胀）
- [ ] 关键路径识别正确
- [ ] 时钟定义正确（频率、占空比）
- [ ] 无latch推断（除非有意为之）

## 相关命令参考

### Yosys综合流程
```tcl
# 读取设计
read_verilog rtl/gcd.v

# 层次检查
hierarchy -check -top gcd

# 处理进程块
proc

# 优化
opt

# FSM提取和优化
fsm
fsm_map

# 技术映射
techmap

# ABC优化
abc -liberty $liberty_file

# 写出网表
write_verilog results/synth.v
```

### OpenSTA时序分析
```tcl
# 读取库和网表
read_liberty asap7.lib
read_verilog synth.v
link_design gcd

# 读取约束
read_sdc constraints.sdc

# 报告时序
report_checks -path_delay max
report_checks -path_delay min
report_tns
report_wns
```

## 下一步

综合完成后，进入 **布图规划 (Floorplan)** 阶段：
→ 参见: [02_floorplan.md](02_floorplan.md)
