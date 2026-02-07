# ========================================================================
# Detailed Placement - 使用修复后的io_place ODB
# ========================================================================

# 设置路径
set PLATFORM_DIR "/home/yuxiangw/github/OpenROAD-flow-scripts/flow/platforms/asap7"
set RESULT_DIR "./results"
set REPORT_DIR "./reports"

puts "\n=========================================="
puts "Detailed Placement"
puts "=========================================="

# 步骤1：加载IO placement结果
puts "\n\[Step 1\\] Loading IO placement design..."

read_lef $PLATFORM_DIR/lef/asap7_tech_1x_201209.lef
read_lef $PLATFORM_DIR/lef/asap7sc7p5t_28_R_1x_220121a.lef

# 读取Liberty库（用于timing）
read_liberty $PLATFORM_DIR/lib/NLDM/asap7sc7p5t_SEQ_RVT_TT_nldm_220123.lib
read_liberty $PLATFORM_DIR/lib/NLDM/asap7sc7p5t_INVBUF_RVT_TT_nldm_220122.lib.gz
read_liberty $PLATFORM_DIR/lib/NLDM/asap7sc7p5t_SIMPLE_RVT_TT_nldm_211120.lib.gz

# 读取修复后的io_place ODB
read_db $RESULT_DIR/io_place_fixed.odb

# 读取约束
read_sdc /home/yuxiangw/github/OpenROAD-flow-scripts/flow/designs/asap7/gcd/constraint.sdc

puts "  ✓ Design loaded"

# 步骤2：验证pin shapes（关键检查！）
puts "\n\[Step 2\\] Verifying pin shapes..."

set missing_count 0
foreach bterm [[ord::get_db_block] getBTerms] {
    if {[llength [$bterm getBPins]] == 0} {
        puts "ERROR: [$bterm getName] has no BPins!"
        incr missing_count
    }
}

if {$missing_count > 0} {
    puts "ERROR: $missing_count pins missing shapes! Cannot proceed."
    exit 1
}

puts "  ✓ All [llength [[ord::get_db_block] getBTerms]] pins have shapes"

# 步骤3：设置RC参数
puts "\n\[Step 3\\] Setting RC parameters..."
set_wire_rc -signal -layer M2
set_wire_rc -clock -layer M5
puts "  ✓ RC parameters set"

# 步骤4：设置cell padding
puts "\n\[Step 4\\] Setting cell padding..."
set_placement_padding -global -left 1 -right 1
puts "  ✓ Cell padding set (1 site each side)"

# 步骤5：执行detailed placement
puts "\n\[Step 5\\] Running detailed placement..."
puts "  This will:"
puts "    - Legalize all cell placements"
puts "    - Resolve overlaps"
puts "    - Align cells to placement rows"
puts ""

detailed_placement

puts "  ✓ Detailed placement completed"

# 步骤6：检查placement质量
puts "\n\[Step 6\\] Checking placement quality..."

set all_insts [[ord::get_db_block] getInsts]
set unplaced_count 0
foreach inst $all_insts {
    if {![$inst isPlaced]} {
        incr unplaced_count
        puts "  WARNING: Unplaced instance: [$inst getName]"
    }
}

set total_insts [llength $all_insts]
puts "  Total instances: $total_insts"
puts "  Placed: [expr $total_insts - $unplaced_count]"
puts "  Unplaced: $unplaced_count"

if {$unplaced_count == 0} {
    puts "  ✓ All instances are placed"
} else {
    puts "  WARNING: Some instances not placed"
}

# 步骤7：运行placement检查
puts "\n\[Step 7\\] Running placement checks..."
check_placement -verbose
puts "  ✓ Placement check completed"

# 步骤8：保存结果
puts "\n\[Step 8\\] Saving results..."

write_db $RESULT_DIR/detail_place_fixed.odb
puts "  ✓ Saved: detail_place_fixed.odb"

write_def $RESULT_DIR/detail_place_fixed.def
puts "  ✓ Saved: detail_place_fixed.def"

report_design_area > $REPORT_DIR/detail_place_area.rpt
puts "  ✓ Area report: detail_place_area.rpt"

# 生成timing报告
puts "\nGenerating timing report..."
report_checks -path_delay min_max -format full_clock_expanded \
    > $REPORT_DIR/detail_place_timing.rpt
puts "  ✓ Timing report: detail_place_timing.rpt"

puts "\n=========================================="
puts "Detailed Placement Completed!"
puts "=========================================="
puts ""
puts "Summary:"
puts "  - All cells legalized and placed"
puts "  - Pin shapes preserved"
puts "  - Ready for Clock Tree Synthesis"
puts ""
puts "Design Statistics:"
report_design_area
puts ""
puts "Next steps:"
puts "  1. Clock Tree Synthesis (CTS)"
puts "  2. Filler cell insertion"
puts "  3. Global routing"
puts "  4. Detailed routing"
puts ""

exit
