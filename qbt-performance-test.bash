#!/bin/bash

# qBittorrent Performance Testing Toolkit
# Comprehensive performance assessment for qBittorrent-nox
# Tests network, disk, memory, CPU, and connection performance

set -o pipefail

# Color codes for output
readonly color_red='\033[0;31m'
readonly color_green='\033[0;32m'
readonly color_yellow='\033[0;33m'
readonly color_blue='\033[0;34m'
readonly color_cyan='\033[0;36m'
readonly color_end='\033[0m'

# Test configuration
TEST_DURATION=60
QBT_HOST="localhost"
QBT_PORT="8080"
QBT_USER="admin"
QBT_PASS=""
OUTPUT_DIR="./qbt-perf-results"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Performance thresholds (can be adjusted)
THRESHOLD_CPU_IDLE=10
THRESHOLD_MEM_MB=2048
THRESHOLD_DISK_IOPS=50000
THRESHOLD_NET_MBPS=1000

# Print functions
_print() {
	local level="${1}"
	local message="${2}"

	case "${level}" in
		INFO) printf '%b[INFO]%b %s\n' "${color_blue}" "${color_end}" "${message}" ;;
		SUCCESS) printf '%b[SUCCESS]%b %s\n' "${color_green}" "${color_end}" "${message}" ;;
		WARNING) printf '%b[WARNING]%b %s\n' "${color_yellow}" "${color_end}" "${message}" ;;
		ERROR) printf '%b[ERROR]%b %s\n' "${color_red}" "${color_end}" "${message}" ;;
		*) printf '%s\n' "${message}" ;;
	esac
}

_banner() {
	local text="${1}"
	printf '\n%b%s%b\n' "${color_cyan}" "$(printf '=%.0s' {1..80})" "${color_end}"
	printf '%b%s%b\n' "${color_cyan}" "${text}" "${color_end}"
	printf '%b%s%b\n\n' "${color_cyan}" "$(printf '=%.0s' {1..80})" "${color_end}"
}

# Check dependencies
_check_dependencies() {
	local missing=0
	local deps=(curl jq bc iostat sar ss iftop pidstat nproc free df lscpu)

	_banner "Checking Dependencies"

	for cmd in "${deps[@]}"; do
		if ! command -v "${cmd}" &> /dev/null; then
			_print ERROR "Missing required command: ${cmd}"
			((missing++))
		else
			_print SUCCESS "Found: ${cmd}"
		fi
	done

	if ((missing > 0)); then
		_print ERROR "Please install missing dependencies:"
		_print INFO "Debian/Ubuntu: apt install sysstat iotop iftop jq bc curl procps"
		exit 1
	fi
}

# Detect qBittorrent process
_detect_qbt() {
	_banner "Detecting qBittorrent"

	QBT_PID=$(pgrep -x qbittorrent-nox | head -1)

	if [[ -z ${QBT_PID} ]]; then
		_print WARNING "qBittorrent-nox not running"
		_print INFO "Please start qBittorrent-nox before running tests"
		exit 1
	fi

	_print SUCCESS "Found qBittorrent-nox (PID: ${QBT_PID})"

	# Get binary path
	QBT_BIN=$(readlink -f "/proc/${QBT_PID}/exe")
	_print INFO "Binary: ${QBT_BIN}"

	# Check if optimized build
	if readelf -p .comment "${QBT_BIN}" 2>/dev/null | grep -q "O3"; then
		_print SUCCESS "Optimized build detected (-O3)"
	else
		_print WARNING "Build optimization level unknown"
	fi

	if file "${QBT_BIN}" | grep -q "stripped"; then
		_print SUCCESS "Debug symbols stripped (production build)"
	else
		_print WARNING "Debug symbols present (development build)"
	fi
}

# System information
_system_info() {
	_banner "System Information"

	mkdir -p "${OUTPUT_DIR}"
	local sysinfo="${OUTPUT_DIR}/sysinfo_${TIMESTAMP}.txt"

	{
		printf 'System Information\n'
		printf '==================\n\n'

		printf 'CPU:\n'
		lscpu | grep -E '(Model name|Socket|Core|Thread|MHz|Flags)' | sed 's/^/  /'
		printf '\n'

		printf 'Memory:\n'
		free -h | sed 's/^/  /'
		printf '\n'

		printf 'Disk:\n'
		df -h | grep -E '(Filesystem|nvme|sda|mapper)' | sed 's/^/  /'
		printf '\n'

		printf 'Network:\n'
		ip -br link | sed 's/^/  /'
		printf '\n'

		printf 'Kernel:\n'
		uname -a | sed 's/^/  /'
		printf '\n'

		printf 'System Limits:\n'
		printf '  File descriptors: %s\n' "$(ulimit -n)"
		printf '  Max processes: %s\n' "$(ulimit -u)"
		printf '  Max locked memory: %s\n' "$(ulimit -l)"

	} | tee "${sysinfo}"

	_print SUCCESS "System info saved to: ${sysinfo}"
}

