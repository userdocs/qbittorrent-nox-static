#!/bin/bash

# qBittorrent Scientific Performance Benchmark Suite
# A/B testing framework with statistical analysis
# Compares baseline (vanilla) vs optimized builds

set -o pipefail

# ==============================================================================
# Configuration
# ==============================================================================

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly RESULTS_DIR="${SCRIPT_DIR}/benchmark-results"
readonly TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
readonly RUN_ID="${TIMESTAMP}_$$"

# Test scenarios (reproducible workloads)
readonly SCENARIO_SMALL=1000    # 1,000 torrents
readonly SCENARIO_MEDIUM=5000   # 5,000 torrents
readonly SCENARIO_LARGE=10000   # 10,000 torrents

# Number of test iterations for statistical significance
readonly TEST_ITERATIONS=5
readonly WARMUP_DURATION=30
readonly TEST_DURATION=300

# Statistical confidence level
readonly CONFIDENCE_LEVEL=0.95

# Build configurations
declare -A BUILD_CONFIGS=(
	[baseline]="Vanilla libtorrent (no patches)"
	[optimized]="Patched with network threads + EPYC opts"
)

# Color codes
readonly C_RED='\033[0;31m'
readonly C_GREEN='\033[0;32m'
readonly C_YELLOW='\033[0;33m'
readonly C_BLUE='\033[0;34m'
readonly C_CYAN='\033[0;36m'
readonly C_BOLD='\033[1m'
readonly C_END='\033[0m'

# ==============================================================================
# Utility Functions
# ==============================================================================

_print() {
	local level="${1}"
	local message="${2}"

	case "${level}" in
		INFO) printf '%b[INFO]%b %s\n' "${C_BLUE}" "${C_END}" "${message}" ;;
		SUCCESS) printf '%b[PASS]%b %s\n' "${C_GREEN}" "${C_END}" "${message}" ;;
		WARN) printf '%b[WARN]%b %s\n' "${C_YELLOW}" "${C_END}" "${message}" ;;
		ERROR) printf '%b[FAIL]%b %s\n' "${C_RED}" "${C_END}" "${message}" ;;
		HEADER) printf '\n%b%s%b\n' "${C_CYAN}${C_BOLD}" "${message}" "${C_END}" ;;
		*) printf '%s\n' "${message}" ;;
	esac
}

_banner() {
	local text="${1}"
	printf '\n%b%s%b\n' "${C_CYAN}" "$(printf '=%.0s' {1..80})" "${C_END}"
	printf '%b  %s%b\n' "${C_CYAN}${C_BOLD}" "${text}" "${C_END}"
	printf '%b%s%b\n\n' "${C_CYAN}" "$(printf '=%.0s' {1..80})" "${C_END}"
}

_check_deps() {
	local deps=(bc awk sed jq curl)
	local missing=0

	for cmd in "${deps[@]}"; do
		if ! command -v "${cmd}" &> /dev/null; then
			_print ERROR "Missing required command: ${cmd}"
			((missing++))
		fi
	done

	if ((missing > 0)); then
		_print ERROR "Install missing dependencies first"
		exit 1
	fi
}

# ==============================================================================
# Statistical Functions
# ==============================================================================

