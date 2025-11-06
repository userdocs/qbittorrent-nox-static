#!/bin/bash

# Simple qBittorrent Performance Test
# Builds binary, tests with real torrents, logs speeds to CSV

set -o pipefail

# ==============================================================================
# Configuration
# ==============================================================================

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly STORAGE_DIR="/mnt/storage"
readonly TEST_TORRENTS_DIR="${SCRIPT_DIR}/test_torrents"
readonly QBT_CONFIG_DIR="${SCRIPT_DIR}/.qbt-test-config"
readonly QBT_PORT=8999
readonly RESULTS_CSV="${SCRIPT_DIR}/performance-results.csv"
readonly TEST_DURATION=300  # 5 minutes per test

# Color codes
readonly C_RED='\033[0;31m'
readonly C_GREEN='\033[0;32m'
readonly C_YELLOW='\033[0;33m'
readonly C_BLUE='\033[0;34m'
readonly C_END='\033[0m'

# ==============================================================================
# Utility Functions
# ==============================================================================

_print() {
	local level="${1}"
	local message="${2}"

	case "${level}" in
		INFO) printf '%b[INFO]%b %s\n' "${C_BLUE}" "${C_END}" "${message}" ;;
		SUCCESS) printf '%b[SUCCESS]%b %s\n' "${C_GREEN}" "${C_END}" "${message}" ;;
		WARN) printf '%b[WARN]%b %s\n' "${C_YELLOW}" "${C_END}" "${message}" ;;
		ERROR) printf '%b[ERROR]%b %s\n' "${C_RED}" "${C_END}" "${message}" ;;
		*) printf '%s\n' "${message}" ;;
	esac
}

_banner() {
	printf '\n%b%s%b\n' "${C_BLUE}" "$(printf '=%.0s' {1..80})" "${C_END}"
	printf '%b%s%b\n' "${C_BLUE}" "${1}" "${C_END}"
	printf '%b%s%b\n\n' "${C_BLUE}" "$(printf '=%.0s' {1..80})" "${C_END}"
}

_check_deps() {
	local missing=0

	for cmd in curl jq bc; do
		if ! command -v "${cmd}" &> /dev/null; then
			_print ERROR "Missing required command: ${cmd}"
			((missing++))
		fi
	done

	if ((missing > 0)); then
		_print ERROR "Install missing dependencies: apt install curl jq bc"
		exit 1
	fi
}

# ==============================================================================
# Build Function
# ==============================================================================

_build_binary() {
	_banner "Building qBittorrent Binary"

	cd "${SCRIPT_DIR}" || exit 1

	_print INFO "Running build script..."
	if ! bash qbittorrent-nox-static.sh all &> "${SCRIPT_DIR}/build-test.log"; then
		_print ERROR "Build failed - check build-test.log"
		exit 1
	fi

	if [[ ! -f "${SCRIPT_DIR}/qbt-nox-static" ]]; then
		_print ERROR "Binary not found after build"
		exit 1
	fi

	_print SUCCESS "Binary built successfully"

	# Get build info
	local build_date=$(date +%Y%m%d_%H%M%S)
	local git_commit=$(git rev-parse --short HEAD 2>/dev/null || printf 'unknown')
	local git_branch=$(git branch --show-current 2>/dev/null || printf 'unknown')

	printf '%s' "${build_date}_${git_commit}_${git_branch}"
}

# ==============================================================================
# qBittorrent Configuration
# ==============================================================================