# CPU performance test
_test_cpu() {
	_banner "CPU Performance Test"

	local cpu_log="${OUTPUT_DIR}/cpu_${TIMESTAMP}.log"

	_print INFO "Monitoring CPU for ${TEST_DURATION} seconds..."
	_print INFO "PID: ${QBT_PID}"

	# Capture CPU usage
	{
		printf 'Timestamp,CPU%%,User%%,System%%,IO-Wait%%\n'
		for ((i=0; i<TEST_DURATION; i++)); do
			read -r cpu user sys iowait _ < <(top -b -n1 -p "${QBT_PID}" | awk -v pid="${QBT_PID}" '$1==pid {print $9,$10,$11,$12}')
			printf '%s,%.1f,%.1f,%.1f,%.1f\n' "$(date +%s)" "${cpu:-0}" "${user:-0}" "${sys:-0}" "${iowait:-0}"
			sleep 1
		done
	} > "${cpu_log}"

	# Analyze results
	local avg_cpu=$(awk -F',' 'NR>1 {sum+=$2; count++} END {if(count>0) print sum/count; else print 0}' "${cpu_log}")
	local max_cpu=$(awk -F',' 'NR>1 {if($2>max) max=$2} END {print max+0}' "${cpu_log}")

	_print SUCCESS "Average CPU: ${avg_cpu}%"
	_print SUCCESS "Peak CPU: ${max_cpu}%"

	if (($(printf '%s>%s\n' "${avg_cpu}" "${THRESHOLD_CPU_IDLE}" | bc -l))); then
		_print WARNING "High average CPU usage (threshold: ${THRESHOLD_CPU_IDLE}%)"
	fi

	_print INFO "CPU data saved to: ${cpu_log}"
}

# Memory performance test
_test_memory() {
	_banner "Memory Performance Test"

	local mem_log="${OUTPUT_DIR}/memory_${TIMESTAMP}.log"

	_print INFO "Monitoring memory for ${TEST_DURATION} seconds..."

	{
		printf 'Timestamp,RSS_MB,VSZ_MB,Shared_MB,Mem%%\n'
		for ((i=0; i<TEST_DURATION; i++)); do
			read -r rss vsz shr mem _ < <(ps -p "${QBT_PID}" -o rss=,vsz=,rss=,%mem= | awk '{print $1/1024, $2/1024, $3/1024, $4}')
			printf '%s,%.2f,%.2f,%.2f,%.2f\n' "$(date +%s)" "${rss:-0}" "${vsz:-0}" "${shr:-0}" "${mem:-0}"
			sleep 1
		done
	} > "${mem_log}"

	local avg_mem=$(awk -F',' 'NR>1 {sum+=$2; count++} END {if(count>0) print sum/count; else print 0}' "${mem_log}")
	local max_mem=$(awk -F',' 'NR>1 {if($2>max) max=$2} END {print max+0}' "${mem_log}")

	_print SUCCESS "Average Memory: ${avg_mem} MB"
	_print SUCCESS "Peak Memory: ${max_mem} MB"

	if (($(printf '%s>%s\n' "${max_mem}" "${THRESHOLD_MEM_MB}" | bc -l))); then
		_print WARNING "High memory usage (threshold: ${THRESHOLD_MEM_MB} MB)"
	fi

	_print INFO "Memory data saved to: ${mem_log}"
}

# Disk I/O performance test
_test_disk_io() {
	_banner "Disk I/O Performance Test"

	local disk_log="${OUTPUT_DIR}/disk_${TIMESTAMP}.log"

	# Find qBittorrent's main disk device
	local data_dir=$(lsof -p "${QBT_PID}" 2>/dev/null | grep -E '\\.fastresume$' | head -1 | awk '{print $NF}')
	if [[ -z ${data_dir} ]]; then
		_print WARNING "Could not detect qBittorrent data directory"
		return
	fi

	local disk_dev=$(df "${data_dir}" | awk 'NR==2 {print $1}' | sed 's/[0-9]*$//' | sed 's|/dev/||')

	_print INFO "Monitoring disk: ${disk_dev} for ${TEST_DURATION} seconds..."

	iostat -dx "${disk_dev}" 1 "${TEST_DURATION}" | awk '
		BEGIN {print "Timestamp,Read_MB/s,Write_MB/s,IOPS_Read,IOPS_Write,Util%"}
		/^'${disk_dev}'/ {
			printf "%s,%.2f,%.2f,%.0f,%.0f,%.2f\n",
				systime(), $6/1024, $7/1024, $4, $5, $NF
		}
	' > "${disk_log}"

	local avg_read=$(awk -F',' 'NR>1 {sum+=$2; count++} END {if(count>0) print sum/count; else print 0}' "${disk_log}")
	local avg_write=$(awk -F',' 'NR>1 {sum+=$3; count++} END {if(count>0) print sum/count; else print 0}' "${disk_log}")
	local max_util=$(awk -F',' 'NR>1 {if($6>max) max=$6} END {print max+0}' "${disk_log}")

	_print SUCCESS "Average Read: ${avg_read} MB/s"
	_print SUCCESS "Average Write: ${avg_write} MB/s"
	_print SUCCESS "Peak Utilization: ${max_util}%"

	_print INFO "Disk I/O data saved to: ${disk_log}"
}