_calculate_mean() {
	local -a values=("$@")
	local sum=0 count=${#values[@]}

	for val in "${values[@]}"; do
		sum=$(printf '%.6f' "$(printf '%s + %s\n' "${sum}" "${val}" | bc -l)")
	done

	printf '%.6f' "$(printf '%s / %s\n' "${sum}" "${count}" | bc -l)"
}

_calculate_stddev() {
	local mean="${1}"
	shift
	local -a values=("$@")
	local sum_sq_diff=0 count=${#values[@]}

	for val in "${values[@]}"; do
		local diff=$(printf '%s - %s\n' "${val}" "${mean}" | bc -l)
		local sq=$(printf '%s * %s\n' "${diff}" "${diff}" | bc -l)
		sum_sq_diff=$(printf '%.6f' "$(printf '%s + %s\n' "${sum_sq_diff}" "${sq}" | bc -l)")
	done

	local variance=$(printf '%s / %s\n' "${sum_sq_diff}" "${count}" | bc -l)
	printf '%.6f' "$(printf 'sqrt(%s)\n' "${variance}" | bc -l)"
}

_calculate_confidence_interval() {
	local mean="${1}"
	local stddev="${2}"
	local n="${3}"
	# Using t-distribution critical value for 95% CI with small samples
	# For n=5, df=4, t=2.776
	local t_critical=2.776
	local stderr=$(printf '%s / sqrt(%s)\n' "${stddev}" "${n}" | bc -l)
	local margin=$(printf '%s * %s\n' "${t_critical}" "${stderr}" | bc -l)

	local ci_lower=$(printf '%.6f' "$(printf '%s - %s\n' "${mean}" "${margin}" | bc -l)")
	local ci_upper=$(printf '%.6f' "$(printf '%s + %s\n' "${mean}" "${margin}" | bc -l)")

	printf '%s %s' "${ci_lower}" "${ci_upper}"
}

_calculate_improvement() {
	local baseline="${1}"
	local optimized="${2}"

	if (($(printf '%s == 0\n' "${baseline}" | bc -l))); then
		printf 'N/A'
		return
	fi

	local diff=$(printf '%s - %s\n' "${baseline}" "${optimized}" | bc -l)
	local pct=$(printf '(%s / %s) * 100\n' "${diff}" "${baseline}" | bc -l)
	printf '%.2f' "${pct}"
}

_is_significant() {
	local baseline_mean="${1}"
	local baseline_ci_lower="${2}"
	local baseline_ci_upper="${3}"
	local opt_mean="${4}"
	local opt_ci_lower="${5}"
	local opt_ci_upper="${6}"

	# Check if confidence intervals don't overlap
	if (($(printf '%s > %s\n' "${opt_ci_lower}" "${baseline_ci_upper}" | bc -l))); then
		printf 'YES_WORSE'
		return 0
	elif (($(printf '%s < %s\n' "${opt_ci_upper}" "${baseline_ci_lower}" | bc -l))); then
		printf 'YES_BETTER'
		return 0
	else
		printf 'NO'
		return 1
	fi
}

# ==============================================================================
# Build Functions
# ==============================================================================

_build_baseline() {
	_banner "Building Baseline (Vanilla) qBittorrent"

	local build_dir="${RESULTS_DIR}/builds/baseline"
	mkdir -p "${build_dir}"

	_print INFO "Temporarily disabling patches..."

	# Backup patches
	if [[ -d "${SCRIPT_DIR}/patches" ]]; then
		mv "${SCRIPT_DIR}/patches" "${SCRIPT_DIR}/patches.bak"
	fi

	_print INFO "Building vanilla version..."
	cd "${SCRIPT_DIR}" || exit 1

	# Run build without patches
	if ! bash qbittorrent-nox-static.sh all &> "${build_dir}/build.log"; then
		_print ERROR "Baseline build failed - check ${build_dir}/build.log"
		[[ -d "${SCRIPT_DIR}/patches.bak" ]] && mv "${SCRIPT_DIR}/patches.bak" "${SCRIPT_DIR}/patches"
		exit 1
	fi

	# Save baseline binary
	if [[ -f "${SCRIPT_DIR}/qbt-nox-static" ]]; then
		cp "${SCRIPT_DIR}/qbt-nox-static" "${build_dir}/qbittorrent-nox-baseline"
		_print SUCCESS "Baseline binary saved"
	else
		_print ERROR "Baseline binary not found"
		exit 1
	fi

	# Restore patches
	if [[ -d "${SCRIPT_DIR}/patches.bak" ]]; then
		mv "${SCRIPT_DIR}/patches.bak" "${SCRIPT_DIR}/patches"
	fi
}

_build_optimized() {
	_banner "Building Optimized qBittorrent"

	local build_dir="${RESULTS_DIR}/builds/optimized"
	mkdir -p "${build_dir}"

	_print INFO "Building with all optimizations enabled..."
	cd "${SCRIPT_DIR}" || exit 1

	if ! bash qbittorrent-nox-static.sh all &> "${build_dir}/build.log"; then
		_print ERROR "Optimized build failed - check ${build_dir}/build.log"
		exit 1
	fi

	if [[ -f "${SCRIPT_DIR}/qbt-nox-static" ]]; then
		cp "${SCRIPT_DIR}/qbt-nox-static" "${build_dir}/qbittorrent-nox-optimized"
		_print SUCCESS "Optimized binary saved"
	else
		_print ERROR "Optimized binary not found"
		exit 1
	fi
}

# ==============================================================================
# Test Workload Generation
# ==============================================================================

_generate_test_torrents() {
	local num_torrents="${1}"
	local test_dir="${2}"

	_print INFO "Generating ${num_torrents} test torrents..."

	mkdir -p "${test_dir}/torrents"
	mkdir -p "${test_dir}/data"

	for ((i=1; i<=num_torrents; i++)); do
		# Create minimal test file
		local file="${test_dir}/data/file_${i}.dat"
		dd if=/dev/urandom of="${file}" bs=1M count=1 2>/dev/null

		# Create .torrent file using mktorrent or transmission-create
		if command -v mktorrent &> /dev/null; then
			mktorrent -p -l 18 -a "http://tracker.example.com:8000/announce" \
				-o "${test_dir}/torrents/test_${i}.torrent" "${file}" 2>/dev/null
		elif command -v transmission-create &> /dev/null; then
			transmission-create -p -t "http://tracker.example.com:8000/announce" \
				-o "${test_dir}/torrents/test_${i}.torrent" "${file}" 2>/dev/null
		else
			_print WARN "No torrent creation tool found (mktorrent or transmission-create)"
			_print WARN "Using mock torrents - results may not be fully representative"
			# Create a minimal mock torrent file
			printf 'd8:announce33:http://tracker.example.com:80004:infod6:lengthi1048576e4:name12:file_%d.dat12:piece lengthi262144e6:pieces20:' "${i}" > "${test_dir}/torrents/test_${i}.torrent"
			printf '\x00%.0s' {1..20} >> "${test_dir}/torrents/test_${i}.torrent"
			printf 'ee' >> "${test_dir}/torrents/test_${i}.torrent"
		fi

		if ((i % 500 == 0)); then
			_print INFO "Generated ${i}/${num_torrents} torrents..."
		fi
	done

	_print SUCCESS "Generated ${num_torrents} test torrents"
}

# ==============================================================================
# Performance Measurement
# ==============================================================================

_measure_tracker_announce_time() {
	local qbt_binary="${1}"
	local test_dir="${2}"
	local num_torrents="${3}"

	_print INFO "Measuring tracker announce time for ${num_torrents} torrents..."

	# Start qBittorrent
	"${qbt_binary}" --daemon --webui-port=8999 &> /dev/null
	local qbt_pid=$!
	sleep 10

	# Add all torrents
	local start_time=$(date +%s.%N)

	for torrent in "${test_dir}"/torrents/*.torrent; do
		# Use qBittorrent Web API to add torrents
		curl -s -X POST "http://localhost:8999/api/v2/torrents/add" \
			-F "torrents=@${torrent}" &> /dev/null
	done

	# Wait for all tracker announces to complete
	sleep 5

	# Check tracker status
	local all_announced=0
	local timeout=600
	local elapsed=0

	while ((all_announced == 0 && elapsed < timeout)); do
		local response=$(curl -s "http://localhost:8999/api/v2/torrents/info")
		local announced=$(printf '%s' "${response}" | jq '[.[] | select(.tracker_status | contains("Working"))] | length')

		if ((announced >= num_torrents * 9 / 10)); then  # 90% threshold
			all_announced=1
		else
			sleep 5
			((elapsed += 5))
		fi
	done

	local end_time=$(date +%s.%N)
	local duration=$(printf '%.2f' "$(printf '%s - %s\n' "${end_time}" "${start_time}" | bc -l)")

	# Cleanup
	kill "${qbt_pid}" 2>/dev/null
	wait "${qbt_pid}" 2>/dev/null

	printf '%s' "${duration}"
}

_measure_network_throughput() {
	local qbt_binary="${1}"

	# Measure network handler throughput
	_print INFO "Measuring network I/O throughput..."

	"${qbt_binary}" --daemon --webui-port=8999 &> /dev/null
	local qbt_pid=$!
	sleep 10

	# Measure network connections per second
	local start_conns=$(ss -s | grep 'TCP:' | awk '{print $2}')
	sleep 10
	local end_conns=$(ss -s | grep 'TCP:' | awk '{print $2}')

	local throughput=$(printf '%s' "$(((end_conns - start_conns) / 10))")

	kill "${qbt_pid}" 2>/dev/null
	wait "${qbt_pid}" 2>/dev/null

	printf '%s' "${throughput}"
}

_measure_cpu_efficiency() {
	local qbt_binary="${1}"
	local test_dir="${2}"

	_print INFO "Measuring CPU efficiency under load..."

	"${qbt_binary}" --daemon --webui-port=8999 &> /dev/null
	local qbt_pid=$!
	sleep 10

	# Add torrents
	for torrent in "${test_dir}"/torrents/*.torrent; do
		curl -s -X POST "http://localhost:8999/api/v2/torrents/add" \
			-F "torrents=@${torrent}" &> /dev/null
	done

	sleep 5

	# Measure CPU usage
	local cpu_samples=()
	for ((i=0; i<30; i++)); do
		local cpu=$(ps -p "${qbt_pid}" -o %cpu= | awk '{print $1}')
		cpu_samples+=("${cpu}")
		sleep 1
	done

	# Calculate average
	local sum=0
	for val in "${cpu_samples[@]}"; do
		sum=$(printf '%.2f' "$(printf '%s + %s\n' "${sum}" "${val}" | bc -l)")
	done
	local avg_cpu=$(printf '%.2f' "$(printf '%s / %s\n' "${sum}" "${#cpu_samples[@]}" | bc -l)")

	kill "${qbt_pid}" 2>/dev/null
	wait "${qbt_pid}" 2>/dev/null

	printf '%s' "${avg_cpu}"
}

# ==============================================================================
# Test Execution
# ==============================================================================

_run_test_suite() {
	local build_name="${1}"
	local qbt_binary="${2}"
	local num_torrents="${3}"
	local iteration="${4}"

	_print HEADER "Running Test Suite: ${build_name} - ${num_torrents} torrents - Iteration ${iteration}"

	local test_dir="${RESULTS_DIR}/tests/${build_name}_${num_torrents}_iter${iteration}"
	mkdir -p "${test_dir}"

	# Generate test workload
	_generate_test_torrents "${num_torrents}" "${test_dir}"

	# Measure metrics
	local tracker_time=$(_measure_tracker_announce_time "${qbt_binary}" "${test_dir}" "${num_torrents}")
	local cpu_usage=$(_measure_cpu_efficiency "${qbt_binary}" "${test_dir}")

	# Save results
	cat > "${test_dir}/results.json" <<-EOF
	{
		"build": "${build_name}",
		"torrents": ${num_torrents},
		"iteration": ${iteration},
		"tracker_announce_time": ${tracker_time},
		"cpu_usage": ${cpu_usage},
		"timestamp": "$(date -Iseconds)"
	}
	EOF

	_print SUCCESS "Tracker announce time: ${tracker_time}s"
	_print SUCCESS "CPU usage: ${cpu_usage}%"

	printf '%s %s' "${tracker_time}" "${cpu_usage}"
}

# ==============================================================================
# Statistical Analysis & Reporting
# ==============================================================================

_analyze_results() {
	_banner "Statistical Analysis"

	local scenario="${1}"
	local baseline_results=("${@:2:TEST_ITERATIONS}")
	local optimized_results=("${@:$((TEST_ITERATIONS+2)):TEST_ITERATIONS}")

	# Split tracker time and CPU usage
	local -a baseline_tracker=()
	local -a baseline_cpu=()
	local -a opt_tracker=()
	local -a opt_cpu=()

	for result in "${baseline_results[@]}"; do
		baseline_tracker+=("$(printf '%s' "${result}" | awk '{print $1}')")
		baseline_cpu+=("$(printf '%s' "${result}" | awk '{print $2}')")
	done

	for result in "${optimized_results[@]}"; do
		opt_tracker+=("$(printf '%s' "${result}" | awk '{print $1}')")
		opt_cpu+=("$(printf '%s' "${result}" | awk '{print $2}')")
	done

	# Calculate statistics for tracker announce time
	local b_tracker_mean=$(_calculate_mean "${baseline_tracker[@]}")
	local b_tracker_std=$(_calculate_stddev "${b_tracker_mean}" "${baseline_tracker[@]}")
	read -r b_tracker_ci_l b_tracker_ci_u <<< "$(_calculate_confidence_interval "${b_tracker_mean}" "${b_tracker_std}" "${TEST_ITERATIONS}")"

	local o_tracker_mean=$(_calculate_mean "${opt_tracker[@]}")
	local o_tracker_std=$(_calculate_stddev "${o_tracker_mean}" "${opt_tracker[@]}")
	read -r o_tracker_ci_l o_tracker_ci_u <<< "$(_calculate_confidence_interval "${o_tracker_mean}" "${o_tracker_std}" "${TEST_ITERATIONS}")"

	# Calculate statistics for CPU usage
	local b_cpu_mean=$(_calculate_mean "${baseline_cpu[@]}")
	local b_cpu_std=$(_calculate_stddev "${b_cpu_mean}" "${baseline_cpu[@]}")
	read -r b_cpu_ci_l b_cpu_ci_u <<< "$(_calculate_confidence_interval "${b_cpu_mean}" "${b_cpu_std}" "${TEST_ITERATIONS}")"

	local o_cpu_mean=$(_calculate_mean "${opt_cpu[@]}")
	local o_cpu_std=$(_calculate_stddev "${o_cpu_mean}" "${opt_cpu[@]}")
	read -r o_cpu_ci_l o_cpu_ci_u <<< "$(_calculate_confidence_interval "${o_cpu_mean}" "${o_cpu_std}" "${TEST_ITERATIONS}")"

	# Calculate improvements
	local tracker_improvement=$(_calculate_improvement "${b_tracker_mean}" "${o_tracker_mean}")
	local cpu_improvement=$(_calculate_improvement "${b_cpu_mean}" "${o_cpu_mean}")

	# Statistical significance
	local tracker_sig=$(_is_significant "${b_tracker_mean}" "${b_tracker_ci_l}" "${b_tracker_ci_u}" \
		"${o_tracker_mean}" "${o_tracker_ci_l}" "${o_tracker_ci_u}")
	local cpu_sig=$(_is_significant "${b_cpu_mean}" "${b_cpu_ci_l}" "${b_cpu_ci_u}" \
		"${o_cpu_mean}" "${o_cpu_ci_l}" "${o_cpu_ci_u}")

	# Generate report
	cat > "${RESULTS_DIR}/analysis_${scenario}_${RUN_ID}.txt" <<-EOF
	================================================================
	SCIENTIFIC PERFORMANCE BENCHMARK RESULTS
	================================================================

	Test Scenario: ${scenario} torrents
	Test Iterations: ${TEST_ITERATIONS}
	Confidence Level: ${CONFIDENCE_LEVEL} (95%)
	Timestamp: $(date -Iseconds)

	================================================================
	TRACKER ANNOUNCE TIME (seconds)
	================================================================

	Baseline (Vanilla):
	  Mean: ${b_tracker_mean}s
	  Std Dev: ${b_tracker_std}s
	  95% CI: [${b_tracker_ci_l}, ${b_tracker_ci_u}]
	  Raw Data: ${baseline_tracker[*]}

	Optimized (Patched):
	  Mean: ${o_tracker_mean}s
	  Std Dev: ${o_tracker_std}s
	  95% CI: [${o_tracker_ci_l}, ${o_tracker_ci_u}]
	  Raw Data: ${opt_tracker[*]}

	Performance Change: ${tracker_improvement}% faster
	Statistical Significance: ${tracker_sig}

	================================================================
	CPU USAGE (%)
	================================================================

	Baseline (Vanilla):
	  Mean: ${b_cpu_mean}%
	  Std Dev: ${b_cpu_std}%
	  95% CI: [${b_cpu_ci_l}, ${b_cpu_ci_u}]
	  Raw Data: ${baseline_cpu[*]}

	Optimized (Patched):
	  Mean: ${o_cpu_mean}%
	  Std Dev: ${o_cpu_std}%
	  95% CI: [${o_cpu_ci_l}, ${o_cpu_ci_u}]
	  Raw Data: ${opt_cpu[*]}

	Performance Change: ${cpu_improvement}% reduction
	Statistical Significance: ${cpu_sig}

	================================================================
	INTERPRETATION
	================================================================

	EOF

	# Add interpretation
	if [[ ${tracker_sig} == "YES_BETTER" ]]; then
		printf 'Tracker Performance: STATISTICALLY SIGNIFICANT IMPROVEMENT\n' >> "${RESULTS_DIR}/analysis_${scenario}_${RUN_ID}.txt"
		printf '  The optimized build is significantly faster at tracker announces.\n' >> "${RESULTS_DIR}/analysis_${scenario}_${RUN_ID}.txt"
	elif [[ ${tracker_sig} == "YES_WORSE" ]]; then
		printf 'Tracker Performance: STATISTICALLY SIGNIFICANT REGRESSION\n' >> "${RESULTS_DIR}/analysis_${scenario}_${RUN_ID}.txt"
		printf '  The optimized build is significantly slower (investigate!).\n' >> "${RESULTS_DIR}/analysis_${scenario}_${RUN_ID}.txt"
	else
		printf 'Tracker Performance: NO SIGNIFICANT DIFFERENCE\n' >> "${RESULTS_DIR}/analysis_${scenario}_${RUN_ID}.txt"
		printf '  Performance change is within margin of error.\n' >> "${RESULTS_DIR}/analysis_${scenario}_${RUN_ID}.txt"
	fi

	printf '\n' >> "${RESULTS_DIR}/analysis_${scenario}_${RUN_ID}.txt"

	if [[ ${cpu_sig} == "YES_BETTER" ]]; then
		printf 'CPU Efficiency: STATISTICALLY SIGNIFICANT IMPROVEMENT\n' >> "${RESULTS_DIR}/analysis_${scenario}_${RUN_ID}.txt"
		printf '  The optimized build uses significantly less CPU.\n' >> "${RESULTS_DIR}/analysis_${scenario}_${RUN_ID}.txt"
	elif [[ ${cpu_sig} == "YES_WORSE" ]]; then
		printf 'CPU Efficiency: STATISTICALLY SIGNIFICANT REGRESSION\n' >> "${RESULTS_DIR}/analysis_${scenario}_${RUN_ID}.txt"
		printf '  The optimized build uses significantly more CPU (investigate!).\n' >> "${RESULTS_DIR}/analysis_${scenario}_${RUN_ID}.txt"
	else
		printf 'CPU Efficiency: NO SIGNIFICANT DIFFERENCE\n' >> "${RESULTS_DIR}/analysis_${scenario}_${RUN_ID}.txt"
		printf '  CPU usage change is within margin of error.\n' >> "${RESULTS_DIR}/analysis_${scenario}_${RUN_ID}.txt"
	fi

	printf '\n================================================================\n' >> "${RESULTS_DIR}/analysis_${scenario}_${RUN_ID}.txt"

	# Display results
	cat "${RESULTS_DIR}/analysis_${scenario}_${RUN_ID}.txt"
}

# ==============================================================================
# Main Execution
# ==============================================================================

main() {
	_banner "qBittorrent Scientific Performance Benchmark"

	_check_deps

	mkdir -p "${RESULTS_DIR}"

	# Parse arguments
	local build_only=0
	local test_only=0
	local scenario="${SCENARIO_MEDIUM}"

	while [[ $# -gt 0 ]]; do
		case "${1}" in
			--build-only) build_only=1; shift ;;
			--test-only) test_only=1; shift ;;
			--small) scenario="${SCENARIO_SMALL}"; shift ;;
			--medium) scenario="${SCENARIO_MEDIUM}"; shift ;;
			--large) scenario="${SCENARIO_LARGE}"; shift ;;
			--help)
				cat <<-EOF
				Usage: $0 [OPTIONS]

				Options:
				  --build-only    Only build binaries, don't run tests
				  --test-only     Only run tests (binaries must exist)
				  --small         Test with ${SCENARIO_SMALL} torrents
				  --medium        Test with ${SCENARIO_MEDIUM} torrents (default)
				  --large         Test with ${SCENARIO_LARGE} torrents
				  --help          Show this help

				This script performs scientific A/B performance testing:
				1. Builds baseline (vanilla) and optimized qBittorrent
				2. Runs reproducible test workloads
				3. Collects performance metrics with statistical rigor
				4. Analyzes results with confidence intervals
				5. Reports statistically significant differences
				EOF
				exit 0
				;;
			*) _print ERROR "Unknown option: ${1}"; exit 1 ;;
		esac
	done

	# Build phase
	if ((build_only == 1 || test_only == 0)); then
		_build_baseline
		_build_optimized
	fi

	# Test phase
	if ((test_only == 1 || build_only == 0)); then
		local baseline_bin="${RESULTS_DIR}/builds/baseline/qbittorrent-nox-baseline"
		local optimized_bin="${RESULTS_DIR}/builds/optimized/qbittorrent-nox-optimized"

		if [[ ! -f ${baseline_bin} || ! -f ${optimized_bin} ]]; then
			_print ERROR "Binaries not found. Run with --build-only first."
			exit 1
		fi

		_banner "Running ${TEST_ITERATIONS} Iterations per Build"

		# Run baseline tests
		local -a baseline_results=()
		for ((i=1; i<=TEST_ITERATIONS; i++)); do
			local result=$(_run_test_suite "baseline" "${baseline_bin}" "${scenario}" "${i}")
			baseline_results+=("${result}")
		done

		# Run optimized tests
		local -a optimized_results=()
		for ((i=1; i<=TEST_ITERATIONS; i++)); do
			local result=$(_run_test_suite "optimized" "${optimized_bin}" "${scenario}" "${i}")
			optimized_results+=("${result}")
		done

		# Analyze results
		_analyze_results "${scenario}" "${baseline_results[@]}" "${optimized_results[@]}"
	fi

	_print SUCCESS "Benchmark complete! Results in: ${RESULTS_DIR}"
}

main "$@"
