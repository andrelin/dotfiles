if is_macos; then
	export JAVA_17_HOME=~/Library/Java/JavaVirtualMachines/azul-17.0.4.1/Contents/Home
fi

# Ubuntu-only stuff. Abort if not Ubuntu.
is_ubuntu || return 1

function jc8() {
	export JAVA_HOME="/usr/lib/jvm/zulu8"
	sudo update-java-alternatives --set zulu8-ca-amd64
}

function jc11() {
	export JAVA_HOME="/usr/lib/jvm/zulu11"
	sudo update-java-alternatives --set zulu11-ca-amd64
}

function jc17() {
	export JAVA_HOME="/usr/lib/jvm/zulu17"
	sudo update-java-alternatives --set zulu17-ca-amd64
}

export JAVA_HOME="/usr/lib/jvm/zulu17"
export M2_HOME=/opt/maven
export MAVEN_HOME=/opt/maven
export PATH=${M2_HOME}/bin:${PATH}
