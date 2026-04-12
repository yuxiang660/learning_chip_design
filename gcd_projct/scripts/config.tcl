# ========================================================================
# GCD项目配置文件
# 定义所有路径和全局参数
# ========================================================================

# 设计名称
set DESIGN_NAME "gcd"

# 平台路径（ASAP7 7nm工艺）
set PLATFORM_DIR "/home/yuxiangw/github/OpenROAD-flow-scripts/flow/platforms/asap7"

# 项目目录
set PROJ_DIR "/mnt/c/Users/yuxiangw/GitHub/learning_chip_design/gcd_projct"
set RESULT_DIR "./results"
set REPORT_DIR "./reports"
set RTL_DIR "./rtl"
set LOG_DIR "./logs"

# ========================================================================
# LEF 文件（Library Exchange Format - 物理信息）
# ========================================================================
# 技术LEF：工艺层定义、通孔规则、布线规则
set TECH_LEF "$PLATFORM_DIR/lef/asap7_tech_1x_201209.lef"

# 标准单元LEF：单元的物理视图（尺寸、引脚位置、blockage）
set SC_LEF "$PLATFORM_DIR/lef/asap7sc7p5t_28_R_1x_220121a.lef"

# ========================================================================
# Liberty 文件（时序和功耗信息）
# ========================================================================
# 使用TT corner（Typical-Typical，典型工艺角）
set SEQ_LIB "$PLATFORM_DIR/lib/NLDM/asap7sc7p5t_SEQ_RVT_TT_nldm_220123.lib"
set INVBUF_LIB "$PLATFORM_DIR/lib/NLDM/asap7sc7p5t_INVBUF_RVT_TT_nldm_220122.lib.gz"
set SIMPLE_LIB "$PLATFORM_DIR/lib/NLDM/asap7sc7p5t_SIMPLE_RVT_TT_nldm_211120.lib.gz"

# ========================================================================
# SDC 约束文件
# ========================================================================
set SDC_FILE "/home/yuxiangw/github/OpenROAD-flow-scripts/flow/designs/asap7/gcd/constraint.sdc"

# ========================================================================
# RTL 文件
# ========================================================================
set RTL_FILE "$RTL_DIR/gcd.v"

# ========================================================================
# 布图规划参数
# ========================================================================
# Die尺寸（微米）
set DIE_WIDTH 16.2
set DIE_HEIGHT 16.2

# Core区域占比
set CORE_MARGIN 1.08  ;# Core边界距离die边界的距离（um）

# 目标利用率
set CORE_UTILIZATION 25  ;# 25%利用率

# Core面积将自动计算以适应目标利用率

# ========================================================================
# 布局参数
# ========================================================================
# Placement padding（单元间距，单位：sites）
set PLACE_DENSITY 0.60  ;# 更低的密度，为布线留出更多空间

# ========================================================================
# 时钟树综合参数
# ========================================================================
# 时钟缓冲器
set CTS_BUFFER "BUFx4_ASAP7_75t_R"
set CTS_MAX_SLEW 100     ;# ps
set CTS_MAX_CAP 0.2      ;# pF

# ========================================================================
# 布线参数
# ========================================================================
# 布线层设置
set MIN_ROUTING_LAYER "M1"
set MAX_ROUTING_LAYER "Pad"

# 全局布线层容量调整
set GR_ADJUSTMENT 0.0

# 信号线和时钟线使用的金属层
set SIGNAL_LAYER "M2"
set CLOCK_LAYER "M5"

# ========================================================================
# PDN（电源分配网络）参数
# ========================================================================
set PDN_STDCELL_RAILS 1  ;# 标准单元行上有电源轨
set PDN_VERTICAL_LAYER "M1"
set PDN_HORIZONTAL_LAYER "M2"

# ========================================================================
# Filler 单元
# ========================================================================
set FILLER_CELLS [list \
    "FILLERxp5_ASAP7_75t_R" \
    "FILLER_ASAP7_75t_R" \
]

# ========================================================================
# Tapcell 参数
# ========================================================================
set TAPCELL_NAME "TAPCELL_ASAP7_75t_R"
set TAPCELL_DISTANCE 14  ;# 单位：sites（约25-30个site的间距）

# ========================================================================
# 输出格式
# ========================================================================
set OUTPUT_FORMATS [list "def" "odb" "v" "gds"]

puts "Configuration loaded:"
puts "  Design:    $DESIGN_NAME"
puts "  Platform:  ASAP7 7nm"
puts "  Die size:  ${DIE_WIDTH}um x ${DIE_HEIGHT}um"
puts "  Target utilization: ${CORE_UTILIZATION}%"
puts ""
