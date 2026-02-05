#!/bin/bash
# Quick Run Script - Complete ASIC Flow for GCD
# Usage: ./run_all.sh

set -e  # Exit on any error

PROJ_DIR="/home/yuxiangw/github/learning_chip_design/gcd_projct"

echo "========================================="
echo "Running Complete GCD ASIC Flow"
echo "========================================="
echo ""

cd "$PROJ_DIR"

# Step 1: Synthesis
echo "[1/12] Synthesis..."
yosys scripts/01_synth.tcl -l logs/01_synth.log
echo "  ✓ Synthesis completed"

# Step 2: Floorplan
echo "[2/12] Floorplan..."
openroad scripts/02_floorplan.tcl -log logs/02_floorplan.log
echo "  ✓ Floorplan completed"

# Step 3: Tapcell insertion
echo "[3/12] Tapcell insertion..."
openroad scripts/03_tapcell.tcl -log logs/03_tapcell.log
echo "  ✓ Tapcell insertion completed"

# Step 4: Power distribution network
echo "[4/12] Power distribution network..."
openroad scripts/04_pdn.tcl -log logs/04_pdn.log
echo "  ✓ PDN completed"

# Step 5: Global placement
echo "[5/12] Global placement..."
openroad scripts/05_global_place_skip_io.tcl -log logs/05_global_place.log
echo "  ✓ Global placement completed"

# Step 6: IO placement (fixed version)
echo "[6/12] IO placement..."
openroad scripts/06_io_place_fixed.tcl -log logs/06_io_place.log
echo "  ✓ IO placement completed"

# Step 7: Detailed placement (fixed version)
echo "[7/12] Detailed placement..."
openroad scripts/07_detail_place_fixed.tcl -log logs/07_detail_place.log
echo "  ✓ Detailed placement completed"

# Step 8: Clock tree synthesis
echo "[8/12] Clock tree synthesis..."
openroad scripts/08_cts.tcl -log logs/08_cts.log
echo "  ✓ CTS completed"

# Step 9: Global routing
echo "[9/12] Global routing..."
openroad scripts/09_global_route.tcl -log logs/09_global_route.log
echo "  ✓ Global routing completed"

# Step 10: Detailed routing
echo "[10/12] Detailed routing..."
openroad scripts/10_detail_route.tcl -log logs/10_detail_route.log
echo "  ✓ Detailed routing completed"

# Step 11: Filler cell insertion
echo "[11/12] Filler cell insertion..."
openroad scripts/11_filler.tcl -log logs/11_filler.log
echo "  ✓ Filler insertion completed"

# Step 12: Final output generation
echo "[12/12] Final output generation..."
openroad scripts/12_gdsii.tcl -log logs/12_gdsii.log
echo "  ✓ Final output completed"

echo ""
echo "========================================="
echo "✅ Complete Flow Finished Successfully!"
echo "========================================="
echo ""
echo "Output files:"
echo "  - results/gcd_final.def    (DEF format)"
echo "  - results/gcd_final.odb    (OpenROAD database)"
echo "  - results/gcd_final.v      (Post-route netlist)"
echo ""
echo "Reports:"
echo "  - reports/final_timing_*.rpt"
echo "  - reports/final_area.rpt"
echo ""
echo "Logs:"
echo "  - logs/*.log"
echo ""
echo "To view layout:"
echo "  openroad -gui results/gcd_final.odb"
echo ""
