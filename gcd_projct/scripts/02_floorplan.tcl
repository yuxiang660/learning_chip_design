# ========================================================================
# OpenROAD Floorplan脚本 - 布图规划
# 将逻辑网表转换为物理布局
# ========================================================================

# 设置路径
set DESIGN_NAME "gcd"
set PLATFORM_DIR "/home/yuxiangw/github/OpenROAD-flow-scripts/flow/platforms/asap7"
set RESULT_DIR "./results"
set REPORT_DIR "./reports"

puts "\n=========================================="
puts "OpenROAD Floorplanning for $DESIGN_NAME"
puts "==========================================\n"

# ========================================================================
# 步骤1：读取库文件（LEF/LIB）
# ========================================================================
puts "Step 1: Reading technology files..."

# LEF = Library Exchange Format (物理信息：单元尺寸、引脚位置等)
# 技术LEF：工艺层信息
read_lef $PLATFORM_DIR/lef/asap7_tech_1x_201209.lef
# 标准单元LEF：单元的物理视图
read_lef $PLATFORM_DIR/lef/asap7sc7p5t_28_R_1x_220121a.lef

# LIB = Liberty格式 (时序信息：延迟、功耗等)
# 读取典型工艺角时序库（TT corner）
read_liberty $PLATFORM_DIR/lib/NLDM/asap7sc7p5t_SEQ_RVT_TT_nldm_220123.lib
read_liberty $PLATFORM_DIR/lib/NLDM/asap7sc7p5t_INVBUF_RVT_TT_nldm_220122.lib.gz
read_liberty $PLATFORM_DIR/lib/NLDM/asap7sc7p5t_SIMPLE_RVT_TT_nldm_211120.lib.gz

puts "  ✓ Technology files loaded\n"

# ========================================================================
# 步骤2：读取综合生成的网表
# ========================================================================
puts "Step 2: Reading synthesized netlist..."

# Verilog网表包含门级连接关系
read_verilog $RESULT_DIR/synth.v
# 链接设计（解析所有模块）
link_design $DESIGN_NAME

puts "  ✓ Netlist loaded and linked\n"

# ========================================================================
# 步骤3：读取约束文件（SDC）
# ========================================================================
puts "Step 3: Reading timing constraints..."

# SDC = Synopsys Design Constraints
# 包含时钟定义、输入输出延迟等
read_sdc /home/yuxiangw/github/OpenROAD-flow-scripts/flow/designs/asap7/gcd/constraint.sdc

puts "  ✓ Constraints loaded\n"

# ========================================================================
# 步骤4：初始化Floorplan
# ========================================================================
puts "Step 4: Initializing floorplan..."

# initialize_floorplan参数说明：
# -die_area: 芯片边界 (x1 y1 x2 y2) 单位：微米
# -core_area: 核心区域（放置标准单元的区域）
# -site: 标准单元放置的最小单位

# 使用官方GCD设计相同的尺寸：16.2um x 16.2um
# DIE_AREA: 0 0 16.2 16.2
# CORE_AREA: 1.08 1.08 15.12 15.12
# 注意：1.08是为了对齐工艺要求

initialize_floorplan \
  -die_area "0 0 16.2 16.2" \
  -core_area "1.08 1.08 15.12 15.12" \
  -site asap7sc7p5t

puts "  ✓ Floorplan initialized"
puts "    Die area:  16.2um x 16.2um"
puts "    Core area: 14.04um x 14.04um\n"

# ========================================================================
# 步骤5：创建routing tracks
# ========================================================================
puts "Step 5: Creating routing tracks..."

# make_tracks为每个金属层创建布线轨道
# 这是place_pins等命令的前提条件
# ASAP7需要手动指定每层的offset和pitch（从官方make_tracks.tcl）

