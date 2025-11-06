# Test Torrents Directory

Place your `.torrent` files here for performance testing.

## Usage

1. **Add torrent files:**
   ```bash
   cp /path/to/*.torrent test_torrents/
   ```

2. **Run the performance test:**
   ```bash
   ./qbt-simple-test.bash
   ```

3. **View results:**
   ```bash
   cat performance-results.csv
   ```

## What the Test Does

The test script will:

1. ✅ Build the latest qBittorrent binary
2. ✅ Start qBittorrent with storage at `/mnt/storage`
3. ✅ Add all `.torrent` files from this directory
4. ✅ Measure download/upload speeds for 5 minutes
5. ✅ Log results to `performance-results.csv` with build ID
6. ✅ Delete downloaded files after test

## Torrent Selection Tips

For best performance testing results, use torrents that have:

- **Active seeders** - Public torrents from popular trackers work well
- **Varied sizes** - Mix of small (100MB), medium (1GB), and large (10GB+)
- **Different trackers** - Test tracker announce performance
- **Legal content** - Ubuntu ISOs, Linux distros, open source software

## Example: Getting Test Torrents

```bash
# Ubuntu releases (legal, well-seeded)
cd test_torrents/

# Ubuntu 24.04 Desktop
curl -O https://releases.ubuntu.com/24.04/ubuntu-24.04-desktop-amd64.iso.torrent

# Ubuntu 22.04 Server
curl -O https://releases.ubuntu.com/22.04/ubuntu-22.04-live-server-amd64.iso.torrent

# Debian
curl -O https://cdimage.debian.org/debian-cd/current/amd64/bt-dvd/debian-12.4.0-amd64-DVD-1.iso.torrent
```

## Results Format

The `performance-results.csv` contains:

| Column | Description |
|--------|-------------|
| `timestamp` | When the measurement was taken |
| `build_id` | Git commit + branch identifier |
| `elapsed_sec` | Seconds since test start |
| `dl_speed_mbps` | Download speed in Mbps |
| `up_speed_mbps` | Upload speed in Mbps |
| `num_torrents` | Total torrents added |
| `num_active` | Actively transferring torrents |
| `num_downloading` | Torrents downloading |
| `num_seeding` | Torrents seeding |
| `num_peers` | Connected peers (leechers) |
| `num_seeds` | Connected seeders |

## Advanced Options

```bash
# Skip building (use existing binary)
./qbt-simple-test.bash --skip-build

# Keep downloaded files (don't cleanup)
./qbt-simple-test.bash --skip-cleanup

# Show help
./qbt-simple-test.bash --help
```

## Comparing Builds

To compare performance between builds:

1. **Test baseline:**
   ```bash
   git checkout baseline-branch
   ./qbt-simple-test.bash
   ```

2. **Test optimized:**
   ```bash
   git checkout optimized-branch
   ./qbt-simple-test.bash
   ```

3. **Compare results:**
   ```bash
   # View all test runs
   cat performance-results.csv | column -t -s,

   # Compare average speeds by build
   awk -F',' 'NR>1 {builds[$2]+=$4; counts[$2]++}
              END {for(b in builds) printf "%s: %.2f Mbps avg\n", b, builds[b]/counts[b]}' \
              performance-results.csv
   ```

## Troubleshooting

**No torrents found:**
- Ensure `.torrent` files are in this directory
- Check file extensions are `.torrent` (not `.torrent.txt`)

**Low speeds:**
- Torrents may have few seeders (try popular Ubuntu/Debian ISOs)
- Network firewall may be blocking connections
- Test during peak hours for more seeders

**Download fails to start:**
- Some torrents may be dead (no seeders)
- Try adding more torrents
- Check qBittorrent logs in `qbt-test.log`

## Git Ignore

This directory is tracked in git, but `.torrent` files are ignored (see `.gitignore`).
Only `README.md` and `.gitkeep` are committed.
