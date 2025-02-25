% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/clustering.R
\name{ParameterScan}
\alias{ParameterScan}
\title{Run HDBSCAN over parameter ranges
Must use Python HDBSCAN because it has 2 important parameters
(min_cluster_size and min_samples) but R HDBSCAN only has one (minPts)}
\usage{
ParameterScan(stvea_object, min_cluster_size_range, min_sample_range, ...)
}
\arguments{
\item{stvea_object}{STvEA.data class object containing CITE-seq latent space}

\item{min_cluster_size_range}{vector of min_cluster_size arguments to scan over}

\item{min_sample_range}{vector of min_sample arguments to scan over}

\item{...}{extra parameters to be passed into UMAP}
}
\description{
Run HDBSCAN over parameter ranges
Must use Python HDBSCAN because it has 2 important parameters
(min_cluster_size and min_samples) but R HDBSCAN only has one (minPts)
}