_setup_qbt_config() {
	_banner "Setting Up qBittorrent Configuration"

	# Create config directory
	mkdir -p "${QBT_CONFIG_DIR}/qBittorrent/config"
	mkdir -p "${STORAGE_DIR}"

	# Create qBittorrent.conf
	cat > "${QBT_CONFIG_DIR}/qBittorrent/config/qBittorrent.conf" <<-EOF
	[Preferences]
	Downloads\SavePath=${STORAGE_DIR}
	Downloads\TempPath=${STORAGE_DIR}/temp
	WebUI\Port=${QBT_PORT}
	WebUI\Username=admin
	WebUI\Password_PBKDF2=@ByteArray(ARQ77eY1NUZaQsuDHbIMCA==:0WMRkYTUWVT9wVvdDtHAjU9b3b7uB8NR1Gur2hmQCvCDpm39Q+PsJRJPaCU51dEiz+dTzh8qbPsL8WkFljQYFQ==)
	WebUI\LocalHostAuth=false
	Connection\PortRangeMin=6881
	Connection\UPnP=false
	Connection\GlobalDLLimitAlt=0
	Connection\GlobalUPLimitAlt=0
	Bittorrent\MaxConnections=-1
	Bittorrent\MaxConnectionsPerTorrent=-1
	Bittorrent\MaxUploads=-1
	Bittorrent\MaxUploadsPerTorrent=-1
	Bittorrent\DHT=true
	Bittorrent\PeX=true
	Bittorrent\LSD=true
	EOF

	_print SUCCESS "Configuration created at ${QBT_CONFIG_DIR}"
	_print INFO "Storage directory: ${STORAGE_DIR}"
	_print INFO "WebUI port: ${QBT_PORT}"
	_print INFO "WebUI credentials: admin / adminadmin"
}

# ==============================================================================
# qBittorrent Control
# ==============================================================================

_start_qbt() {
	_banner "Starting qBittorrent"

	# Kill any existing instance
	pkill -9 qbittorrent-nox 2>/dev/null || true
	sleep 2

	# Start qBittorrent
	"${SCRIPT_DIR}/qbt-nox-static" \
		--profile="${QBT_CONFIG_DIR}" \
		--webui-port="${QBT_PORT}" &> "${SCRIPT_DIR}/qbt-test.log" &

	local qbt_pid=$!
	sleep 5

	# Verify it's running
	if ! ps -p "${qbt_pid}" &> /dev/null; then
		_print ERROR "qBittorrent failed to start - check qbt-test.log"
		exit 1
	fi

	# Wait for Web UI
	local retries=30
	while ((retries > 0)); do
		if curl -s "http://localhost:${QBT_PORT}/api/v2/app/version" &> /dev/null; then
			_print SUCCESS "qBittorrent started (PID: ${qbt_pid})"
			return 0
		fi
		sleep 1
		((retries--))
	done

	_print ERROR "qBittorrent Web UI did not start"
	exit 1
}

_stop_qbt() {
	_print INFO "Stopping qBittorrent..."
	pkill -15 qbittorrent-nox 2>/dev/null || true
	sleep 2
	pkill -9 qbittorrent-nox 2>/dev/null || true
}

# ==============================================================================
# Torrent Testing
# ==============================================================================

