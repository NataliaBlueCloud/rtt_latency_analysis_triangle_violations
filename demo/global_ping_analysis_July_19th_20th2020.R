library(data.table)
library(igraph)


# Load the servers dataset
servers <- fread("Input_files/servers-2020-07-19.csv")


# Load data
df <- fread("Input_files/pings-2020-07-19-2020-07-20.csv.gz")


# Merge with server names to replace IDs with names
df <- merge(df, servers, by.x = "source", by.y = "id")
df <- merge(df, servers, by.x = "destination", by.y = "id", suffixes = c("_src", "_dst"))

# Create a unique list of node names
city_ids <- servers$id
city_names <- servers$name

# Initialize adjacency matrix with Inf (no direct connection)
adj_matrix <- matrix(Inf, nrow = length(city_names), ncol = length(city_names))
rownames(adj_matrix) <- city_names
colnames(adj_matrix) <- city_names

# # Fill adjacency matrix with average latencies
src_num = 0
for(src in servers$id){
  dst_num = 0
  src_num = src_num + 1
  for(dst in servers$id){
    
    dst_num = dst_num + 1
    latency = mean(df$avg[df$source == src & df$destination == dst])
    print(dst_num)
    
    adj_matrix[src_num, dst_num] <- latency
  }
}
  

count <<- 0 
# Convert NaN or missing values to Inf and process values
adj_matrix_withoutNaN <- apply(adj_matrix, c(1,2), function(x) {
  
  if (is.nan(x) || is.na(x)) {  # Use is.nan() and is.na() to handle NaN and NA properly
    count <<- count + 1
    return(Inf)
  } else {
    return(x)
  }
})


# Create a graph from the adjacency matrix
graph <- graph_from_adjacency_matrix(adj_matrix_withoutNaN, mode = "directed", weighted = TRUE)

# Function to find the shortest path and check for better 2-hop alternatives
alternative_paths <- data.frame(From=character(), To=character(), Direct=numeric(), Alternative=numeric(), Improvement=numeric(), Alternative_path = character(), stringsAsFactors=FALSE)

for (i in seq_along(city_names)) {
  for (j in seq_along(city_names)) {
    if (i != j) {
      direct_path <- adj_matrix_withoutNaN[i, j]
      
      # Find shortest path using Dijkstra’s algorithm
      sp <- shortest_paths(graph, from = city_names[i], to = city_names[j], weights = E(graph)$weight)
      
      if (length(sp$vpath[[1]]) > 0) {
        shortest_path_weight <- sum(E(graph, path=sp$vpath[[1]])$weight)
        
        if (shortest_path_weight < direct_path) {
          alternative_paths <- rbind(alternative_paths, 
                                     data.frame(From=city_names[i], 
                                                To=city_names[j], 
                                                Direct=direct_path, 
                                                Alternative=shortest_path_weight, 
                                                Improvement=direct_path - shortest_path_weight,
                                                Alternative_path = paste(as.character(sp$vpath[[1]])) ))
          cat("Alternative path found:", city_names[i], "->", city_names[j], "via", sp$vpath[[1]], "with latency", shortest_path_weight, "ms (Direct:", direct_path, "ms)\n")
          
          
        }
      }
    }
  }
}

# Display alternative paths
print(alternative_paths)


# Remove rows where direct path is Inf
alternative_paths <- alternative_paths[is.finite(alternative_paths$Direct), ]



# Calculate % of optimized paths
percent_optimized <- (nrow(alternative_paths) / (length(city_names) * (length(city_names) - 1))) * 100

# Calculate average improvement in ms
#avg_improvement <- mean(alternative_paths$Improvement, na.rm=TRUE)
avg_improvement <- mean(alternative_paths$Improvement)


# Bar plot for % non-optimized paths
percent_df <- data.frame(Category=c("Needs Improvement", "Already Optimal"), 
                         Percentage=c(100-percent_non_optimized, percent_non_optimized))
ggplot(percent_df, aes(x=Category, y=Percentage, fill=Category)) +
  geom_bar(stat="identity") +
  labs(title="Percentage of Paths That Need Optimization", x="", y="Percentage (%)") +
  theme_minimal()

# Print stats
cat("Percentage of optimized paths:", percent_optimized, "%\n")
cat("Average improvement in RTT:", avg_improvement, "ms\n")

# Visualization
# Histogram of RTT improvement
ggplot(alternative_paths, aes(x=Improvement)) +
  geom_histogram(binwidth=5, fill="blue", alpha=0.7) +
  labs(title="Distribution of RTT Improvements", x="RTT Improvement (ms)", y="Frequency") +
  theme_minimal()



# Create a new dataframe for boxplot comparison
boxplot_data <- data.frame(
  Category = c(rep("Non-Optimized", nrow(alternative_paths)), 
               rep("Optimized", nrow(alternative_paths))),
  Latency = c(alternative_paths$Direct, alternative_paths$Alternative)
)

# Create the boxplot
ggplot(boxplot_data, aes(x=Category, y=Latency, fill=Category)) +
  geom_boxplot(alpha=0.7) +
  labs(title="Comparison of Latency: Non-Optimized vs Optimized Paths",
       x="", y="RTT Latency (ms)") +
  theme_minimal() +
  scale_fill_manual(values=c("red", "blue"))


