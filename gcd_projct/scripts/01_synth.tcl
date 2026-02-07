# ========================================================================
# Yosys综合脚本 - 手动版
# 这个脚本将RTL代码转换为门级网表
# ========================================================================

# 导入Yosys命令（关键！）
yosys -import

# 设置路径变量
set PLATFORM_DIR "/home/yuxiangw/github/OpenROAD-flow-scripts/flow/platforms/asap7"
set DESIGN_DIR "/home/yuxiangw/github/OpenROAD-flow-scripts/flow/designs/src/gcd"
set RESULT_DIR "./results"
set SCRIPT_DIR "/home/yuxiangw/github/OpenROAD-flow-scripts/flow/scripts"

# 库文件路径 - 使用FF corner（Fast-Fast，最快工艺角）
# 注意：综合通常用FF corner，以确保最坏情况下也能满足时序
set LIB_DIR "$PLATFORM_DIR/lib/NLDM"
set AO_LIB "$LIB_DIR/asap7sc7p5t_AO_RVT_FF_nldm_211120.lib.gz"
set INVBUF_LIB "$LIB_DIR/asap7sc7p5t_INVBUF_RVT_FF_nldm_220122.lib.gz"
set OA_LIB "$LIB_DIR/asap7sc7p5t_OA_RVT_FF_nldm_211120.lib.gz"
set SIMPLE_LIB "$LIB_DIR/asap7sc7p5t_SIMPLE_RVT_FF_nldm_211120.lib.gz"
set SEQ_LIB "$LIB_DIR/asap7sc7p5t_SEQ_RVT_FF_nldm_220123.lib"

# ABC脚本和约束
set ABC_SCRIPT "$SCRIPT_DIR/abc_speed.script"

# 时钟周期约束（单位：ps）
set CLOCK_PERIOD 310

# ========================================================================
# 步骤1：读取RTL设计
# ========================================================================
puts "\n=========================================="
puts "Step 1: Reading RTL design..."
puts "==========================================\n"

# read_verilog：读取Verilog源文件
read_verilog $DESIGN_DIR/gcd.v

# ========================================================================
# 步骤2：设置顶层模块并建立层次结构
# ========================================================================
puts "\n=========================================="
puts "Step 2: Setting top module..."
puts "==========================================\n"

# hierarchy：建立模块层次结构
# -check：检查是否所有模块都被定义
# -top gcd：指定顶层模块名
hierarchy -check -top gcd

# ========================================================================
# 步骤3：高层次综合 - 使用synth命令（关键！）
# ========================================================================
puts "\n=========================================="
puts "Step 3: High-level synthesis..."
puts "==========================================\n"

# 使用Yosys的synth命令进行综合
# -flatten: 展平层次结构
# -run :fine: 运行从开始到fine阶段（包括proc, opt, memory, fsm等）
puts "  3.1 Running synthesis with flatten..."
synth -flatten -run :fine -top gcd

puts "  3.2 Removing formal constructs..."
chformal -remove

# renames命令在某些Yosys版本中不可用，跳过
# puts "  3.3 Renaming wires..."
# yosys renames -wire

puts "  3.3 General optimization..."
opt -purge

# ========================================================================
# 步骤4：技术映射准备
# ========================================================================
puts "\n=========================================="
puts "Step 4: Preparing for technology mapping..."
puts "==========================================\n"

# 创建ABC约束文件
puts "  4.1 Creating ABC constraints..."
set ABC_CONSTR_FILE "./objects/abc.constr"
file mkdir "./objects"
set constr_fp [open $ABC_CONSTR_FILE w]
puts $constr_fp "set_driving_cell BUFx2_ASAP7_75t_R"
puts $constr_fp "set_load 0.01"
close $constr_fp
puts "      Constraint file: $ABC_CONSTR_FILE"

# 完成综合的fine阶段
puts "  4.2 Running fine synthesis stage..."
synth -top gcd -run fine:

# ========================================================================
# 步骤5：技术映射 - 映射到ASAP7标准单元库
# ========================================================================
puts "\n=========================================="
puts "Step 5: Technology mapping..."
puts "==========================================\n"

# 先映射触发器（FF）
puts "  5.1 Mapping flip-flops..."
dfflibmap -liberty $SEQ_LIB

# 设置未定义值为常数（避免X态）
puts "  5.2 Setting undefined values..."
setundef -zero

# 使用ABC进行组合逻辑映射
puts "  5.3 Mapping combinational logic with ABC..."
puts "      Using ABC script: $ABC_SCRIPT"
puts "      Target clock period: ${CLOCK_PERIOD}ps"
puts "      Constraint file: $ABC_CONSTR_FILE"

# ABC映射命令 - 完全模仿官方流程
abc \
  -script $ABC_SCRIPT \
  -liberty $AO_LIB \
  -liberty $INVBUF_LIB \
  -liberty $OA_LIB \
  -liberty $SIMPLE_LIB \
  -liberty $SEQ_LIB \
  -dont_use "*x1p*_ASAP7*" \
  -dont_use "*xp*_ASAP7*" \
  -dont_use "SDF*" \
  -dont_use "ICG*" \
  -constr $ABC_CONSTR_FILE \
  -D $CLOCK_PERIOD

puts "      ✓ ABC mapping completed"

# 分离多bit信号
puts "  5.4 Splitting multi-bit nets..."
splitnets

# 最终清理
puts "  5.5 Final cleanup..."
opt_clean -purge

# 映射高/低常数
puts "  5.6 Mapping constant drivers..."
hilomap -hicell "TIEHIx1_ASAP7_75t_R" H -locell "TIELOx1_ASAP7_75t_R" L

# 插入buffer以解决fanout问题
puts "  5.7 Inserting buffers..."
insbuf -buf "BUFx2_ASAP7_75t_R" A Y

# 最终清理
puts "  5.8 Final cleanup after all mapping..."
clean

# ========================================================================
# 步骤6：后处理和清理
# ========================================================================
puts "\n=========================================="
puts "Step 6: Post-processing..."
puts "==========================================\n"

# clean：清理网表
puts "  6.1 Cleaning netlist..."
clean

# opt_clean：优化和清理
puts "  6.2 Final cleanup..."
opt_clean -purge

# ========================================================================
# 步骤7：输出门级网表
# ========================================================================
puts "\n=========================================="
puts "Step 7: Writing netlist..."
puts "==========================================\n"

# write_verilog：写出门级网表
# -noattr：不输出Yosys的内部属性
# -noexpr：不使用Verilog表达式，用基本门
write_verilog -noattr -noexpr $RESULT_DIR/synth.v

puts "Netlist written to: $RESULT_DIR/synth.v"

# ========================================================================
# 步骤8：统计和报告
# ========================================================================
puts "\n=========================================="
puts "Step 8: Generating statistics..."
puts "==========================================\n"

# stat：统计信息
# -liberty：使用库文件计算面积（使用所有库）
stat \
  -liberty $AO_LIB \
  -liberty $INVBUF_LIB \
  -liberty $OA_LIB \
  -liberty $SIMPLE_LIB \
  -liberty $SEQ_LIB

# check：检查设计
puts "\nChecking design..."
check

puts "\n=========================================="
puts "Synthesis completed successfully!"
puts "==========================================\n"
puts "Output files:"
puts "  - Netlist: $RESULT_DIR/synth.v"
puts "  - Log: See terminal output"
puts "\nNext step: Run floorplanning"
puts "=========================================="
