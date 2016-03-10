#!/bin/bash
source charms.reactive.sh
set -ex

# Update java-related system configuration and relation data. This function
# must only be called from a 'java.connected' state handler.
#
# :param: The major java version (e.g.: 6)
function update_java_data() {
    local java_major=$1
    local java_alternative=$(update-java-alternatives -l | grep java-1.${java_major} | awk {'print $1'})

    # Set our java symlinks to the alternative that matched our major version.
    update-java-alternatives -s ${java_alternative}

    # Remove any previous mention of JAVA_HOME from /etc/environment.
    sed -i -e '/JAVA_HOME/d' /etc/environment

    # Update environment and relation if we have a /usr/bin/java symlink
    if [[ -L "/usr/bin/java" ]]; then
        local java_home=$(readlink -f /usr/bin/java | sed "s:/bin/java::")
        local java_version=$(java -version 2>&1 | grep -i version | head -1 | awk -F '"' {'print $2'})
        echo "JAVA_HOME=${java_home}" >> /etc/environment
        relation_call --state=java.connected set_ready $java_home $java_version
    fi
}

@when 'java.connected'
@when_not 'java.installed'
function install() {
    local install_type=$(config-get 'install-type')
    local java_major=$(config-get 'java-major')

    # Install jre or jdk+jre depending on config.
    status-set maintenance "Installing OpenJDK ${java_major} (${install_type})"
    apt-get update -q
    if [[ ${install_type} == "full" ]]; then
      apt-get install -qqy openjdk-${java_major}-jre-headless openjdk-${java_major}-jdk
    else
      apt-get install -qqy openjdk-${java_major}-jre-headless
    fi

    # Register current java information
    update_java_data $java_major
    set_state 'java.installed'
    status-set active "OpenJDK ${java_major} (${install_type}) installed"
}

@when 'java.connected' 'java.installed'
@when 'config.changed.java-major'
function change_major() {
    # Different major java version requested by config, call install.
    # NOTE: no need to check for an install-type change when java-major changes.
    # The install function will use the current config value whether it
    # changed since initial install or not.
    install
}

@when 'java.connected' 'java.installed'
@when 'config.changed.install-type'
@when_not 'config.changed.java-major'
function change_type() {
    # Different install-type (but same java-major) requested by config.
    # Update packages accordingly.
    # NOTE: if install-type AND java-major change, that is handled with a
    # reinstall in the above change_major function.
    local install_type=$(config-get 'install-type')
    local java_major=$(config-get 'java-major')

    if [[ ${install_type} == 'jre' ]]; then
      # Config tells us we only want the JRE. Remove the JDK if it exists.
      if dpkg -s openjdk-${java_major}-jdk &> /dev/null; then
        status-set maintenance "Uninstalling OpenJDK ${java_major} (JDK)"
        apt-get remove --purge -qqy openjdk-${java_major}-jdk
      fi
    elif [[ ${install_type} == 'full' ]]; then
      # Config tells us we want a full install. Install the JDK unconditionally
      # (it doesn't hurt to install a package that is already installed).
      # NOTE: this will update existing jdk packages to the latest rev of the
      # major release.
      status-set maintenance "Installing OpenJDK ${java_major} (${install_type})"
      apt-get install -qqy openjdk-${java_major}-jdk
    fi

    # Register current java information
    update_java_data $java_major
    status-set active "OpenJDK ${java_major} (${install_type}) installed"
}

@when 'java.installed'
@when_not 'java.connected'
function uninstall() {
    # Uninstall all versions of OpenJDK
    status-set maintenance "Uninstalling OpenJDK (all versions)"
    apt-get remove --purge -qqy openjdk-[0-9]?-j.*

    remove_state 'java.installed'
    status-set blocked "OpenJDK (all versions) uninstalled"
}

reactive_handler_main
