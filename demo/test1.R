library(igraph)

# Load the adjacency matrix from an Excel file
library(readxl)
file_path <- "Input_files/wondernetwork_pings.xlsx"
df <- read_excel(file_path, sheet = 2)

# Convert the dataframe into a graph representation
city_names <- df[[1]]
adj_matrix <- as.matrix(df[,-1])
rownames(adj_matrix) <- city_names
colnames(adj_matrix) <- city_names

# Convert latency values to numeric (remove 'ms' and replace dashes with Inf)
adj_matrix <- apply(adj_matrix, c(1,2), function(x) {
  val <- as.numeric(gsub("ms", "", x))
  ifelse(is.na(val), 0, val)
})

graph <- graph_from_adjacency_matrix(adj_matrix, mode="undirected", weighted=TRUE)

# Function to find the shortest path and check for better 2-hop alternatives
check_alternative_paths <- function(graph, city_names) {
  alternative_paths = 0
  for (i in seq_along(city_names)) {
    for (j in seq_along(city_names)) {
      if (i != j) {
        direct_path <- adj_matrix[i, j]
        
        # Find shortest path using Dijkstra’s algorithm
        sp <- shortest_paths(graph, from = city_names[i], to = city_names[j], weights = E(graph)$weight)
        shortest_path_weight <- sum(E(graph, path=sp$vpath[[1]])$weight)
      
        if (shortest_path_weight < direct_path) {
          cat("Alternative path found:", city_names[i], "->", city_names[j], "via", sp$vpath[[1]], "with latency", shortest_path_weight, "ms (Direct:", direct_path, "ms)\n")
          alternative_paths = alternative_paths + 1
        }
      }
    }
  }
  return(alternative_paths)
}

alternative_paths <- check_alternative_paths(graph, city_names)
(alternative_paths/2)/(length(city_names)^2)