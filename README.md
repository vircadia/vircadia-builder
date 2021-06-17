# Project Vircadia builder
Builds Vircadia (codename "Project Athena"), an Open Source fork of the High Fidelity codebase.

## Supported platforms

* Amazon Linux 2 (see notes below)
* CentOS 8.x (see notes below)
* Debian 10 (codename Buster)
    * Linux Mint Debian Edition 4
* Fedora 31
* Fedora 32
* Fedora 33
* Ubuntu 18.04.x (codename Bionic, has pre-built Qt)
    * Linux Mint 19.x
* Ubuntu 20.04.x (codename Focal)
    * Linux Mint 20.x
* OpenSuSE Tumbleweed
* (more coming soon)

## Notes on Ubuntu 18.04

The Node.js in Ubuntu's official repositories is severely outdated. This can lead to problems building target jsdoc.

To update Node.js, manually add the 16.x repository as shown [here](https://github.com/nodesource/distributions)
```bash
    curl -fsSL https://deb.nodesource.com/setup_16.x | sudo -E bash -
    sudo apt-get install -y nodejs
```

## Notes on CentOS / RHEL 8.x builds

Before starting the build

- Enable PowerTools and EPEL repos
  dnf install epel-release
  dnf config-manager --set-enabled PowerTools

- Make sure basic dev tools are installed
  dnf groupinstall "Development Tools" "RPM Development Tools"

- CentOS/RHEL has two Python version, make sure Python 2 is default
  dnf install python2 python36
  alternatives --set python /usr/bin/python2

## Notes on Amazon Linux 2

Amazon Linux is a very trimmed-down distribution that lacks some packages that are present in other distributions. Unfortunately it even lacks Perl by default, which means `vircadia-builder` can't run on a default installation.

To deal with this issue, run the `install_amazon_linux_deps.sh` script before running `vircadia-builder`.

## Unsupported platforms

* Ubuntu 16.04

While the dependency lists remain in the code, functionality is not guaranteed with the current Vircadia code due to the distribution being too old to build the required software successfully without extra work.

Given my lack of time, fixes are unlikely to happen, though contributed patches will be accepted if they're not too intrusive.

* Manjaro

Broken completely broken by Manjaro updates shortly after implementation.

## Instructions:

You can see the possible environment variables for building [here](https://docs.vircadia.dev/developer/build/BUILD_GENERAL.html#generating-build-files).

    git clone https://github.com/vircadia/vircadia-builder.git
    cd vircadia-builder
    chmod +x vircadia-builder
    ./vircadia-builder

## What it does

* Installs all required packages
* Downloads the Vircadia source from github
* Downloads and compiles Qt if required
* Compiles the Vircadia source
* Creates a wrapper script to make it run correctly
* Creates a desktop icon
* Adds it to the menu

It will ask some questions, all of which can be left with their default values.

It will detect the system's core count and amount of available memory, and do a parallel build taking care not to exhaust the system memory on high core count systems.

## Build targets

The script by default builds the GUI ('interface') but it can also build the server components using the --build option. For instance:

    $ ./vircadia-builder --build server

Will build only the server components. To build both, separate entries with a comma:

    $ ./vircadia-builder --build server,client

Have in mind that each build overwrites the previous one, so if you want to have both desktop and server components at the same time, you need to build them both in one command like above.

## Building AppImages

You can create an AppImage using the `--make-appimage` argument.

When making an AppImage, you will want to create it on the oldest possible distribution in order to achieve the greatest compatibility. You will want to also ensure that your distribution is fully up to date. For example, on Ubuntu you will want to run `sudo apt-get update && sudo apt-get upgrade` prior to building.

## Qt

The Vircadia codebase uses a specific, patched version of Qt. Binary packages are only available for some platforms. For platforms without a package, Qt can be built from source by the script.

**WARNING: The Qt build uses a large amount of RAM, which can be a problem with VPSes. A minimum of 4 GB RAM + 2GB swap is recommended for building Qt with one process**. The swap usage should be tolerable, as Qt has a few very memory intensive parts in the compilation process, but the rest is much less so.

In case of trouble, look at the autodetected number of cores, eg:

    Checking how many cores to use for building Vircadia... 4 cores, memory limited to 2
    Checking how many cores to use for building Qt... 4 cores, memory limited to 3

And manually specify a lower number. For instance:

    ./vircadia-builder --qt-cores 1


In any case, building in low resource environments is slow and problematic. While it can be done, it might be faster and easier to do the build in Docker or a bigger VM running on a local machine, and then copy the files over.

## Adding support for more distributions

The script is intended to be as automatic as possible, and to set it all up for the user. For that to work, it depends on including a list of dependencies inside the script itself, but it can work without that as well. Here's how:

First, get a list of the supported distributions, and find the closest one:


    $ ./vircadia-builder --get-supported
    ubuntu-19.10
    linuxmint-19.3
    custom
    fedora-31
    ubuntu-16.04
    ubuntu-18.04

Tell the script to dump the list of dependencies for that distro:

    $ ./vircadia-builder --get-source-deps ubuntu-18.04
	...
	$ ./vircadia-builder --get-qt-deps ubuntu-18.04
	...

Use those results as a starting point. Choosing a similar distribution (eg, 18.04 when running on 18.10) should mostly work, and only a few package names might need fixing. With the package list figured out, install them:

    $ sudo apt-get install ...

After installing the packages, you can try the script by selecting the special distro name "custom", which will perform a build without any hardcoded dependency checking:

    $ ./vircadia-builder --distro custom

After that, the build process should begin. If there are problems, it's likely more packages need to be installed.

Once you know what packages are needed, a new configuration can be created. Configurations are stored in the `distros` subdirectory. Copy the one you used as a base, and make your modifications. The syntax for the file is that of a Perl script.

Once modifications are done, you can use the `maint` script to clean it up:

    $ ./maint --cleanup distros/new-distro.cfg

This will verify that your config file parses correctly, will apply a standard indentation and order the contents. This makes it easier to see what changed between different releases of a distribution, and makes for better patches.

## Questions

####  How much disk space does it need?

Some packages will likely need to be installed, depending on the distro and the current instalation. On a Fedora 31 VPS without a desktop, this required 130 MiB of packages.

In addition to any packages that may be needed to do the build:

* About 20 GiB for a full build including Qt.
* About 10 GiB if the binary Qt package is used.
* About 8.2 GiB after deleting downloaded source files.

#### How long does it take?

It's extremely variable, depending greatly on hardware. Here are some sample numbers, only of the compilation process:

| Processor                           | Qt           | CMake | Vircadia Client  | Vircadia Server |
| ------------                        | ------------ | ----- | ------------   | ----------    |
| Ryzen 9 3950X, using 32 cores       | 19:01        | ?     | 4:07           | ?             |
| Ryzen 9 3950X, using 16 cores in VM | 25:32        | ?     | 4:46           | ?             |
| Core i7-8550U (Dell XPS 13 laptop)  | 2:20:22      | ?     | 19:37          | ?             |
| Linode 8GB                          | 3:09:40      | 14:25 | 31:47          | 16:30         |


#### Why is it using such a weird number of cores for the build?

The script measures available (not total) RAM, and estimates a requirement of 1 GiB needed per build process. So if you have 8 GiB RAM free, you'll get a maximum of 8 cores used for the build.

The script is intended to be friendly and not kill the user's machine through memory exhaustion, so it's intentionally very conservative. You can specify a higher numer if you wish.

## Contact

For questions and support, contact Dale Glass#8576 on Discord.
