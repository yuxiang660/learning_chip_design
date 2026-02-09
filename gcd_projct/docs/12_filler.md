# 步骤12: Filler插入 (Filler Cell Insertion)

本文档详细说明Filler单元插入步骤。完整内容请参考 [13_14_finishing.md](13_14_finishing.md) 的步骤11章节。

## 快速参考

```bash
openroad scripts/12_filler.tcl
```

## 主要功能

- 在标准单元行的空隙中插入filler单元
- 确保N-well/P-well连续性
- 保持电源rail连续性
- 满足金属密度DRC规则

## 输入输出

**输入**: `results/detail_route.odb`  
**输出**: `results/filler.odb`

**统计**:
```
原始instances: 516
Filler instances: ~5000
总计: ~5500
```

## 详细说明

完整的Filler概念、类型、插入策略等，请参考:
- [13_14_finishing.md](13_14_finishing.md) - Filler Cell章节

## 下一步

```bash
openroad scripts/13_gdsii.tcl  # 最终输出生成
```
