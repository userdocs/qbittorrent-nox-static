v1.1.0 - 18-03-2023

	Breaking changes: -bv 1.81.0 have been replaced with -bt boost-1.81

	Reason: This check is now very similar to the -lt and -qt switches to it makes sense to bring it inline with how those are used.

	Changes:

	The script has gone through a general refactoring with many code optimizations, simplifications and improvements starting from v1.0.6.

	Features:

	Caching and cache management via -cd

	Tag switches are more versatile in how they select source files based on tag input. Trying to use archives first but automatically falling back to folders when required.

	More env options introduced to make setting most dynamic features available via env settings.

	New switch options added.

v1.0.6 - 07-03-2023

	Lot of tweaks and changes.

	cache files method is now integrated into the script as a result of the URL function changes.

	Refactored URL function. It now uses associative arrays to hold the data for URLs, tags and versions. This makes the data more structured and easier to use consistently throughout the script.

	Changed all instances of echo -e to printf %b

	Added a method to using an existing local git repo as a cached source. It will clone a folder with the matching app name in the cache path provided and clone, if it exists.

	It will respect manually specified tags and checkout those from the clone folders.

	The lowercase naming convention of the applications must be used in the cache_path/folder_name like cache_path/qbittorrent

	It must be a git repo


v1.0.5 - 06-03-2023

	Modified the default behaviour of the Debian installation to not build gawk and bison by default. It will now install them via apt-get.

	There is a new switch -dma which will trigger the alternate mode and instead build gawk and bison from source.

v1.0.4 - 19-01-2023

	Changed: Dropped build support for older Buster-Bionic since they require a more modern gcc version to successfully build natively. Successful builds on a modern OS can be used there instead.

v1.0.3 - 15-07-2022

	Fixed: build - Libtorrent using b2 had checks against supplied tags to do version specific things that failed to match properly when using a pull request tag or non versioned branch. It now always check the version.hpp to determine the version in these build checks.