# Network performance test
_test_network() {
	_banner "Network Performance Test"

	local net_log="${OUTPUT_DIR}/network_${TIMESTAMP}.log"

	_print INFO "Monitoring network for ${TEST_DURATION} seconds..."

	# Get primary network interface
	local net_if=$(ip route | grep default | awk '{print $5}' | head -1)

	{
		printf 'Timestamp,RX_Mbps,TX_Mbps,Connections,Listen_Ports\n'
		for ((i=0; i<TEST_DURATION; i++)); do
			# Network throughput
			read -r rx1 tx1 < <(cat "/sys/class/net/${net_if}/statistics/rx_bytes" "/sys/class/net/${net_if}/statistics/tx_bytes")
			sleep 1
			read -r rx2 tx2 < <(cat "/sys/class/net/${net_if}/statistics/rx_bytes" "/sys/class/net/${net_if}/statistics/tx_bytes")

			rx_mbps=$(printf '%s\n' "scale=2; (${rx2:-0}-${rx1:-0})*8/1000000" | bc)
			tx_mbps=$(printf '%s\n' "scale=2; (${tx2:-0}-${tx1:-0})*8/1000000" | bc)

			# Connection count
			conns=$(ss -tn state established | grep -c ":${QBT_PORT:-8080}")
			listen=$(ss -tln | grep -c ":${QBT_PORT:-8080}")

			printf '%s,%.2f,%.2f,%d,%d\n' "$(date +%s)" "${rx_mbps}" "${tx_mbps}" "${conns}" "${listen}"
		done
	} > "${net_log}"

	local avg_rx=$(awk -F',' 'NR>1 {sum+=$2; count++} END {if(count>0) print sum/count; else print 0}' "${net_log}")
	local avg_tx=$(awk -F',' 'NR>1 {sum+=$3; count++} END {if(count>0) print sum/count; else print 0}' "${net_log}")
	local max_conns=$(awk -F',' 'NR>1 {if($4>max) max=$4} END {print max+0}' "${net_log}")

	_print SUCCESS "Average RX: ${avg_rx} Mbps"
	_print SUCCESS "Average TX: ${avg_tx} Mbps"
	_print SUCCESS "Peak Connections: ${max_conns}"

	_print INFO "Network data saved to: ${net_log}"
}

# Connection performance test
_test_connections() {
	_banner "Connection Performance Test"

	local conn_log="${OUTPUT_DIR}/connections_${TIMESTAMP}.log"

	_print INFO "Analyzing connections for ${TEST_DURATION} seconds..."

	{
		printf 'Timestamp,Total,Established,Time-Wait,Close-Wait,Listen\n'
		for ((i=0; i<TEST_DURATION; i++)); do
			local total=$(ss -tan | grep -c "^ESTAB\|^TIME-WAIT\|^CLOSE-WAIT")
			local estab=$(ss -tan state established | wc -l)
			local timewait=$(ss -tan state time-wait | wc -l)
			local closewait=$(ss -tan state close-wait | wc -l)
			local listen=$(ss -tln | wc -l)

			printf '%s,%d,%d,%d,%d,%d\n' "$(date +%s)" "$((total))" "$((estab))" "$((timewait))" "$((closewait))" "$((listen))"
			sleep 1
		done
	} > "${conn_log}"

	local avg_estab=$(awk -F',' 'NR>1 {sum+=$3; count++} END {if(count>0) print sum/count; else print 0}' "${conn_log}")
	local max_total=$(awk -F',' 'NR>1 {if($2>max) max=$2} END {print max+0}' "${conn_log}")

	_print SUCCESS "Average Established: ${avg_estab}"
	_print SUCCESS "Peak Total: ${max_total}"

	_print INFO "Connection data saved to: ${conn_log}"
}

