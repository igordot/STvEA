Using STvEA to analyze CODEX data
================

``` r
library(STvEA)
set.seed(4068)
```

Read in CODEX data
------------------

Goltsev et al. used CODEX to image the protein expression of tissue sections from 3 normal BALBc mice ( <https://www.cell.com/cell/fulltext/S0092-8674(18)30904-8> ). We downloaded their segmented and spillover corrected data as FCS files from <http://welikesharingdata.blob.core.windows.net/forshare/index.html>. Here we load the expression of the protein and blank channels, cell size, and spatial coordinates from that file.

``` r
data("codex_balbc1")
```

### Convert CODEX spatial coordinates from voxels to nm

We want the z dimension to be in the same units as the x and y dimensions for nearest neighbor computations, so we convert the stacks and voxels to nm.

``` r
codex_spatial$x <- codex_spatial$x - (min(codex_spatial$x) - 1)
codex_spatial$y <- codex_spatial$y - (min(codex_spatial$y) - 1)

codex_spatial_nm <- as.data.frame(cbind(x=codex_spatial$x*188, y=codex_spatial$y*188, z=codex_spatial$z*900))
```

### Take corner section of CODEX data

Some functions in the following analysis are fairly slow on large numbers of cells, so for this tutorial we take a subset of the CODEX cells. It is important to subset the cells in a section of the slide rather than randomly sampling, so that analyses on neighboring cells are accurate.

``` r
codex_subset <- codex_spatial$x < 3000 & codex_spatial$y < 3000
codex_protein <- codex_protein[codex_subset,]
codex_blanks <- codex_blanks[codex_subset,]
codex_size <- codex_size[codex_subset]
codex_spatial_nm <- codex_spatial_nm[codex_subset,]
```

Create object to hold data
--------------------------

We use the STvEA.data class to conveniently handle the required data frames and matrices between function calls. We create an object by first adding the data from CODEX: the expression levels from the protein channels after segmentation and spillover correction, the expression levels from the blank channels, the size of each cell according to the segmentation algorithm, and the xyz coordinates of each cell.

``` r
stvea_object <- SetDataCODEX(codex_protein = codex_protein,
                             codex_blanks = codex_blanks,
                             codex_size = codex_size,
                             codex_spatial = codex_spatial_nm)
```

Filter and clean protein expression
-----------------------------------

We follow the gating strategy in Goltsev et al. to remove cells that are too small or large, or have too low or too high expression in the blank channels. If the limits aren't specified, the 0.025 and 0.99 quantiles are taken as the lower and upper bounds on size, and the 0.002 and 0.99 quantiles are used for the blank channel expression. We then normalize the protein expression values by the total expression per cell.

``` r
stvea_object <- FilterCODEX(stvea_object, size_lim = c(1000,25000),
                            blank_lower = c(-1200, -1200, -1200, -1200),
                            blank_upper = c(6000,2500,5000,2500))
```

We remove noise from the CODEX protein expression by first fitting a Gaussian mixture model to the expression levels of each protein. The signal expression is taken as the cumulative probability according to the Gaussian with the higher mean.

``` r
stvea_object <- CleanCODEX(stvea_object)
```

Cluster CODEX cells based on protein expression
-----------------------------------------------

We use UMAP to compute the 2 dimensional embedding of the cleaned CODEX protein expression for later visualization. The call to UMAP also returns the KNN indices with k = n\_neighbors.

``` r
# This will take around 5 minutes for ~10000 cells
stvea_object <- GetUmapCODEX(stvea_object, metric = 'pearson', n_neighbors=30,
                             min_dist=0.1, negative_sample_rate = 50)
```

We perform Louvain clustering on a KNN graph of the CODEX cells, built from the KNN indices returned by UMAP. If k is provided, it must be less than or equal to n\_neighbors from above. If it is not provided, it is set equal to n\_neighbors.

``` r
stvea_object <- ClusterCODEX(stvea_object, k=30)
```

Visualize clustering and protein expression
-------------------------------------------

Color each cell in the CODEX UMAP embedding with its cluster assignment. Cells in gray were not assigned to any cluster.

``` r
PlotClusterCODEXemb(stvea_object)
```

![](codex_tutorial_files/figure-markdown_github/unnamed-chunk-10-1.png)

Color each cell in the CODEX UMAP embedding with its expression level of proteins. One or two protein names can be input. If two protein names are provided, color will be interpolated between red and green color values.

``` r
PlotExprCODEXemb(stvea_object, "CD4")
```

![](codex_tutorial_files/figure-markdown_github/unnamed-chunk-11-1.png)

``` r
PlotExprCODEXemb(stvea_object, c("CD4","B220"))
```

![](codex_tutorial_files/figure-markdown_github/unnamed-chunk-12-1.png)

Color the CODEX spatial slide with the expression level of proteins. One or two protein names can be input. If two protein names are provided, color will be interpolated between red and green color values.

``` r
PlotExprCODEXspatial(stvea_object, "CD4")
```

![](codex_tutorial_files/figure-markdown_github/unnamed-chunk-13-1.png)

``` r
PlotExprCODEXspatial(stvea_object, c("CD4","B220"))
```

![](codex_tutorial_files/figure-markdown_github/unnamed-chunk-14-1.png)

Assess colocalization of features
---------------------------------

The Adjacency Score (<https://github.com/CamaraLab/AdjacencyScore>) can be used to evaluate how often two features (cluster assignments, proteins, genes) take high values in adjacent nodes in a KNN graph of the CODEX spatial dimensions:

### Which pairs of proteins are often highly expressed in adjacent cells?

Since we are computing the Adjacency Score of every combination of features (clusters), we can plot a heatmap of the scores, where each cell in the heatmap represents the significance of the Adjacency Score between the row feature and the column feature.

``` r
protein_adj <- AdjScoreProteins(stvea_object, k=3, num_cores=8)
```

    ## Creating permutation matrices - 11.271 seconds
    ## Computing adjacency score for each feature pair - 39.315 seconds

``` r
AdjScoreHeatmap(protein_adj)
```

![](codex_tutorial_files/figure-markdown_github/unnamed-chunk-15-1.png)

### Which pairs of CODEX clusters often appear in adjacent cells?

Since the assignment of a cell to a cluster is a binary feature which is mutually exclusive with all other cluster assignments, the null distribution used to assess significance can be parameterized as a hypergeometric distribution, providing a significant speedup.

``` r
cluster_adj <- AdjScoreClustersCODEX(stvea_object, k=3)
```

    ## Creating permutation matrices - 0.007 seconds
    ## Computing adjacency score for each feature pair - 0.34 seconds

``` r
AdjScoreHeatmap(cluster_adj)
```

![](codex_tutorial_files/figure-markdown_github/unnamed-chunk-16-1.png)
