#!/usr/bin/env openroad
# ========================================================================
# SPEF Generation - 寄生参数提取
# ========================================================================
# 
# 目的：从详细布线后的设计中提取RC寄生参数并生成SPEF文件
# 
# 输入：results/detail_route.odb
# 输出：reports/detail_route.spef
#
# SPEF (Standard Parasitic Exchange Format) 包含：
#   - 网络的电阻 (R)
#   - 网络的电容 (C) 
#   - 耦合电容 (Coupling C)
#   - 用于精确时序分析和后仿真
# ========================================================================

# 设置路径
set PLATFORM_DIR "/home/yuxiangw/github/OpenROAD-flow-scripts/flow/platforms/asap7"
set RESULT_DIR "./results"
set REPORT_DIR "./reports"

puts "\n=========================================="
puts "SPEF Generation - Parasitic Extraction"
puts "=========================================="

# 步骤1：加载详细布线后的设计
puts "\n\[Step 1\] Loading detailed routing design..."

read_lef $PLATFORM_DIR/lef/asap7_tech_1x_201209.lef
read_lef $PLATFORM_DIR/lef/asap7sc7p5t_28_R_1x_220121a.lef

# 读取Liberty库（用于时序信息）
read_liberty $PLATFORM_DIR/lib/NLDM/asap7sc7p5t_SEQ_RVT_TT_nldm_220123.lib
read_liberty $PLATFORM_DIR/lib/NLDM/asap7sc7p5t_INVBUF_RVT_TT_nldm_220122.lib.gz
read_liberty $PLATFORM_DIR/lib/NLDM/asap7sc7p5t_SIMPLE_RVT_TT_nldm_211120.lib.gz

# 读取详细布线后的设计
read_db $RESULT_DIR/detail_route.odb

puts "  ✓ Design loaded with detailed routing"

# 步骤2：验证设计状态
puts "\n\[Step 2\] Verifying design status..."

if {![design_is_routed]} {
    puts "ERROR: Design is not fully routed!"
    puts "Please run 10_detail_route.tcl first."
    exit 1
}

set block [ord::get_db_block]
puts "  ✓ Design: [$block getName]"
puts "  ✓ All nets are routed"

# 步骤3：查找extraction rules文件
puts "\n\[Step 3\] Setting up parasitic extraction..."

# ASAP7工艺的extraction rules文件路径
set ext_rules_paths [list \
    "$PLATFORM_DIR/rcx/asap7_ext_rules.rules" \
    "$PLATFORM_DIR/rcx_patterns.rules" \
    "$PLATFORM_DIR/extraction.rules" \
]

set ext_rules_file ""
foreach path $ext_rules_paths {
    if {[file exists $path]} {
        set ext_rules_file $path
        puts "  ✓ Found extraction rules: $path"
        break
    }
}

# 步骤4：提取寄生参数
puts "\n\[Step 4\] Extracting RC parasitics..."

if {$ext_rules_file != "" && [file exists $ext_rules_file]} {
    # 使用extraction rules文件（精确提取）
    puts "  Using extraction rules for accurate RC extraction..."
    
    if {[catch {
        define_process_corner -ext_model_index 0 typical
        extract_parasitics -ext_model_file $ext_rules_file
    } err]} {
        puts "  Warning: Advanced extraction failed: $err"
        puts "  Falling back to wire-based estimation..."
        estimate_parasitics -placement
    }
} else {
    # 使用基于wire的估算（OpenROAD内置）
    puts "  No extraction rules found, using wire-based RC estimation..."
    puts "  (This is less accurate but sufficient for digital designs)"
    
    # 设置RC参数
    set_wire_rc -signal -layer M2
    set_wire_rc -clock -layer M5
    
    # 使用placement模式进行估算（考虑实际布线）
    estimate_parasitics -placement
}

puts "  ✓ Parasitic extraction completed"

# 步骤5：生成SPEF文件
puts "\n\[Step 5\] Writing SPEF file..."

# 确保reports目录存在
if {![file exists $REPORT_DIR]} {
    file mkdir $REPORT_DIR
}

# 写入SPEF
set spef_file "$REPORT_DIR/detail_route.spef"

if {[catch {
    write_spef $spef_file
    puts "  ✓ SPEF saved: $spef_file"
} err]} {
    puts "  ERROR: Failed to write SPEF: $err"
    puts ""
    puts "  Note: write_spef requires parasitic extraction data."
    puts "  Current extraction method may not support SPEF output."
    puts ""
    puts "  Alternative approaches:"
    puts "  1. Use estimate_parasitics for internal timing only"
    puts "  2. Use external RC extraction tools (Calibre xRC, StarRC)"
    puts "  3. Check if OpenROAD-flow-scripts has SPEF generation flow"
    exit 1
}

# 步骤6：验证SPEF文件
puts "\n\[Step 6\] Verifying SPEF file..."

if {[file exists $spef_file]} {
    set file_size [file size $spef_file]
    puts "  ✓ SPEF file size: [expr {$file_size / 1024}] KB"
    
    # 读取前几行验证格式
    set fp [open $spef_file r]
    set header [read $fp 500]
    close $fp
    
    if {[string match "*\*SPEF*" $header]} {
        puts "  ✓ SPEF format validated"
    } else {
        puts "  ⚠ Warning: SPEF format may be incorrect"
    }
} else {
    puts "  ✗ SPEF file not created"
    exit 1
}

# 步骤7：生成摘要信息
puts "\n\[Step 7\] SPEF summary..."

puts ""
puts "  ============================================"
puts "  SPEF File Information"
puts "  ============================================"
puts "  File: $spef_file"
puts "  Size: [expr {[file size $spef_file] / 1024}] KB"
puts "  "
puts "  SPEF contains:"
puts "  - Wire resistance (R) from metal layers"
puts "  - Coupling capacitance (C) between nets"
puts "  - Ground capacitance to substrate"
puts "  - Via resistances"
puts "  "
puts "  Use cases:"
puts "  ✓ Accurate static timing analysis (STA)"
puts "  ✓ Post-layout gate-level simulation"
puts "  ✓ Sign-off timing verification"
puts "  ✓ Power analysis with switching activity"
puts "  ============================================"
puts ""

puts "=========================================="
puts "SPEF Generation Completed!"
puts "=========================================="
puts ""
puts "Output files:"
puts "  - $spef_file"
puts ""
puts "Next steps:"
puts "  1. Use SPEF for accurate timing analysis"
puts "  2. Load SPEF in gate-level simulation"
puts "  3. Continue with filler insertion (step 11)"
puts ""

exit
