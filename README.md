# Overview

This is a layered charm that generates a deployable OpenJDK charm. Source for
this charm is available at
[github](https://github.com/juju-solutions/layer-openjdk).

## Usage

This subordinate charm implements the `java` interface and requires a principal
charm that provides the `java` relation endpoint. Example deployment:

    juju deploy ubuntu-devenv
    juju deploy openjdk
    juju add-relation ubuntu-devenv openjdk

## Configuration

### java-type

  This determines which OpenJDK packages to install. Valid options are `jre`
  or `full`. The default is `jre`, which will install the OpenJDK Java Runtime
  Environment (JRE). Setting this to `full` will install the OpenJDK Java
  Development Kit (JDK), which includes the JRE.

  Switch between the JRE and full (JRE+JDK) with the following:

      juju set openjdk java-type=full

### java-major

Major version of Java to install.  This defaults to `8` and installs
openjdk-8-[jre|jdk]. Valid options for Ubuntu releases are:

- 14.04 (Trusty): `6`, `7`, `8`
- 16.04 (Xenial): `8`, `9`
- 18.04 (Bionic): `8`, `11`
- 20.04 (Focal):  `8`, `11`, `13`, `16`, `17`

Switch between Java8 and Java9 with the following:

    juju set openjdk java-major=9

## Contact Information

- <kevin.monroe@canonical.com>
