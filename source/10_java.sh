# Switch JDK version using Homebrew paths (all platforms).
# Usage: jdk 17, jdk 21, jdk 25
jdk() {
	local prefix
	prefix="$(brew --prefix "openjdk@$1" 2>/dev/null)"
	if [[ -d "$prefix" ]]; then
		export JAVA_HOME="$prefix"
		export PATH="$JAVA_HOME/bin:$PATH"
		java -version
	else
		echo "openjdk@$1 not found. Install with: brew install openjdk@$1"
	fi
}

# Set default JAVA_HOME to the latest installed OpenJDK.
if [[ -d "$(brew --prefix openjdk 2>/dev/null)" ]]; then
	JAVA_HOME="$(brew --prefix openjdk)"
	export JAVA_HOME
	export PATH="$JAVA_HOME/bin:$PATH"
fi

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

	# Check for missing/stale symlinks on shell startup (avoids calling brew)
	(
		if [[ -d /opt/homebrew ]]; then
			_bp="/opt/homebrew"
		else
			_bp="/usr/local"
		fi
		_jvm="/Library/Java/JavaVirtualMachines"

		for _jdk in "${_bp}"/opt/openjdk*/libexec/openjdk.jdk; do
			[[ -d "$_jdk" ]] || continue
			_name="$(basename "$(dirname "$(dirname "$_jdk")")")"
			_link="${_jvm}/${_name/@/-}.jdk"
			if [[ ! -L "$_link" ]] || [[ "$(readlink "$_link")" != "$_jdk" ]]; then
				echo "Java symlinks need updating. Run 'java_setup' to fix."
				break
			fi
		done
	)
fi
