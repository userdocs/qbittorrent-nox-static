# Scientific Performance Testing Methodology

This document describes the scientific approach used to validate performance optimizations in this qBittorrent build system.

## Table of Contents

- [Overview](#overview)
- [Scientific Method](#scientific-method)
- [Test Framework](#test-framework)
- [Statistical Analysis](#statistical-analysis)
- [Usage Guide](#usage-guide)
- [Interpreting Results](#interpreting-results)
- [Troubleshooting](#troubleshooting)

---

## Overview

### Problem Statement

How do we **scientifically validate** that our optimizations (multi-threaded network I/O, EPYC CPU tuning, etc.) actually improve performance?

### Solution

We use **A/B testing with statistical analysis** to compare:
- **Baseline Build:** Vanilla libtorrent + qBittorrent (no patches)
- **Optimized Build:** Patched libtorrent with all performance enhancements

### Key Principles

1. **Reproducibility:** Same test workload every time
2. **Control:** Isolate variables (only difference is the build)
3. **Statistical Rigor:** Multiple iterations + confidence intervals
4. **Objectivity:** Automated measurements (no human bias)

---

## Scientific Method

### 1. Hypothesis

**Null Hypothesis (H₀):** The optimizations have no effect on performance.

**Alternative Hypothesis (H₁):** The optimized build performs significantly better than baseline.

### 2. Controlled Experiment Design

```
┌─────────────────────────────────────────────────┐
│                Test Environment                 │
│  (Same hardware, OS, network, disk, etc.)       │
└─────────────────────────────────────────────────┘
                        │
        ┌───────────────┴───────────────┐
        │                               │
┌───────▼────────┐             ┌────────▼───────┐
│ Baseline Build │             │ Optimized Build │
│  (Control)     │             │ (Experimental)  │
└───────┬────────┘             └────────┬────────┘
        │                               │
        │  Run Same Workload (N times)  │
        │                               │
        ▼                               ▼
┌───────────────┐             ┌────────────────┐
│   Metrics     │             │    Metrics     │
│ - Tracker     │             │  - Tracker     │
│ - CPU         │             │  - CPU         │
│ - Memory      │             │  - Memory      │
│ - Network     │             │  - Network     │
└───────┬───────┘             └────────┬───────┘
        │                               │
        └───────────────┬───────────────┘
                        │
                        ▼
            ┌───────────────────────┐
            │ Statistical Analysis  │
            │ - Mean                │
            │ - Std Deviation       │
            │ - Confidence Interval │
            │ - Significance Test   │
            └───────────┬───────────┘
                        │
                        ▼
                 ┌──────────────┐
                 │   Conclusion │
                 └──────────────┘
```

### 3. Independent Variables

- **Build Configuration:** Baseline vs Optimized (THIS is what we're testing)

### 4. Dependent Variables (Metrics)

- **Tracker Announce Time:** How long for all torrents to announce to trackers
- **CPU Usage:** Average CPU utilization under load
- **Network Throughput:** Connections per second
- **Memory Consumption:** RAM usage over time

### 5. Controlled Variables

- Same hardware (CPU, RAM, disk, network)
- Same OS and kernel version
- Same test workload (number of torrents, file sizes)
- Same environmental conditions (no other processes running)

### 6. Sample Size

- **N = 5 iterations** per build configuration
- Provides statistical power while being practical

---

## Test Framework

### Architecture

**File:** `qbt-scientific-benchmark.bash`

```bash
# 1. Build Phase
├── _build_baseline()      # Builds vanilla qBittorrent (no patches)
└── _build_optimized()     # Builds with all optimizations

# 2. Test Phase
├── _generate_test_torrents()  # Creates reproducible workload
├── _run_test_suite()          # Executes tests with metrics collection
└── Repeat N times for each build

# 3. Analysis Phase
├── _calculate_mean()               # μ = Σx / n
├── _calculate_stddev()             # σ = sqrt(Σ(x-μ)² / n)
├── _calculate_confidence_interval() # CI = μ ± t*SE
├── _is_significant()               # Compare CIs for overlap
└── _analyze_results()              # Generate report
```

### Test Scenarios

Three workload sizes for different scales:

| Scenario | Torrents | Use Case |
|----------|----------|----------|
| Small    | 1,000    | Home seedbox |
| Medium   | 5,000    | Power user |
| Large    | 10,000   | Enterprise/tracker |

### Metrics Collection

#### Tracker Announce Time
```bash
# Measures time from adding torrents to all trackers responding
start_time=$(date +%s.%N)
# Add all torrents...
# Wait for tracker status = "Working"
end_time=$(date +%s.%N)
duration=$(bc <<< "$end_time - $start_time")
```

#### CPU Usage
```bash
# Sample CPU % every second for 30 seconds
for i in {1..30}; do
    cpu=$(ps -p $PID -o %cpu= | awk '{print $1}')
    samples+=("$cpu")
    sleep 1
done
avg_cpu=$(calculate_mean "${samples[@]}")
```

---

## Statistical Analysis

### Metrics Calculated

For each metric (tracker time, CPU usage, etc.):

#### 1. Mean (μ)
```
μ = (x₁ + x₂ + ... + xₙ) / n
```
The average value across all iterations.

#### 2. Standard Deviation (σ)
```
σ = sqrt( Σ(xᵢ - μ)² / n )
```
Measures variability/spread of data.

#### 3. Confidence Interval (95% CI)
```
CI = μ ± (t_critical × SE)

where:
  SE = σ / sqrt(n)          (Standard Error)
  t_critical = 2.776        (for n=5, df=4, 95% confidence)
```

The 95% CI means: "We are 95% confident the true mean lies within this range."

#### 4. Statistical Significance Test

We use **non-overlapping confidence intervals** as the criterion:

```
If CI_optimized and CI_baseline don't overlap:
  → Statistically significant difference
  → Reject null hypothesis

If CIs overlap:
  → No significant difference
  → Cannot reject null hypothesis
```

**Example:**

```
Baseline:  Mean = 120s,  95% CI = [115, 125]
Optimized: Mean = 30s,   95% CI = [28, 32]

CIs don't overlap → STATISTICALLY SIGNIFICANT improvement
```

### Performance Improvement Calculation

```
Improvement % = ((Baseline - Optimized) / Baseline) × 100

Example:
  Baseline = 120s
  Optimized = 30s
  Improvement = ((120 - 30) / 120) × 100 = 75%
```

---

## Usage Guide

### Prerequisites

```bash
# Install dependencies
apt install bc jq curl mktorrent

# Ensure you have enough disk space (varies by scenario)
df -h
```

### Basic Usage

```bash
# Run complete benchmark (medium scenario, 5,000 torrents)
./qbt-scientific-benchmark.bash

# This will:
# 1. Build baseline qBittorrent (no patches)
# 2. Build optimized qBittorrent (with patches)
# 3. Run 5 iterations of tests on baseline
# 4. Run 5 iterations of tests on optimized
# 5. Analyze results with statistical tests
# 6. Generate report
```

### Advanced Options

```bash
# Test with 1,000 torrents (faster, less rigorous)
./qbt-scientific-benchmark.bash --small

# Test with 10,000 torrents (comprehensive, slower)
./qbt-scientific-benchmark.bash --large

# Only build binaries (skip tests)
./qbt-scientific-benchmark.bash --build-only

# Only run tests (binaries must already exist)
./qbt-scientific-benchmark.bash --test-only

# Build baseline and optimized, then test small scenario
./qbt-scientific-benchmark.bash --small
```

### Customization

Edit variables in the script:

```bash
# Number of test iterations (more = better statistics, but slower)
readonly TEST_ITERATIONS=5        # Increase to 10 for more rigor

# Test scenarios
readonly SCENARIO_SMALL=1000      # Adjust workload sizes
readonly SCENARIO_MEDIUM=5000
readonly SCENARIO_LARGE=10000

# Confidence level
readonly CONFIDENCE_LEVEL=0.95    # 95% confidence (standard)
```

---

## Interpreting Results

### Example Report

```
================================================================
SCIENTIFIC PERFORMANCE BENCHMARK RESULTS
================================================================

Test Scenario: 5000 torrents
Test Iterations: 5
Confidence Level: 0.95 (95%)

================================================================
TRACKER ANNOUNCE TIME (seconds)
================================================================

Baseline (Vanilla):
  Mean: 1247.32s
  Std Dev: 43.21s
  95% CI: [1194.18, 1300.46]
  Raw Data: 1210.5 1255.3 1289.1 1198.2 1283.5

Optimized (Patched):
  Mean: 312.18s
  Std Dev: 18.45s
  95% CI: [288.92, 335.44]
  Raw Data: 298.3 315.7 320.1 305.4 321.4

Performance Change: 74.98% faster
Statistical Significance: YES_BETTER

================================================================
INTERPRETATION
================================================================

Tracker Performance: STATISTICALLY SIGNIFICANT IMPROVEMENT
  The optimized build is significantly faster at tracker announces.
  Confidence intervals don't overlap, indicating real improvement.

================================================================
```

### What to Look For

#### ✅ Good Results

1. **"YES_BETTER"** statistical significance
2. **Large improvement %** (>30%)
3. **Non-overlapping CIs**
4. **Low standard deviation** (consistent results)

**Example:**
```
Baseline:  Mean = 1200s,  CI = [1150, 1250]
Optimized: Mean = 300s,   CI = [280, 320]
Improvement: 75%
Significance: YES_BETTER ✓
```

#### ⚠️ Unclear Results

1. **"NO"** statistical significance
2. **Small improvement %** (<10%)
3. **Overlapping CIs**
4. **High standard deviation** (inconsistent)

**Example:**
```
Baseline:  Mean = 120s,  CI = [100, 140]
Optimized: Mean = 115s,  CI = [95, 135]
Improvement: 4.2%
Significance: NO
```

**Action:** Increase test iterations or check for environmental variability.

#### ❌ Bad Results (Regression)

1. **"YES_WORSE"** statistical significance
2. **Negative improvement %**
3. **Optimized is slower than baseline**

**Example:**
```
Baseline:  Mean = 100s,  CI = [95, 105]
Optimized: Mean = 150s,  CI = [145, 155]
Improvement: -50% (REGRESSION)
Significance: YES_WORSE
```

**Action:** Investigate what went wrong! Check patches, build flags, etc.

### Statistical Significance Explained

**Q: What does "95% confidence" mean?**

A: If we repeated this experiment 100 times, the true mean would fall within the CI in 95 of those experiments.

**Q: Why do CIs matter more than just comparing means?**

A: Because the mean alone doesn't tell you if differences are real or just random variation.

**Example:**

```
Scenario A: Large, consistent difference
  Baseline:  100 ± 2  (CI: [98, 102])
  Optimized: 50 ± 2   (CI: [48, 52])
  → Clear improvement, CIs don't overlap

Scenario B: Small, noisy difference
  Baseline:  100 ± 20 (CI: [80, 120])
  Optimized: 90 ± 20  (CI: [70, 110])
  → Unclear if real improvement, CIs overlap
```

---

## Troubleshooting

### Issue: "No significant difference" but I expected improvement

**Possible Causes:**
1. **Not enough iterations:** Increase `TEST_ITERATIONS` to 10 or 20
2. **Environmental noise:** Close other applications, ensure consistent conditions
3. **Workload too small:** Use `--large` scenario for clearer signals
4. **Optimizations don't help this workload:** Try different metrics

### Issue: High standard deviation

**Possible Causes:**
1. **Background processes:** Ensure clean test environment
2. **Thermal throttling:** Check CPU temperatures
3. **Network variability:** Use local test trackers, not internet
4. **Disk caching:** Clear caches between tests

**Fix:**
```bash
# Clear caches before each test
sync && echo 3 > /proc/sys/vm/drop_caches
```

### Issue: Tests take too long

**Solutions:**
1. Use `--small` scenario (1,000 torrents)
2. Reduce `TEST_ITERATIONS` from 5 to 3
3. Run `--build-only` once, then `--test-only` repeatedly
4. Test specific metrics only (edit script to comment out others)

### Issue: Build failures

**Check:**
```bash
# View build logs
cat benchmark-results/builds/baseline/build.log
cat benchmark-results/builds/optimized/build.log

# Ensure dependencies installed
apt install build-essential cmake autoconf libtool pkg-config
```

---

## Best Practices

### 1. Controlled Environment

- Close unnecessary applications
- Disable cron jobs during testing
- Use dedicated test machine
- Consistent power settings (no CPU frequency scaling)

```bash
# Set CPU governor to performance
for cpu in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
    echo performance > "$cpu"
done
```

### 2. Multiple Test Runs

- Run tests at different times of day
- Run on different days to account for environmental variations
- Combine results for meta-analysis

### 3. Reproducibility Checklist

- [ ] Same kernel version
- [ ] Same compiler version
- [ ] Same library versions
- [ ] Same test data
- [ ] No background network traffic
- [ ] No disk I/O from other processes
- [ ] Sufficient cooling (no thermal throttling)

### 4. Reporting

When sharing results, include:

1. Full report output
2. System specifications (CPU, RAM, disk, network)
3. OS and kernel version
4. Compiler version
5. Test scenario used
6. Any deviations from standard procedure

---

## Scientific Rigor Checklist

- [x] **Randomization:** Tests run in randomized order (prevents bias)
- [x] **Replication:** Multiple iterations (N=5)
- [x] **Control Group:** Baseline build for comparison
- [x] **Blinding:** Automated measurement (no human observation bias)
- [x] **Statistical Analysis:** Confidence intervals and significance testing
- [x] **Reproducibility:** Documented methodology and workload generation
- [x] **Transparency:** All raw data saved for review

---

## References

### Statistical Methods

- **Student's t-distribution:** Used for confidence intervals with small samples (n < 30)
- **Confidence Interval:** Range likely to contain the true population mean
- **Statistical Significance:** Whether observed differences are likely due to chance

### Further Reading

- [Understanding Confidence Intervals](https://en.wikipedia.org/wiki/Confidence_interval)
- [A/B Testing Best Practices](https://en.wikipedia.org/wiki/A/B_testing)
- [Statistical Significance](https://en.wikipedia.org/wiki/Statistical_significance)
- [Standard Error vs Standard Deviation](https://en.wikipedia.org/wiki/Standard_error)

---

## Changelog

### Version 1.0 (2025-01-06)
- Initial scientific testing framework
- A/B comparison with statistical analysis
- Automated workload generation
- Confidence interval calculations
- Significance testing

---

## Contributing

To improve this testing framework:

1. **Add more metrics:** Network latency, disk IOPS, memory allocations
2. **Longer test durations:** For more stable measurements
3. **More scenarios:** Edge cases (100k torrents, slow network, etc.)
4. **Effect size calculations:** Cohen's d for practical significance
5. **Power analysis:** Determine optimal sample size beforehand

---

## License

This testing framework is part of the qbittorrent-nox-static build system.
Same license applies.
