library(igraph)
library(ggplot2)
library(readxl)

# Load the adjacency matrix from an Excel file
file_path <- "Input_files/wondernetwork_pings.xlsx"
df <- read_excel(file_path)

# Convert the dataframe into a graph representation
city_names <- df[[1]]
adj_matrix <- as.matrix(df[,-1])
rownames(adj_matrix) <- city_names
colnames(adj_matrix) <- city_names

adj_matrix[nrow(adj_matrix) - 50, ncol(adj_matrix)-3]
# Convert latency values to numeric (remove 'ms' and replace dashes with Inf)
adj_matrix <- apply(adj_matrix, c(1,2), function(x) {
  x <- ifelse(x == "N/A", c(-1,"ms"), x)
  val <- as.numeric(gsub("ms", "", x))
  val <- ifelse(val == -1, Inf, val)
  ifelse(is.na(val), 0, val)
  
})

graph <- graph_from_adjacency_matrix(adj_matrix, mode="undirected", weighted=TRUE)

# Function to find the shortest path and check for better 2-hop alternatives
alternative_paths <- data.frame(From=character(), To=character(), Direct=numeric(), Alternative=numeric(), Improvement=numeric(), stringsAsFactors=FALSE)

for (i in seq_along(city_names)) {
  for (j in seq_along(city_names)) {
    if (i != j) {
      direct_path <- adj_matrix[i, j]
      
      # Find shortest path using Dijkstra’s algorithm
      sp <- shortest_paths(graph, from = city_names[i], to = city_names[j], weights = E(graph)$weight)
      shortest_path_weight <- sum(E(graph, path=sp$vpath[[1]])$weight)
      
      if (shortest_path_weight < direct_path) {
        alternative_paths <- rbind(alternative_paths, 
                                   data.frame(From=city_names[i], To=city_names[j], Direct=direct_path, Alternative=shortest_path_weight, 
                                              Improvement=direct_path - shortest_path_weight))
      }
    }
  }
}

# Calculate % of non-optimized paths
percent_non_optimized <- (nrow(alternative_paths) / (length(city_names) * (length(city_names) - 1))) * 100

# Calculate average improvement in ms
#avg_improvement <- mean(alternative_paths$Improvement, na.rm=TRUE)
avg_improvement <- mean(alternative_paths$Improvement)

# Print stats
cat("Percentage of non-optimized paths:", percent_non_optimized, "%\n")
cat("Average improvement in RTT:", avg_improvement, "ms\n")

# Visualization
# Histogram of RTT improvement
ggplot(alternative_paths, aes(x=Improvement)) +
  geom_histogram(binwidth=5, fill="blue", alpha=0.7) +
  labs(title="Distribution of RTT Improvements", x="RTT Improvement (ms)", y="Frequency") +
  theme_minimal()

# Bar plot for % non-optimized paths
percent_df <- data.frame(Category=c("Optimized", "Non-Optimized"), Percentage=c(100-percent_non_optimized, percent_non_optimized))
ggplot(percent_df, aes(x=Category, y=Percentage, fill=Category)) +
  geom_bar(stat="identity") +
  labs(title="Percentage of Non-Optimized Paths", x="", y="Percentage (%)") +
  theme_minimal()

# Boxplot of RTT improvements
ggplot(alternative_paths, aes(y=Improvement)) +
  geom_boxplot(fill="blue", alpha=0.7) +
  labs(title="RTT Improvement Statistics", y="RTT Improvement (ms)") +
  theme_minimal()
