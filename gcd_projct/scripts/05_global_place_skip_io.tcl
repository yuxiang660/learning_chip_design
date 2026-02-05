# ========================================================================
# OpenROAD全局布局脚本(跳过IO) - Global Placement Skip IO
# 粗略放置标准单元，但不放置I/O引脚
# ========================================================================

# 设置路径
set DESIGN_NAME "gcd"
set PLATFORM_DIR "/home/yuxiangw/github/OpenROAD-flow-scripts/flow/platforms/asap7"
set RESULT_DIR "./results"
set REPORT_DIR "./reports"

puts "\n=========================================="
puts "OpenROAD Global Placement (Skip IO) for $DESIGN_NAME"
puts "==========================================\n"

# ========================================================================
# 步骤1：读取PDN结果
# ========================================================================
puts "Step 1: Loading design with PDN..."

# 读取技术文件
read_lef $PLATFORM_DIR/lef/asap7_tech_1x_201209.lef
read_lef $PLATFORM_DIR/lef/asap7sc7p5t_28_R_1x_220121a.lef

# 读取Liberty库（TT corner）
read_liberty $PLATFORM_DIR/lib/NLDM/asap7sc7p5t_SEQ_RVT_TT_nldm_220123.lib
read_liberty $PLATFORM_DIR/lib/NLDM/asap7sc7p5t_INVBUF_RVT_TT_nldm_220122.lib.gz
read_liberty $PLATFORM_DIR/lib/NLDM/asap7sc7p5t_SIMPLE_RVT_TT_nldm_211120.lib.gz

# 读取PDN ODB（保持完整数据）
read_db $RESULT_DIR/pdn.odb

# 读取约束
read_sdc /home/yuxiangw/github/OpenROAD-flow-scripts/flow/designs/asap7/gcd/constraint.sdc

puts "  ✓ Design loaded from ODB\n"

# ========================================================================
# 步骤2：配置全局布局参数
# ========================================================================
puts "Step 2: Configuring global placement parameters..."

# 全局布局参数：
# - density: 目标密度 (0.35 = 35%的区域被单元占用)
# - pad_left/right: 单元间的padding（以sites为单位）
# - skip_io: 跳过I/O引脚放置

set PLACE_DENSITY 0.35
set CELL_PAD 0

puts "  Configuration:"
puts "    Target density:  $PLACE_DENSITY (35%)"
puts "    Cell padding:    $CELL_PAD sites"
puts "    Skip I/O:        Yes\n"

# ========================================================================
# 步骤3：执行全局布局
# ========================================================================
puts "Step 3: Running global placement (without I/O pins)..."

# global_placement命令：
# - 使用分析放置算法（analytical placement）
# - 最小化总线长（wirelength）
# - 满足密度约束
# - 避免单元重叠

puts "  Starting placement algorithm..."
puts "  (This may take a moment...)\n"

global_placement \
  -skip_io \
  -density $PLACE_DENSITY \
  -pad_left $CELL_PAD \
  -pad_right $CELL_PAD

puts "  ✓ Global placement completed\n"

# ========================================================================
# 步骤4：检查布局结果
# ========================================================================
puts "Step 4: Checking placement results..."

# 统计放置的单元（通过ODB API）
set block [ord::get_db_block]
set placed_count 0
set total_count 0

foreach inst [$block getInsts] {
  incr total_count
  set status [$inst getPlacementStatus]
  if { $status == "PLACED" || $status == "FIRM" || $status == "LOCKED" } {
    incr placed_count
  }
}

puts "  Placement statistics:"
puts "    Total cells:   $total_count"
puts "    Placed cells:  $placed_count"
puts "    Placement %:   [format "%.1f%%" [expr {100.0 * $placed_count / $total_count}]]\n"

# ========================================================================
# 步骤5：输出结果
# ========================================================================
puts "Step 5: Writing outputs..."

# 输出ODB文件（主要格式）
write_db $RESULT_DIR/global_place_skip_io.odb
puts "  ✓ Saved ODB: results/global_place_skip_io.odb"

# 输出DEF文件（参考）
write_def $RESULT_DIR/global_place_skip_io.def
puts "  ✓ Saved DEF: results/global_place_skip_io.def (reference only)"

# 生成报告
report_design_area > $REPORT_DIR/global_place_skip_io_area.rpt

puts "  ✓ Results written to:"
puts "    - $RESULT_DIR/global_place_skip_io.def"
puts "    - $REPORT_DIR/global_place_skip_io_area.rpt\n"

# ========================================================================
# 设计统计
# ========================================================================
puts "=========================================="
puts "Global Placement (Skip IO) Summary:"
puts "==========================================\n"

puts "Design: $DESIGN_NAME"
puts "Placement density: $PLACE_DENSITY"
puts ""

report_design_area

puts "\n=========================================="
puts "Global placement (skip IO) completed!"
puts "=========================================="
puts ""
puts "Global Placement作用："
puts "  1. 将所有标准单元放置到大致位置"
puts "  2. 优化总线长，减少互连延迟"
puts "  3. 满足密度约束，避免拥塞"
puts "  4. 为详细布局提供良好的初始解"
puts ""
puts "Next: I/O pin placement (io_place.tcl)\n"

exit