# 高层金属（Pad, M9, M8）
make_tracks Pad -x_offset 0.116 -x_pitch 0.080 -y_offset 0.116 -y_pitch 0.080
make_tracks M9 -x_offset 0.116 -x_pitch 0.080 -y_offset 0.116 -y_pitch 0.080
make_tracks M8 -x_offset 0.116 -x_pitch 0.080 -y_offset 0.116 -y_pitch 0.080

# 中层金属（M7, M6, M5, M4, M3）
make_tracks M7 -x_offset 0.016 -x_pitch 0.064 -y_offset 0.016 -y_pitch 0.064
make_tracks M6 -x_offset 0.012 -x_pitch 0.048 -y_offset 0.016 -y_pitch 0.064
make_tracks M5 -x_offset 0.012 -x_pitch 0.048 -y_offset 0.012 -y_pitch 0.048
make_tracks M4 -x_offset 0.009 -x_pitch 0.036 -y_offset 0.012 -y_pitch 0.048
make_tracks M3 -x_offset 0.009 -x_pitch 0.036 -y_offset 0.009 -y_pitch 0.036

# M2层特殊处理（多个offset以对齐标准单元行）
make_tracks M2 -x_offset 0.009 -x_pitch 0.036 -y_offset 0.045 -y_pitch 0.270
make_tracks M2 -x_offset 0.009 -x_pitch 0.036 -y_offset 0.081 -y_pitch 0.270
make_tracks M2 -x_offset 0.009 -x_pitch 0.036 -y_offset 0.117 -y_pitch 0.270
make_tracks M2 -x_offset 0.009 -x_pitch 0.036 -y_offset 0.153 -y_pitch 0.270
make_tracks M2 -x_offset 0.009 -x_pitch 0.036 -y_offset 0.189 -y_pitch 0.270
make_tracks M2 -x_offset 0.009 -x_pitch 0.036 -y_offset 0.225 -y_pitch 0.270
make_tracks M2 -x_offset 0.009 -x_pitch 0.036 -y_offset 0.270 -y_pitch 0.270

# M1层（最底层，连接标准单元）
make_tracks M1 -x_offset 0.009 -x_pitch 0.036 -y_offset 0.009 -y_pitch 0.036

puts "  ✓ Routing tracks created for all metal layers\n"

# ========================================================================
# 步骤6：输出floorplan结果
# ========================================================================
puts "Step 6: Writing outputs..."

# DEF = Design Exchange Format（物理设计文件）
write_def $RESULT_DIR/floorplan.def

# 生成报告
report_checks -path_delay min_max -format full_clock_expanded \
  > $REPORT_DIR/floorplan_timing.rpt

report_design_area > $REPORT_DIR/floorplan_area.rpt

puts "  ✓ Floorplan results written to:"
puts "    - $RESULT_DIR/floorplan.def"
puts "    - $REPORT_DIR/floorplan_timing.rpt"
puts "    - $REPORT_DIR/floorplan_area.rpt\n"

# ========================================================================
# 设计统计
# ========================================================================
puts "=========================================="
puts "Floorplan Summary:"
puts "==========================================\n"

puts "Design: $DESIGN_NAME"
puts "Die area:  [expr 16.2*16.2] um² (262.44 um²)"
puts "Core area: [expr 14.04*14.04] um² (197.12 um²)"
puts ""

report_design_area

# 保存ODB格式（推荐的中间格式）
write_db $RESULT_DIR/floorplan.odb
puts "\n✓ Saved ODB: results/floorplan.odb (recommended format)"

puts "\n=========================================="
puts "Floorplanning completed!"
puts "=========================================="
puts ""
puts "Note: 官方OpenROAD flow将后续步骤分为独立脚本："
puts "  - tapcell.tcl: 插入tap cells"
puts "  - pdn.tcl: 生成电源分布网络"
puts "  - global_place.tcl: 全局布局"
puts "  - io_placement.tcl: I/O引脚放置"
puts ""
puts "这样设计是为了模块化和可调试性。"
puts "Next: 我们可以创建这些独立脚本继续学习。\n"
exit