# Compute 3D Segmentation QA Metrics (Dice, HD95, Surface Dice)

Compute 3D Segmentation QA Metrics (Dice, HD95, Surface Dice)

## Usage

``` r
compute_seg_qa(pred_mask, ref_mask, spacing_mm = c(1, 1, 1), tolerance_mm = 1)
```

## Arguments

- pred_mask:

  3D binary/logical predicted mask array.

- ref_mask:

  3D binary/logical reference mask array of identical dims.

- spacing_mm:

  Numeric vector of length 3 giving voxel spacing in mm.

- tolerance_mm:

  Surface Dice tolerance in mm (default `1.0`).

## Value

A list with `dice`, `hd95_mm`, and `surface_dice`.

## Examples

``` r
m <- array(0L, dim = c(6L, 6L, 6L))
m[2:4, 2:4, 2:4] <- 1L
compute_seg_qa(m, m)
#> $dice
#> [1] 1
#> 
#> $hd95_mm
#> [1] 0
#> 
#> $surface_dice
#> [1] 1
#> 
```
