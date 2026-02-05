# ========================================================================
# IO Pin Placement - 简化版，直接调用
# ========================================================================

# 设置路径
set PLATFORM_DIR "/home/yuxiangw/github/OpenROAD-flow-scripts/flow/platforms/asap7"
set RESULT_DIR "./results"
set REPORT_DIR "./reports"

puts "\n=========================================="
puts "IO Pin Placement (Simplified)"
puts "=========================================="

# 步骤1：加载设计
puts "\n\[Step 1] Loading design..."

read_lef $PLATFORM_DIR/lef/asap7_tech_1x_201209.lef
read_lef $PLATFORM_DIR/lef/asap7sc7p5t_28_R_1x_220121a.lef
read_db $RESULT_DIR/global_place_skip_io.odb

puts "  ✓ Design loaded"

# 步骤2：检查当前状态
puts "\n\[Step 2] Checking before place_pins..."
set bterm [[ord::get_db_block] findBTerm "clk"]
puts "  clk BPins before: [llength [$bterm getBPins]]"

# 步骤3：执行place_pins
puts "\n\[Step 3] Running place_pins..."
place_pins -hor_layers M4 -ver_layers M5

puts "  ✓ place_pins completed"

# 步骤4：验证结果
puts "\n\[Step 4] Verifying results..."
set bterm [[ord::get_db_block] findBTerm "clk"]
set bpins [$bterm getBPins]
puts "  clk BPins after: [llength $bpins]"

if {[llength $bpins] > 0} {
    foreach bpin $bpins {
        set boxes [$bpin getBoxes]
        puts "  clk has [llength $boxes] boxes"
        if {[llength $boxes] > 0} {
            set box [lindex $boxes 0]
            set layer [[$box getTechLayer] getName]
            puts "  clk layer: $layer"
        }
    }
} else {
    puts "ERROR: No BPins created!"
    exit 1
}

# 检查所有pins
set missing_count 0
foreach bterm [[ord::get_db_block] getBTerms] {
    if {[llength [$bterm getBPins]] == 0} {
        incr missing_count
    }
}

puts "\n  Total pins: [llength [[ord::get_db_block] getBTerms]]"
puts "  Missing BPins: $missing_count"

if {$missing_count > 0} {
    puts "ERROR: Some pins missing BPins!"
    exit 1
}

puts "  ✓ All pins have BPins"

# 步骤5：保存ODB
puts "\n\[Step 5] Saving ODB..."
write_db $RESULT_DIR/io_place_fixed.odb
puts "  ✓ Saved: io_place_fixed.odb"

# 也保存DEF用于参考
write_def $RESULT_DIR/io_place_fixed.def
puts "  ✓ Saved: io_place_fixed.def"

puts "\n=========================================="
puts "IO Placement Completed Successfully!"
puts "=========================================="
puts ""
puts "✓ All pins placed with complete geometry"
puts ""
puts "Next: openroad scripts/detail_place_fixed.tcl"
puts ""

exit