_add_torrents() {
	_banner "Adding Torrents from ${TEST_TORRENTS_DIR}"

	if [[ ! -d ${TEST_TORRENTS_DIR} ]]; then
		_print WARN "Test torrents directory not found: ${TEST_TORRENTS_DIR}"
		_print INFO "Creating directory and example instructions..."
		mkdir -p "${TEST_TORRENTS_DIR}"
		cat > "${TEST_TORRENTS_DIR}/README.txt" <<-EOF
		Place your .torrent files here for testing.

		The test will:
		1. Add all .torrent files from this directory
		2. Measure download/upload speeds
		3. Log results to performance-results.csv
		4. Clean up downloaded files

		For best results, use torrents with:
		- Active seeders (public torrents work well)
		- Varied sizes (small to large)
		- Different tracker types
		EOF
		_print ERROR "No torrents found. Add .torrent files to ${TEST_TORRENTS_DIR}"
		exit 1
	fi

	local torrent_count=$(find "${TEST_TORRENTS_DIR}" -name "*.torrent" | wc -l)

	if ((torrent_count == 0)); then
		_print ERROR "No .torrent files found in ${TEST_TORRENTS_DIR}"
		exit 1
	fi

	_print INFO "Found ${torrent_count} torrent(s)"

	# Login to Web UI
	local cookie=$(curl -s -i --header "Referer: http://localhost:${QBT_PORT}" \
		--data "username=admin&password=adminadmin" \
		"http://localhost:${QBT_PORT}/api/v2/auth/login" | \
		grep -i '^set-cookie:' | sed 's/^set-cookie: //i' | cut -d';' -f1)

	if [[ -z ${cookie} ]]; then
		_print ERROR "Failed to login to Web UI"
		exit 1
	fi

	# Add torrents
	local added=0
	for torrent in "${TEST_TORRENTS_DIR}"/*.torrent; do
		[[ -f ${torrent} ]] || continue

		_print INFO "Adding: $(basename "${torrent}")"

		if curl -s --cookie "${cookie}" \
			-F "torrents=@${torrent}" \
			-F "savepath=${STORAGE_DIR}" \
			-F "category=performance-test" \
			"http://localhost:${QBT_PORT}/api/v2/torrents/add" | grep -q "Ok"; then
			((added++))
		else
			_print WARN "Failed to add: $(basename "${torrent}")"
		fi
	done

	_print SUCCESS "Added ${added} torrent(s)"

	# Wait for torrents to start
	sleep 5
}

_measure_performance() {
	local build_id="${1}"
	local start_time=$(date +%s)
	local end_time=$((start_time + TEST_DURATION))

	_banner "Measuring Performance (${TEST_DURATION}s)"

	_print INFO "Build ID: ${build_id}"
	_print INFO "Test duration: ${TEST_DURATION} seconds"
	_print INFO "Sampling every 5 seconds..."

	# Initialize CSV if it doesn't exist
	if [[ ! -f ${RESULTS_CSV} ]]; then
		printf 'timestamp,build_id,elapsed_sec,dl_speed_mbps,up_speed_mbps,num_torrents,num_active,num_downloading,num_seeding,num_peers,num_seeds\n' > "${RESULTS_CSV}"
	fi

	local sample_count=0
	local total_dl=0
	local total_up=0

	while (($(date +%s) < end_time)); do
		local now=$(date +%s)
		local elapsed=$((now - start_time))

		# Get torrent stats from API
		local stats=$(curl -s "http://localhost:${QBT_PORT}/api/v2/torrents/info")

		if [[ -z ${stats} ]]; then
			_print WARN "Failed to get stats from API"
			sleep 5
			continue
		fi

		# Parse JSON stats
		local dl_speed=$(printf '%s' "${stats}" | jq '[.[] | .dlspeed] | add // 0')
		local up_speed=$(printf '%s' "${stats}" | jq '[.[] | .upspeed] | add // 0')
		local num_torrents=$(printf '%s' "${stats}" | jq 'length')
		local num_downloading=$(printf '%s' "${stats}" | jq '[.[] | select(.state == "downloading")] | length')
		local num_seeding=$(printf '%s' "${stats}" | jq '[.[] | select(.state == "seeding" or .state == "uploading")] | length')
		local num_active=$(printf '%s' "${stats}" | jq '[.[] | select(.state != "pausedDL" and .state != "pausedUP")] | length')
		local num_peers=$(printf '%s' "${stats}" | jq '[.[] | .num_leechs] | add // 0')
		local num_seeds=$(printf '%s' "${stats}" | jq '[.[] | .num_seeds] | add // 0')

		# Convert to Mbps
		local dl_mbps=$(printf 'scale=2; %s / 1024 / 1024 * 8\n' "${dl_speed}" | bc -l)
		local up_mbps=$(printf 'scale=2; %s / 1024 / 1024 * 8\n' "${up_speed}" | bc -l)

		# Log to CSV
		printf '%s,%s,%d,%.2f,%.2f,%d,%d,%d,%d,%d,%d\n' \
			"$(date -Iseconds)" "${build_id}" "${elapsed}" \
			"${dl_mbps}" "${up_mbps}" \
			"${num_torrents}" "${num_active}" "${num_downloading}" "${num_seeding}" \
			"${num_peers}" "${num_seeds}" >> "${RESULTS_CSV}"

		# Accumulate for average
		total_dl=$(printf '%.2f' "$(printf '%s + %s\n' "${total_dl}" "${dl_mbps}" | bc -l)")
		total_up=$(printf '%.2f' "$(printf '%s + %s\n' "${total_up}" "${up_mbps}" | bc -l)")
		((sample_count++))

		# Display progress
		printf '\r%b[%03d/%03d]%b DL: %6.2f Mbps  UP: %6.2f Mbps  Peers: %4d  Seeds: %4d' \
			"${C_BLUE}" "${elapsed}" "${TEST_DURATION}" "${C_END}" \
			"${dl_mbps}" "${up_mbps}" "${num_peers}" "${num_seeds}"

		sleep 5
	done

	printf '\n'

	# Calculate averages
	local avg_dl=$(printf 'scale=2; %s / %s\n' "${total_dl}" "${sample_count}" | bc -l)
	local avg_up=$(printf 'scale=2; %s / %s\n' "${total_up}" "${sample_count}" | bc -l)

	_print SUCCESS "Test complete!"
	_print INFO "Average download speed: ${avg_dl} Mbps"
	_print INFO "Average upload speed: ${avg_up} Mbps"
	_print INFO "Results logged to: ${RESULTS_CSV}"
}

# ==============================================================================
# Cleanup
# ==============================================================================

_cleanup() {
	_banner "Cleaning Up"

	# Stop qBittorrent
	_stop_qbt

	# Delete downloaded files
	if [[ -d ${STORAGE_DIR} ]]; then
		_print INFO "Deleting downloaded files from ${STORAGE_DIR}..."
		rm -rf "${STORAGE_DIR:?}"/*
		_print SUCCESS "Downloaded files deleted"
	fi

	# Clean config directory
	if [[ -d ${QBT_CONFIG_DIR} ]]; then
		_print INFO "Cleaning qBittorrent config..."
		rm -rf "${QBT_CONFIG_DIR}"
		_print SUCCESS "Config cleaned"
	fi
}

# ==============================================================================
# Main
# ==============================================================================

main() {
	_banner "qBittorrent Simple Performance Test"

	_check_deps

	local skip_build=0
	local skip_cleanup=0

	# Parse arguments
	while [[ $# -gt 0 ]]; do
		case "${1}" in
			--skip-build)
				skip_build=1
				shift
				;;
			--skip-cleanup)
				skip_cleanup=1
				shift
				;;
			--help)
				cat <<-EOF
				Usage: $0 [OPTIONS]

				Options:
				  --skip-build     Skip building, use existing binary
				  --skip-cleanup   Don't delete files after test
				  --help           Show this help

				This script:
				1. Builds the latest qBittorrent binary
				2. Starts qBittorrent with storage at /mnt/storage
				3. Adds torrents from test_torrents/ directory
				4. Measures download/upload speeds for 5 minutes
				5. Logs results to performance-results.csv with build ID
				6. Deletes downloaded files

				Requirements:
				- Place .torrent files in test_torrents/ directory
				- Ensure /mnt/storage exists or will be created
				- Install dependencies: apt install curl jq bc
				EOF
				exit 0
				;;
			*)
				_print ERROR "Unknown option: ${1}"
				_print INFO "Use --help for usage information"
				exit 1
				;;
		esac
	done

	# Build binary
	if ((skip_build == 0)); then
		build_id=$(_build_binary)
	else
		_print WARN "Skipping build (using existing binary)"
		local git_commit=$(git rev-parse --short HEAD 2>/dev/null || printf 'unknown')
		local git_branch=$(git branch --show-current 2>/dev/null || printf 'unknown')
		build_id="existing_${git_commit}_${git_branch}"
	fi

	# Setup and run test
	_setup_qbt_config
	_start_qbt
	_add_torrents
	_measure_performance "${build_id}"

	# Cleanup
	if ((skip_cleanup == 0)); then
		_cleanup
	else
		_print WARN "Skipping cleanup (--skip-cleanup specified)"
		_stop_qbt
	fi

	_banner "Test Complete"
	_print SUCCESS "Results saved to: ${RESULTS_CSV}"
	_print INFO "View results: cat ${RESULTS_CSV}"
}

# Trap errors and cleanup
trap '_stop_qbt' EXIT INT TERM

main "$@"
