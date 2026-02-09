#!/bin/bash
# Quick Run Script - Complete ASIC Flow for GCD
# Usage: ./run_all.sh

set -e  # Exit on any error

PROJ_DIR="/mnt/c/Users/yuxiangw/GitHub/learning_chip_design/gcd_projct"

echo "========================================="
echo "Running Complete GCD ASIC Flow"
echo "========================================="
echo ""

cd "$PROJ_DIR"
mkdir -p logs results reports

# Step 0: Load environment configuration
source ../setup.sh

# Step 1: Synthesis
echo "[1/14] Synthesis..."
yosys scripts/01_synth.tcl -l logs/01_synth.log || { echo "❌ Step 1 failed! Check logs/01_synth.log"; exit 1; }
echo "  ✓ Synthesis completed"

# Step 2: Floorplan
echo "[2/14] Floorplan..."
openroad scripts/02_floorplan.tcl -log logs/02_floorplan.log || { echo "❌ Step 2 failed! Check logs/02_floorplan.log"; exit 1; }
echo "  ✓ Floorplan completed"

# Step 3: Tapcell insertion
echo "[3/14] Tapcell insertion..."
openroad scripts/03_tapcell.tcl -log logs/03_tapcell.log || { echo "❌ Step 3 failed! Check logs/03_tapcell.log"; exit 1; }
echo "  ✓ Tapcell insertion completed"

# Step 4: Power distribution network
echo "[4/14] Power distribution network..."
openroad scripts/04_pdn.tcl -log logs/04_pdn.log || { echo "❌ Step 4 failed! Check logs/04_pdn.log"; exit 1; }
echo "  ✓ PDN completed"

# Step 5: Global placement
echo "[5/14] Global placement..."
openroad scripts/05_global_place_skip_io.tcl -log logs/05_global_place.log || { echo "❌ Step 5 failed! Check logs/05_global_place.log"; exit 1; }
echo "  ✓ Global placement completed"

# Step 6: IO placement (fixed version)
echo "[6/14] IO placement..."
openroad scripts/06_io_place_fixed.tcl -log logs/06_io_place.log || { echo "❌ Step 6 failed! Check logs/06_io_place.log"; exit 1; }
echo "  ✓ IO placement completed"

# Step 7: Detailed placement (fixed version)
echo "[7/14] Detailed placement..."
openroad scripts/07_detail_place_fixed.tcl -log logs/07_detail_place.log || { echo "❌ Step 7 failed! Check logs/07_detail_place.log"; exit 1; }
echo "  ✓ Detailed placement completed"

# Step 8: Clock tree synthesis
echo "[8/14] Clock tree synthesis..."
openroad scripts/08_cts.tcl -log logs/08_cts.log || { echo "❌ Step 8 failed! Check logs/08_cts.log"; exit 1; }
echo "  ✓ CTS completed"

# Step 9: Global routing
echo "[9/14] Global routing..."
openroad scripts/09_global_route.tcl -log logs/09_global_route.log || { echo "❌ Step 9 failed! Check logs/09_global_route.log"; exit 1; }
echo "  ✓ Global routing completed"

# Step 10: Detailed routing
echo "[10/14] Detailed routing..."
openroad scripts/10_detail_route.tcl -log logs/10_detail_route.log || { echo "❌ Step 10 failed! Check logs/10_detail_route.log"; exit 1; }
echo "  ✓ Detailed routing completed"

# Step 11: SPEF generation (optional but recommended)
echo "[11/14] SPEF generation (parasitic extraction)..."
openroad scripts/11_spef.tcl -log logs/11_spef.log || { echo "❌ Step 11 failed! Check logs/11_spef.log (continuing...)"; }
echo "  ✓ SPEF generation completed"

# Step 12: Filler cell insertion
echo "[12/14] Filler cell insertion..."
openroad scripts/12_filler.tcl -log logs/12_filler.log || { echo "❌ Step 12 failed! Check logs/12_filler.log"; exit 1; }
echo "  ✓ Filler insertion completed"

# Step 13: Final output generation
echo "[13/14] Final output generation..."
openroad scripts/13_gdsii.tcl -log logs/13_gdsii.log || { echo "❌ Step 13 failed! Check logs/13_gdsii.log"; exit 1; }
echo "  ✓ Final output completed"

# Step 14: Final SPEF generation (optional)
echo "[14/14] Final SPEF generation (post-filler)..."
openroad scripts/14_spef_final.tcl -log logs/14_spef_final.log || { echo "❌ Step 14 failed! Check logs/14_spef_final.log (continuing...)"; }
echo "  ✓ Final SPEF generation completed"

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