# File descriptor test
_test_file_descriptors() {
	_banner "File Descriptor Test"

	local fd_count=$(ls -1 "/proc/${QBT_PID}/fd" 2>/dev/null | wc -l)
	local fd_limit=$(grep "Max open files" "/proc/${QBT_PID}/limits" | awk '{print $4}')
	local fd_percent=$(printf '%s\n' "scale=2; ${fd_count}*100/${fd_limit}" | bc)

	_print INFO "Open file descriptors: ${fd_count} / ${fd_limit} (${fd_percent}%)"

	if ((fd_count > fd_limit * 80 / 100)); then
		_print WARNING "File descriptor usage >80%"
	else
		_print SUCCESS "File descriptor usage healthy"
	fi
}

# Generate performance report
_generate_report() {
	_banner "Generating Performance Report"

	local report="${OUTPUT_DIR}/performance_report_${TIMESTAMP}.txt"

	{
		printf 'qBittorrent Performance Test Report\n'
		printf '====================================\n\n'
		printf 'Test Date: %s\n' "$(date)"
		printf 'Test Duration: %d seconds\n\n' "${TEST_DURATION}"

		printf 'System Configuration\n'
		printf '-------------------\n'
		lscpu | grep "Model name" | sed 's/Model name://;s/^[ \t]*//'
		printf 'Memory: %s\n' "$(free -h | awk '/^Mem:/ {print $2}')"
		printf 'qBittorrent PID: %s\n' "${QBT_PID}"
		printf 'Binary: %s\n\n' "${QBT_BIN}"

		printf 'Performance Summary\n'
		printf '------------------\n'
		printf 'CPU:\n'
		awk -F',' 'NR>1 {sum+=$2; count++; if($2>max) max=$2} END {
			printf "  Average: %.2f%%\n  Peak: %.2f%%\n", sum/count, max
		}' "${OUTPUT_DIR}/cpu_${TIMESTAMP}.log"

		printf '\nMemory:\n'
		awk -F',' 'NR>1 {sum+=$2; count++; if($2>max) max=$2} END {
			printf "  Average: %.2f MB\n  Peak: %.2f MB\n", sum/count, max
		}' "${OUTPUT_DIR}/memory_${TIMESTAMP}.log"

		if [[ -f "${OUTPUT_DIR}/disk_${TIMESTAMP}.log" ]]; then
			printf '\nDisk I/O:\n'
			awk -F',' 'NR>1 {r+=$2; w+=$3; count++} END {
				printf "  Average Read: %.2f MB/s\n  Average Write: %.2f MB/s\n", r/count, w/count
			}' "${OUTPUT_DIR}/disk_${TIMESTAMP}.log"
		fi

		printf '\nNetwork:\n'
		awk -F',' 'NR>1 {rx+=$2; tx+=$3; count++; if($4>max_conn) max_conn=$4} END {
			printf "  Average RX: %.2f Mbps\n  Average TX: %.2f Mbps\n  Peak Connections: %d\n",
				rx/count, tx/count, max_conn
		}' "${OUTPUT_DIR}/network_${TIMESTAMP}.log"

		printf '\nFile Descriptors: %s / %s\n' "${fd_count}" "${fd_limit}"

		printf '\n\nData Files\n'
		printf '----------\n'
		ls -1 "${OUTPUT_DIR}"/*_"${TIMESTAMP}".* | sed 's/^/  /'

	} | tee "${report}"

	_print SUCCESS "Performance report: ${report}"
}

# Main execution
main() {
	_banner "qBittorrent Performance Testing Toolkit"

	_check_dependencies
	_detect_qbt
	_system_info

	_print INFO "Starting performance tests (${TEST_DURATION}s each)..."
	printf '\n'

	_test_cpu
	_test_memory
	_test_disk_io
	_test_network
	_test_connections
	_test_file_descriptors

	_generate_report

	_banner "Testing Complete"
	_print SUCCESS "All results saved to: ${OUTPUT_DIR}/"
	_print INFO "Review ${OUTPUT_DIR}/performance_report_${TIMESTAMP}.txt for summary"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
	case "${1}" in
		-d|--duration)
			TEST_DURATION="${2}"
			shift 2
			;;
		-o|--output)
			OUTPUT_DIR="${2}"
			shift 2
			;;
		-h|--help)
			printf 'Usage: %s [OPTIONS]\n\n' "$0"
			printf 'Options:\n'
			printf '  -d, --duration SECONDS  Test duration (default: 60)\n'
			printf '  -o, --output DIR        Output directory (default: ./qbt-perf-results)\n'
			printf '  -h, --help              Show this help\n'
			exit 0
			;;
		*)
			_print ERROR "Unknown option: ${1}"
			exit 1
			;;
	esac
done

main
