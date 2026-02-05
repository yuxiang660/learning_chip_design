# ========================================================================
# Clock Tree Synthesis (CTS) - 时钟树综合
# ========================================================================

# 设置路径
set PLATFORM_DIR "/home/yuxiangw/github/OpenROAD-flow-scripts/flow/platforms/asap7"
set RESULT_DIR "./results"
set REPORT_DIR "./reports"

puts "\n=========================================="
puts "Clock Tree Synthesis (CTS)"
puts "=========================================="

# 步骤1：加载Detailed Placement结果
puts "\n\[Step 1\\] Loading detailed placement design..."

read_lef $PLATFORM_DIR/lef/asap7_tech_1x_201209.lef
read_lef $PLATFORM_DIR/lef/asap7sc7p5t_28_R_1x_220121a.lef

# 读取Liberty库
read_liberty $PLATFORM_DIR/lib/NLDM/asap7sc7p5t_SEQ_RVT_TT_nldm_220123.lib
read_liberty $PLATFORM_DIR/lib/NLDM/asap7sc7p5t_INVBUF_RVT_TT_nldm_220122.lib.gz
read_liberty $PLATFORM_DIR/lib/NLDM/asap7sc7p5t_SIMPLE_RVT_TT_nldm_211120.lib.gz

# 读取详细布局结果
read_db $RESULT_DIR/detail_place_fixed.odb

# 读取约束
read_sdc /home/yuxiangw/github/OpenROAD-flow-scripts/flow/designs/asap7/gcd/constraint.sdc

puts "  ✓ Design loaded"

# 步骤2：设置RC参数
puts "\n\[Step 2\\] Setting RC parameters..."
set_wire_rc -signal -layer M2
set_wire_rc -clock -layer M5
puts "  ✓ RC parameters set"

# 步骤3：检查时钟网络
puts "\n\[Step 3\\] Analyzing clock network..."

# 获取时钟信息
set clocks [all_clocks]
puts "  Clock nets found: [llength $clocks]"
foreach clk $clocks {
    set clk_name [get_name $clk]
    set clk_period [get_property $clk period]
    puts "    - $clk_name: period = $clk_period ps"
}

# 报告CTS前的时序
puts "\n  Timing before CTS (ideal clock):"
report_worst_slack -max
report_worst_slack -min

# 步骤4：修复时钟反相器
puts "\n\[Step 4\\] Repairing clock inverters..."
# Clone clock tree inverters next to register loads
# so CTS does not try to buffer the inverted clocks
repair_clock_inverters
puts "  ✓ Clock inverters repaired"

# 步骤5：执行时钟树综合
puts "\n\[Step 5\\] Running clock tree synthesis..."
puts "  This will:"
puts "    - Insert clock buffers"
puts "    - Balance clock delays"
puts "    - Minimize clock skew"
puts ""

# CTS参数说明：
# -sink_clustering_enable: 启用sink聚类以减少buffer数量
# -sink_clustering_size: 每个cluster的最大sink数量
# -sink_clustering_max_diameter: cluster的最大直径(um)
# -buf_list: 可用的buffer列表
# -root_buf: 时钟根buffer

# 设置可用的buffer
# ASAP7中常用的buffer: BUFx2, BUFx4, BUFx5等
# 注意：使用库中实际存在的cell名称
set cts_buffer_list "BUFx2_ASAP7_75t_R BUFx3_ASAP7_75t_R BUFx4_ASAP7_75t_R BUFx5_ASAP7_75t_R"

clock_tree_synthesis \
    -buf_list $cts_buffer_list \
    -root_buf BUFx4_ASAP7_75t_R \
    -sink_clustering_enable \
    -sink_clustering_size 10 \
    -sink_clustering_max_diameter 5.0

puts "  ✓ Clock tree synthesis completed"

# 步骤6：设置寄生参数并估算
puts "\n\[Step 6\\] Estimating parasitics..."
estimate_parasitics -placement
puts "  ✓ Parasitics estimated"

# 步骤7：报告CTS结果
puts "\n\[Step 7\\] Analyzing CTS results..."

# 统计插入的buffer
set all_insts [[ord::get_db_block] getInsts]
set buf_count 0
set reg_count 0
foreach inst $all_insts {
    set master_name [[$inst getMaster] getName]
    if {[string match "*BUF*" $master_name] || [string match "*CLKBUF*" $master_name]} {
        incr buf_count
    }
    if {[string match "*DFF*" $master_name]} {
        incr reg_count
    }
}

puts "  Instances:"
puts "    Total: [llength $all_insts]"
puts "    Registers: $reg_count"
puts "    Clock buffers: $buf_count"

# 报告时钟skew
puts "\n  Clock skew report:"
report_clock_skew

# 报告CTS后的时序
puts "\n  Timing after CTS (with clock tree):"
report_worst_slack -max
report_worst_slack -min

# 步骤8：重新运行详细布局（因为插入了新的buffer）
puts "\n\[Step 8\\] Re-running detailed placement..."
set_placement_padding -global -left 1 -right 1
detailed_placement
puts "  ✓ Detailed placement completed"

# 步骤9：保存结果
puts "\n\[Step 9\\] Saving results..."

write_db $RESULT_DIR/cts.odb
puts "  ✓ Saved: cts.odb"

write_def $RESULT_DIR/cts.def
puts "  ✓ Saved: cts.def"

report_design_area > $REPORT_DIR/cts_area.rpt
puts "  ✓ Area report: cts_area.rpt"

# 生成详细的时钟树报告
report_clock_skew > $REPORT_DIR/cts_skew.rpt
puts "  ✓ Clock skew report: cts_skew.rpt"

# 生成时序报告
report_checks -path_delay min_max -format full_clock_expanded \
    > $REPORT_DIR/cts_timing.rpt
puts "  ✓ Timing report: cts_timing.rpt"

puts "\n=========================================="
puts "Clock Tree Synthesis Completed!"
puts "=========================================="
puts ""
puts "Summary:"
puts "  - Clock buffers inserted: $buf_count"
puts "  - Clock tree balanced"
puts "  - Ready for Routing"
puts ""
puts "Design Statistics:"
report_design_area
puts ""
puts "Next steps:"
puts "  1. Global routing"
puts "  2. Detailed routing"
puts "  3. Filler cell insertion"
puts "  4. Final checks and GDSII"
puts ""

exit
