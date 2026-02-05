#!/usr/bin/env openroad
# Filler Cell Insertion Script
# Purpose: Fill gaps between standard cells for DRC compliance and N-well continuity

puts "=========================================="
puts "Filler Cell Insertion"
puts "=========================================="
puts ""

# Source configuration
source scripts/config.tcl
source scripts/utils.tcl

# Step 1: Load detailed routing design
puts "\[Step 1\] Loading routed design..."
load_lef_files
load_liberty_files
read_db results/detail_route.odb
puts "  ✓ Design loaded"
puts ""

# Step 2: Check current design status
puts "\[Step 2\] Current design status..."
set instances [get_cells -hierarchical *]
set num_instances [llength $instances]
puts "  Current instances: $num_instances"
puts ""

# Step 3: Get filler cells from LEF
puts "\[Step 3\] Finding filler cells..."

# ASAP7 standard cell library filler cells:
# FILLER_ASAP7_75t_R  - 1x width
# FILLERxp5_ASAP7_75t_R - 0.5x width (half-width for fine gaps)

set filler_cells [list \
    FILLERxp5_ASAP7_75t_R \
    FILLER_ASAP7_75t_R
]

puts "  Filler cells to use:"
foreach cell $filler_cells {
    puts "    - $cell"
}
puts ""

# Step 4: Insert filler cells
puts "\[Step 4\] Inserting filler cells..."
puts "  This will:"
puts "    - Fill all gaps in standard cell rows"
puts "    - Ensure N-well/P-well continuity"
puts "    - Improve power grid connectivity"
puts "    - Meet density requirements"
puts ""

# Insert fillers
# The filler_placement command automatically:
# - Scans all standard cell rows
# - Finds gaps between placed cells
# - Inserts largest possible filler first (greedy algorithm)
# - Then uses smaller fillers for remaining gaps
# - Connects filler cells to power rails

filler_placement $filler_cells

puts "  ✓ Filler cells inserted"
puts ""

# Step 5: Check results
puts "\[Step 5\] Checking results..."
set instances_after [get_cells -hierarchical *]
set num_instances_after [llength $instances_after]
set num_fillers [expr {$num_instances_after - $num_instances}]

puts "  Instances before: $num_instances"
puts "  Instances after:  $num_instances_after"
puts "  Fillers added:    $num_fillers"
puts ""

# Step 6: Verify placement
puts "\[Step 6\] Verifying placement..."
check_placement -verbose
puts "  ✓ Placement check passed"
puts ""

# Step 7: Design statistics
puts "\[Step 7\] Final design statistics..."
report_design_area
puts ""

# Step 8: Save results
puts "\[Step 8\] Saving results..."

# Save ODB (preserves all routing and placement)
write_db results/filler.odb
puts "  ✓ Saved: filler.odb"

# Save DEF
write_def results/filler.def
puts "  ✓ Saved: filler.def"

# Save reports
set report_file [open reports/filler.rpt w]
puts $report_file "Filler Cell Insertion Report"
puts $report_file "============================"
puts $report_file ""
puts $report_file "Original instances: $num_instances"
puts $report_file "Filler instances:   $num_fillers"
puts $report_file "Total instances:    $num_instances_after"
puts $report_file ""
puts $report_file "Filler cells used:"
foreach cell $filler_cells {
    # Count instances of each filler type
    set count 0
    foreach inst [get_cells -hierarchical *] {
        set inst_master [get_property $inst cell]
        if {[string match *$cell* $inst_master]} {
            incr count
        }
    }
    if {$count > 0} {
        puts $report_file "  $cell: $count instances"
    }
}
close $report_file
puts "  ✓ Report: filler.rpt"
puts ""

puts "=========================================="
puts "Filler Cell Insertion Completed!"
puts "=========================================="
puts ""
puts "Summary:"
puts "  - Added $num_fillers filler cells"
puts "  - All gaps in standard cell rows filled"
puts "  - Design ready for final verification"
puts ""
puts "Next steps:"
puts "  1. Final DRC check (optional)"
puts "  2. Final timing analysis"
puts "  3. GDSII generation"
puts ""

exit
