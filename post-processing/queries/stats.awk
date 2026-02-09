# Compute min, max, median, mean, std from sorted numbers (one per line).
# Input must be sorted -n. Outputs nothing and exits 1 if no lines.
{ a[NR] = $1; sum += $1 }
END {
  n = NR
  if (n == 0) exit 1
  mean = sum / n
  for (i = 1; i <= n; i++) s += (a[i] - mean) ^ 2
  std = sqrt(s / n)
  min = a[1]
  max = a[n]
  median = (n % 2) ? a[(n + 1) / 2] : (a[n/2] + a[n/2 + 1]) / 2
  printf "min: %s  max: %s  median: %s  mean: %.2f  std: %.2f\n", min, max, median, mean, std
}
