# On macOS the Homebrew keg root only carries bin/ symlinks, so tools that validate
# JAVA_HOME against a real JDK layout (IntelliJ's Gradle JVM) reject it even though
# java runs fine. The nested Contents/Home is the actual JDK home; Linux has none.
_java_home_for_prefix() {
	if [[ -d "$1/libexec/openjdk.jdk/Contents/Home" ]]; then
		echo "$1/libexec/openjdk.jdk/Contents/Home"
	else
		echo "$1"
	fi
}

# Prints the major version of plain openjdk, Homebrew's latest release: 26 from Cellar/openjdk/26.0.1, or 27 from
# 27_1 after a Homebrew revision. An older Cellar directory can linger after an upgrade, so only the last counts.
_jdk_plain_major() {
	local brew="${HOMEBREW_PREFIX:-/usr/local}" dir version=
	[[ -n "$ZSH_VERSION" ]] && setopt localoptions nullglob
	[[ -d "$brew/opt/openjdk" ]] || return
	for dir in "$brew"/Cellar/openjdk/*; do version="${dir##*/}"; done
	version="${version%%[._]*}"
	[[ "$version" =~ ^[0-9]+$ ]] && echo "$version"
}

# Prints the Homebrew prefix of the installed JDK with major version $1, without spawning brew. Homebrew names a
# superseded release openjdk@N, but the latest release is plain openjdk.
# /usr/local covers Intel macOS, where 02_path.sh leaves HOMEBREW_PREFIX unset.
_jdk_prefix() {
	local brew="${HOMEBREW_PREFIX:-/usr/local}"
	[[ -n "$1" ]] || return
	if [[ -d "$brew/opt/openjdk@$1" ]]; then
		echo "$brew/opt/openjdk@$1"
	elif [[ "$(_jdk_plain_major)" == "$1" ]]; then
		echo "$brew/opt/openjdk"
	fi
}

# Prints the installed JDK major versions, one per line, in no particular order.
_jdk_installed() {
	local brew="${HOMEBREW_PREFIX:-/usr/local}" dir
	[[ -n "$ZSH_VERSION" ]] && setopt localoptions nullglob
	# bash has no nullglob here: an unmatched pattern stays literal, so check each entry exists.
	for dir in "$brew"/opt/openjdk@*; do [[ -d "$dir" ]] && echo "${dir##*@}"; done
	_jdk_plain_major
}

# Prints the newest installed LTS major version. Java has had an LTS every fourth release since 17 (a two-year
# cadence), so it is computed rather than kept in a list that must be edited when the next one ships.
_jdk_newest_lts() {
	local major newest=0
	for major in $(_jdk_installed); do
		# Arithmetic evaluates a non-number as an expression, so never let anything else reach it.
		[[ "$major" =~ ^[0-9]+$ ]] || continue
		(( major >= 17 && (major - 17) % 4 == 0 && major > newest )) && newest=$major
	done
	(( newest )) && echo "$newest"
}

# Switch JDK version using Homebrew paths (all platforms).
# Usage: jdk 21, jdk 25; plain `jdk` shows the active JDK and the installed versions.
jdk() {
	local prefix
	if [[ -z "$1" ]]; then
		echo "JAVA_HOME: ${JAVA_HOME:-unset}"
		echo "Installed: $(_jdk_installed | sort -n | tr '\n' ' ')"
		return
	fi
	prefix="$(_jdk_prefix "$1")"
	if [[ -n "$prefix" ]]; then
		JAVA_HOME="$(_java_home_for_prefix "$prefix")"
		export JAVA_HOME
		export PATH="$JAVA_HOME/bin:$PATH"
		java -version
	else
		echo "JDK $1 not found. Install with: brew install openjdk@$1 (or plain openjdk for the latest release)"
	fi
}

# Default JAVA_HOME: the newest installed LTS, matching the rule in init/31_homebrew_recipes.sh.
_jdk_default="$(_jdk_prefix "$(_jdk_newest_lts)")"
if [[ -n "$_jdk_default" ]]; then
	JAVA_HOME="$(_java_home_for_prefix "$_jdk_default")"
	export JAVA_HOME
	export PATH="$JAVA_HOME/bin:$PATH"
fi
unset _jdk_default

if is_macos; then
	# Set up/update Homebrew OpenJDK symlinks so /usr/libexec/java_home can find them.
	# Run this after installing or upgrading Java versions via Homebrew.
	java_setup() {
		local brew_prefix jvm_dir jdk name link
		brew_prefix="$(brew --prefix)"
		jvm_dir="/Library/Java/JavaVirtualMachines"

		for jdk in "${brew_prefix}"/opt/openjdk*/libexec/openjdk.jdk; do
			[[ -d "$jdk" ]] || continue
			name="$(basename "$(dirname "$(dirname "$jdk")")")"
			link="${jvm_dir}/${name/@/-}.jdk"
			if [[ ! -L "$link" ]] || [[ "$(readlink "$link")" != "$jdk" ]]; then
				echo "Linking: $link -> $jdk"
				sudo ln -sfn "$jdk" "$link"
			else
				echo "OK: $link"
			fi
		done
		echo
		/usr/libexec/java_home -V 2>&1
	}

	# Check for missing/stale symlinks on shell startup. Runs in the shell itself with string operations and -ef,
	# since a subshell plus basename/dirname/readlink per JDK cost 30-70 ms.
	_java_check_links() {
		local jdk name link
		[[ -n "$ZSH_VERSION" ]] && setopt localoptions nullglob
		for jdk in "${HOMEBREW_PREFIX:-/usr/local}"/opt/openjdk*/libexec/openjdk.jdk; do
			[[ -d "$jdk" ]] || continue
			name="${jdk%/libexec/openjdk.jdk}"
			name="${name##*/}"
			link="/Library/Java/JavaVirtualMachines/${name/@/-}.jdk"
			if [[ ! -L "$link" || ! "$link" -ef "$jdk" ]]; then
				echo "Java symlinks need updating. Run 'java_setup' to fix."
				return
			fi
		done
	}
	_java_check_links
	unset -f _java_check_links
fi
