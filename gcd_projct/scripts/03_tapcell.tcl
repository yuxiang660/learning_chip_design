# ========================================================================
# OpenROAD Tapcell插入脚本 - Tap Cell Insertion
# 插入tap cells和endcap cells
# ========================================================================

# 设置路径
set DESIGN_NAME "gcd"
set PLATFORM_DIR "/home/yuxiangw/github/OpenROAD-flow-scripts/flow/platforms/asap7"
set RESULT_DIR "./results"
set REPORT_DIR "./reports"

puts "\n=========================================="
puts "OpenROAD Tap Cell Insertion for $DESIGN_NAME"
puts "==========================================\n"

# ========================================================================
# 步骤1：读取floorplan结果
# ========================================================================
puts "Step 1: Loading floorplan design..."

# 读取技术文件
read_lef $PLATFORM_DIR/lef/asap7_tech_1x_201209.lef
read_lef $PLATFORM_DIR/lef/asap7sc7p5t_28_R_1x_220121a.lef

# 读取Liberty库
read_liberty $PLATFORM_DIR/lib/NLDM/asap7sc7p5t_SEQ_RVT_TT_nldm_220123.lib
read_liberty $PLATFORM_DIR/lib/NLDM/asap7sc7p5t_INVBUF_RVT_TT_nldm_220122.lib.gz
read_liberty $PLATFORM_DIR/lib/NLDM/asap7sc7p5t_SIMPLE_RVT_TT_nldm_211120.lib.gz

# 读取floorplan ODB（保持完整数据）
read_db $RESULT_DIR/floorplan.odb

puts "  ✓ Floorplan design loaded from ODB\n"

# ========================================================================
# 步骤2：插入Tap Cells和End Cap Cells
# ========================================================================
puts "Step 2: Inserting tap cells and endcap cells..."

# Tap Cell说明：
# - Tap cells连接N阱和P阱到电源/地，防止latch-up效应
# - End cap cells封闭每行的两端，防止DRC violation
# - ASAP7使用同一个单元作为tap cell和endcap

# ASAP7配置：
# - TAP_CELL_NAME: TAPCELL_ASAP7_75t_R
# - Distance: 每隔25个site插入一个tap cell
# - Halo: macro周围的保护区域（我们没有macro）

puts "  Configuration:"
puts "    Tap cell master: TAPCELL_ASAP7_75t_R"
puts "    Endcap master:   TAPCELL_ASAP7_75t_R"
puts "    Distance:        25 sites (~1.35um)"
puts "    Halo X/Y:        2um"

tapcell \
  -distance 25 \
  -tapcell_master "TAPCELL_ASAP7_75t_R" \
  -endcap_master "TAPCELL_ASAP7_75t_R" \
  -halo_width_x 2 \
  -halo_width_y 2

puts "  ✓ Tap cells and endcaps inserted\n"

# ========================================================================
# 步骤3：检查设计
# ========================================================================
puts "Step 3: Checking design..."

# 统计tap cells数量
set tap_count 0
foreach inst [get_cells -hier *] {
  if {[get_property [get_cells $inst] ref_name] == "TAPCELL_ASAP7_75t_R"} {
    incr tap_count
  }
}

puts "  ✓ Total tap/endcap cells inserted: $tap_count\n"

# ========================================================================
# 步骤4：输出结果
# ========================================================================
puts "Step 4: Writing outputs..."

# 输出ODB文件（主要格式）
write_db $RESULT_DIR/tapcell.odb
puts "  ✓ Saved ODB: results/tapcell.odb"

# 输出DEF文件（参考）
write_def $RESULT_DIR/tapcell.def
puts "  ✓ Saved DEF: results/tapcell.def (reference only)"

# 生成报告
report_design_area > $REPORT_DIR/tapcell_area.rpt

puts "  ✓ Results written to:"
puts "    - $RESULT_DIR/tapcell.def"
puts "    - $REPORT_DIR/tapcell_area.rpt\n"

# ========================================================================
# 设计统计
# ========================================================================
puts "=========================================="
puts "Tap Cell Insertion Summary:"
puts "==========================================\n"

puts "Design: $DESIGN_NAME"
puts "Tap/Endcap cells: $tap_count"
puts ""

report_design_area

puts "\n=========================================="
puts "Tap cell insertion completed!"
puts "=========================================="
puts ""
puts "Tap cells作用："
puts "  1. 连接N阱到VDD，防止NMOS latch-up"
puts "  2. 连接P阱到VSS，防止PMOS latch-up"
puts "  3. End caps封闭标准单元行，防止DRC错误"
puts ""
puts "Next: PDN generation (pdn.tcl)\n"
exit