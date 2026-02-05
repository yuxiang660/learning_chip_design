# ========================================================================
# OpenROAD PDN生成脚本 - Power Distribution Network Generation
# 创建电源分布网络
# ========================================================================

# 设置路径
set DESIGN_NAME "gcd"
set PLATFORM_DIR "/home/yuxiangw/github/OpenROAD-flow-scripts/flow/platforms/asap7"
set RESULT_DIR "./results"
set REPORT_DIR "./reports"

puts "\n=========================================="
puts "OpenROAD PDN Generation for $DESIGN_NAME"
puts "==========================================\n"

# ========================================================================
# 步骤1：读取tapcell结果
# ========================================================================
puts "Step 1: Loading design with tap cells..."

# 读取技术文件
read_lef $PLATFORM_DIR/lef/asap7_tech_1x_201209.lef
read_lef $PLATFORM_DIR/lef/asap7sc7p5t_28_R_1x_220121a.lef

# 读取Liberty库
read_liberty $PLATFORM_DIR/lib/NLDM/asap7sc7p5t_SEQ_RVT_TT_nldm_220123.lib
read_liberty $PLATFORM_DIR/lib/NLDM/asap7sc7p5t_INVBUF_RVT_TT_nldm_220122.lib.gz
read_liberty $PLATFORM_DIR/lib/NLDM/asap7sc7p5t_SIMPLE_RVT_TT_nldm_211120.lib.gz

# 读取tapcell ODB（保持完整数据）
read_db $RESULT_DIR/tapcell.odb

# 读取约束（需要用于后续时序分析）
read_sdc /home/yuxiangw/github/OpenROAD-flow-scripts/flow/designs/asap7/gcd/constraint.sdc

puts "  ✓ Design loaded from ODB\n"

# ========================================================================
# 步骤2：配置PDN参数
# ========================================================================
puts "Step 2: Configuring PDN parameters..."

# PDN配置（来自ASAP7平台）
set ::halo 2
set ::rails_start_with "POWER"
set ::stripes_start_with "POWER"
set ::power_nets "VDD"
set ::ground_nets "VSS"

puts "  Configuration:"
puts "    Power nets:   $::power_nets"
puts "    Ground nets:  $::ground_nets"
puts "    Rails start:  $::rails_start_with"
puts "    Stripes start: $::stripes_start_with"
puts "    Halo:         $::halo um\n"

# ========================================================================
# 步骤3：定义PDN Grid Strategy
# ========================================================================
puts "Step 3: Defining power grid strategy..."

# 3.1 Global connections（全局电源连接）
# 将所有标准单元的VDD/VSS引脚连接到对应的电源网络
add_global_connection -net {VDD} -inst_pattern {.*} -pin_pattern {^VDD$} -power
add_global_connection -net {VDD} -inst_pattern {.*} -pin_pattern {^VDDPE$}
add_global_connection -net {VDD} -inst_pattern {.*} -pin_pattern {^VDDCE$}
add_global_connection -net {VSS} -inst_pattern {.*} -pin_pattern {^VSS$} -ground
add_global_connection -net {VSS} -inst_pattern {.*} -pin_pattern {^VSSE$}
global_connect

puts "  ✓ Global connections defined"

# 3.2 Voltage domain（电压域）
set_voltage_domain -name {CORE} -power {VDD} -ground {VSS}

puts "  ✓ Voltage domain defined"

# 3.3 Standard cell grid（标准单元电源网格）
# 定义核心区域的电源分布
define_pdn_grid -name {top} -voltage_domains {CORE} -pins {M6}

# M1层：跟随标准单元行的电源轨（followpins）
# width: 0.018um, pitch: 0.54um (每个标准单元行)
add_pdn_stripe -grid {top} -layer {M1} -width {0.018} -pitch {0.54} -offset {0} -followpins

# M2层：跟随标准单元行（水平）
add_pdn_stripe -grid {top} -layer {M2} -width {0.018} -pitch {0.54} -offset {0} -followpins

# M5层：垂直stripes（较粗的电源线）
# width: 0.12um, spacing: 0.072um, pitch: 5.4um
add_pdn_stripe -grid {top} -layer {M5} -width {0.12} -spacing {0.072} -pitch {5.4} -offset {0.300}

# M6层：水平stripes（顶层电源环）
# width: 0.288um, spacing: 0.096um, pitch: 5.4um
add_pdn_stripe -grid {top} -layer {M6} -width {0.288} -spacing {0.096} -pitch {5.4} -offset {0.513}

# 定义各层之间的连接（via）
add_pdn_connect -grid {top} -layers {M1 M2}
add_pdn_connect -grid {top} -layers {M2 M5}
add_pdn_connect -grid {top} -layers {M5 M6}

puts "  ✓ PDN grid strategy defined"
puts "    - M1/M2: Power rails (follow pins, 0.018um width)"
puts "    - M5:    Vertical stripes (0.12um width, 5.4um pitch)"
puts "    - M6:    Horizontal stripes (0.288um width, 5.4um pitch)\n"

# ========================================================================
# 步骤4：生成PDN
# ========================================================================
puts "Step 4: Generating power distribution network..."

# pdngen命令实际执行PDN生成
pdngen

puts "  ✓ PDN generated\n"

# ========================================================================
# 步骤5：检查PDN
# ========================================================================
puts "Step 5: Checking power grid..."

# 检查所有电源网络
set block [ord::get_db_block]
set power_net_count 0
set ground_net_count 0

foreach net [$block getNets] {
  set type [$net getSigType]
  if { $type == "POWER" } {
    incr power_net_count
    puts "  Power net: [$net getName]"
  } elseif { $type == "GROUND" } {
    incr ground_net_count
    puts "  Ground net: [$net getName]"
  }
}

puts "  ✓ Found $power_net_count power nets, $ground_net_count ground nets\n"

# ========================================================================
# 步骤6：输出结果
# ========================================================================
puts "Step 6: Writing outputs..."

# 输出ODB文件（主要格式）
write_db $RESULT_DIR/pdn.odb
puts "  ✓ Saved ODB: results/pdn.odb"

# 输出DEF文件（参考）
write_def $RESULT_DIR/pdn.def
puts "  ✓ Saved DEF: results/pdn.def (reference only)"

# 生成报告
report_design_area > $REPORT_DIR/pdn_area.rpt

puts "  ✓ Results written to:"
puts "    - $RESULT_DIR/pdn.def"
puts "    - $REPORT_DIR/pdn_area.rpt\n"

# ========================================================================
# 设计统计
# ========================================================================
puts "=========================================="
puts "PDN Generation Summary:"
puts "==========================================\n"

puts "Design: $DESIGN_NAME"
puts "Power distribution network layers:"
puts "  M1/M2: Standard cell power rails (0.54um pitch)"
puts "  M5:    Vertical power stripes (5.4um pitch)"
puts "  M6:    Horizontal power stripes (5.4um pitch)"
puts ""

report_design_area

puts "\n=========================================="
puts "PDN generation completed!"
puts "=========================================="
puts ""
puts "PDN作用："
puts "  1. 将VDD/VSS从I/O pads分布到所有标准单元"
puts "  2. 提供低阻抗的电源路径，降低IR drop"
puts "  3. 多层金属网格提供冗余路径，提高可靠性"
puts ""
puts "Next: Global placement (global_place.tcl)\n"

exit
