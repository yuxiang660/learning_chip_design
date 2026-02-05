# ========================================================================
# GCD项目工具函数 - 通用辅助函数
# ========================================================================

# 加载LEF文件
proc load_lef_files {} {
    global TECH_LEF SC_LEF
    puts "Loading LEF files..."
    read_lef $TECH_LEF
    read_lef $SC_LEF
    puts "  ✓ LEF files loaded\n"
}

# 加载Liberty库文件
proc load_liberty_files {} {
    global SEQ_LIB INVBUF_LIB SIMPLE_LIB
    puts "Loading Liberty library files..."
    read_liberty $SEQ_LIB
    read_liberty $INVBUF_LIB
    read_liberty $SIMPLE_LIB
    puts "  ✓ Liberty files loaded\n"
}

# 加载设计（从ODB文件）
proc load_design_odb {odb_file} {
    global RESULT_DIR SDC_FILE
    puts "Loading design from ODB..."
    
    # 加载LEF和Liberty
    load_lef_files
    load_liberty_files
    
    # 读取ODB数据库
    read_db $RESULT_DIR/$odb_file
    
    # 读取约束
    if {[file exists $SDC_FILE]} {
        read_sdc $SDC_FILE
        puts "  ✓ SDC constraints loaded"
    }
    
    # 设置RC参数（从官方平台配置）
    source_rc_settings
    
    puts "  ✓ Design loaded from $odb_file\n"
}

# 设置RC参数（参考官方setRC.tcl）
proc source_rc_settings {} {
    global PLATFORM_DIR
    
    # ASAP7的RC设置 - 仅设置基本layer
    set_wire_rc -clock -layer M5
    set_wire_rc -signal -layer M2
    
    puts "  ✓ RC parameters set (M2 for signal, M5 for clock)"
}

# 保存结果
proc save_results {stage_name} {
    global RESULT_DIR REPORT_DIR
    
    puts "\nSaving results..."
    
    # 保存ODB（关键！保留完整信息）
    set odb_file "$RESULT_DIR/${stage_name}.odb"
    write_db $odb_file
    puts "  ✓ ODB saved: $odb_file"
    
    # 保存DEF（仅供参考）
    set def_file "$RESULT_DIR/${stage_name}.def"
    write_def $def_file
    puts "  ✓ DEF saved: $def_file (reference only)"
    
    # 生成面积报告
    set area_rpt "$REPORT_DIR/${stage_name}_area.rpt"
    report_design_area > $area_rpt
    puts "  ✓ Area report: $area_rpt"
}

# 检查pin shapes
proc check_pin_shapes {} {
    set has_shapes 1
    set missing_pins {}
    
    foreach bterm [[ord::get_db_block] getBTerms] {
        set name [$bterm getName]
        set bpins [$bterm getBPins]
        if {[llength $bpins] == 0} {
            lappend missing_pins $name
            set has_shapes 0
        }
    }
    
    if {!$has_shapes} {
        puts "WARNING: Following pins are missing shapes:"
        foreach pin $missing_pins {
            puts "  - $pin"
        }
        return 0
    } else {
        puts "✓ All pins have shapes"
        return 1
    }
}

# 打印设计统计
proc print_design_stats {} {
    set block [ord::get_db_block]
    set die_area [$block getDieArea]
    set num_insts [llength [$block getInsts]]
    set num_nets [llength [$block getNets]]
    set num_pins [llength [$block getBTerms]]
    
    puts "\n=========================================="
    puts "Design Statistics"
    puts "=========================================="
    puts "Die Area:    $die_area"
    puts "Instances:   $num_insts"
    puts "Nets:        $num_nets"
    puts "I/O Pins:    $num_pins"
    puts "==========================================\n"
}

puts "✓ Utility functions loaded"
