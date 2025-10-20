# Global Triangle Inequality Violation (TIV) Analysis Using WonderNetwork RTT Data

## Objective and Scope of the Repository

This repository provides code and sample data for analyzing global Internet latency, with a particular focus on **Round-Trip Time (RTT)** measurements and 
the phenomenon of **Triangle Inequality Violations (TIVs)** in network routing. 
Its main purpose is to enable researchers and engineers to replicate and extend the analysis presented in our study of worldwide ping times. 
The codebase is designed to systematically process ping measurements between hundreds of globally distributed servers and to identify cases where indirect routes outperform direct routes (i.e., TIVs).
By releasing this toolkit, we aim to facilitate deeper exploration of Internet latency patterns and routing inefficiencies. 

The code consists of the following parts:
- Constructing RTT matrices and directed graphs.
- Finding shortest detour paths.
- Detecting TIVs.
- Quantifying TIV gain and TIV ratios regionally.
- Visualizing hotspots of inefficiency and intermediate hubs.

## Dataset Contents and Format

The dataset from **WonderNetwork’s Global Ping Statistics service** (https://wondernetwork.com/pings/) provided us with a comprehensive baseline of global ping measurements, which underpins all analyses in this repository.

- **Input file**: Input_files/2025-01-01.csv.gz Ping RTT measurements between server pairs on January 1, 2025.
- **Servers metadata**: Input_files/servers-2020-07-19.csv Metadata including server ID, city, country, and geographic coordinates.

RTT data contains hourly pings (24 samples) between servers across 246 locations in 95 countries. 

| Region            | Description                           | Server Count |
| ----------------- | ------------------------------------- | ------------ |
| **NorthAm**       | United States, Canada, Mexico, etc.   | 80           |
| **WestEurope**    | UK, France, Germany, Italy, etc.      | 56           |
| **EastEurope**    | Poland, Czech Republic, Ukraine, etc. | 30           |
| **LatAm**         | Brazil, Argentina, Chile, etc.        | 12           |
| **Africa**        | South Africa, Egypt, Nigeria, etc.    | 11           |
| **MidEast**       | UAE, Israel, Saudi Arabia, etc.       | 4            |
| **Hindustan**     | India, Pakistan, Bangladesh           | 3            |
| **PacificC**      | Japan, Singapore, South Korea, etc.   | 32           |
| **Au&NewZ**       | Australia, New Zealand                | 9            |


## 🧮 Triangle Inequality Violation (TIV)

A TIV occurs when a two-hop or multi-hop path yields lower RTT than the direct link. This reflects suboptimal or policy-constrained Internet routing.

### 📐 TIV Gain Formula

Let:

- $`d(i,j)`$: Direct RTT between nodes $` i `$ and $` j `$
- $` d_{\text{detour}}(i,j) `$: RTT of the best alternative (indirect) path

Then the percentage latency gain is:
```math
G(i,j) = \frac{d(i,j) - d_{\text{detour}}(i,j)}{d_{\text{detour}}(i,j)} \times 100\%
```

This metric is computed for all valid detours.

#### Regional Average TIV Gain

The average latency gain between source region $` R_s `$ and destination region $` R_d `$ is:

```math
\text{AvgGain}(R_s, R_d) = \frac{1}{N} \sum_{i \in R_s, j \in R_d} G(i,j)
```

Where $` N `$ is the number of valid TIVs between the regions.

### 📊 TIV Ratio Between Regions


The **TIV ratio** between source region $` R_s `$ and destination region $` R_d `$ is defined as:
```math
\rho(R_s, R_d) = \frac{N_{\text{TIV}}(R_s, R_d)}{N_{\text{total}}(R_s, R_d)} \times 100\%
```

where:

-$` N_{\text{TIV}}(R_s, R_d)`$ is the number of links exhibiting a TIV between regions $` R_s `$ and $` R_d `$,
-$` N_{\text{total}}(R_s, R_d) `$ is the total number of measured links between the two regions.



---

## Code Workflow Summary

🔹 Step 1: Clone & Install
```r
system('git clone https://github.com/NataliaBlueCloud/wondernetwork_pings.git')
install.packages(c("igraph", "R.utils", "sf", "rnaturalearth", "rnaturalearthdata", "dplyr", "ggrepel", "tidyr"))
```
 🔹 Step 2: Load Data
- `servers-2020-07-19.csv`: server locations and metadata
- `2025-01-01.csv.gz`: RTT values
- Server IDs are mapped to names and coordinates

 🔹 Step 3: Outlier Removal
- Uses IQR to remove extreme RTT outliers per server pair

 🔹 Step 4: RTT Mapping
- Maps average RTT per country to a world map using `ggplot2`
- Server dots labeled by region (e.g. `n_3`, `we_2`)

 🔹 Step 5: Graph & TIV Detection
- Constructs directed weighted graph from RTT data
- Applies Dijkstra's algorithm to find shortest detour
- If detour < direct → TIV detected

 🔹 Step 6: TIV Gain Analysis
- Computes percentage gain using the formula above
- Aggregates average gain per city and region

 🔹 Step 7: Hub Analysis
- Counts cities most frequently used in alternative paths
- Top 20 hubs plotted and exported to CSV

 🔹 Step 8: Intermediate Path Length
- Measures number of intermediate hops in TIVs
- Mean ≈ 1.5 nodes

 🔹 Step 9: Regional Matrix & Heatmaps
- Computes average TIV gain and TIV ratio across regions
- Visualized using heatmaps
- Saved as `Regional_TIV_Matrix_2025.csv`


---

## 📁 Output Files

- `Regional_TIV_Matrix_2025.csv`: Regional average gain and TIV ratio
- `top_20_hubs.csv`: Cities most used in detour paths
- Interactive maps (via `ggplot2`) included in code blocks

---
# Citation

If you use this repository or the processed dataset, please cite:

> WonderNetwork’s ping statistics, at https://wondernetwork.com/pings

WonderNetwork is a commercial provider of geographic latency insight via globally distributed servers. Their ping dataset has been publicly accessible and widely used in both academic and operational network studies. We thank WonderNetwork for providing this valuable resource.
