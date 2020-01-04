# Project Athena builder
Builds Project Athena, an Open Source fork of the High Fidelity codebase.

## Supported platforms

* Ubuntu 16.04
* Ubuntu 18.04
* Ubuntu 19.10 (experimental)
* Fedora 31 (experimental, needs to build Qt)
(more coming soon)

## Instructions:

    git clone https://github.com/daleglass/athena-builder.git
    cd athena-builder
	chmod +x athena_builder
    ./athena_builder

## What it does

* Installs all required packages
* Downloads the Athena source from github
* Downloads and compiles Qt if required
* Compiles the Athena source
* Creates a wrapper script to make it run correctly
* Creates a desktop icon
* Adds it to the menu

It will ask some questions, all of which can be left with their default values.

It will detect the system's core count and amount of available memory, and do a parallel build taking care not to exhaust the system memory on high core count systems.

## Qt

The Athena codebase uses a specific, patched version of Qt. Binary packages are only available for some platforms. For platforms without a package, Qt can be built from source by the script.

## Questions

####  How much disk space does it need?

In addition to any packages that may be needed to do the build:

* About 20 GiB for a full build including Qt.
* About 10 GiB if the binary Qt package is used.
* About 8.2 GiB after deleting downloaded source files.

#### How long does it take?

It's extremely variable, depending greatly on hardware. Here are some sample numbers, only of the compilation process:

| Processor  | Qt  | Athena   |
| ------------ | ------------ | ------------ |
| Ryzen 9 3950X, using 32 cores  |  19:01  | 4:07   |
| Ryzen 9 3950X, using 16 cores in VM | 25:32 | 4:46  |
| Core i7-8550U (Dell XPS 13 laptop) | 2:20:22 | 19:37 |


#### Why is it using such a weird number of cores for the build?

The script measures available (not total) RAM, and estimates a requirement of 1 GiB needed per build process. So if you have 8 GiB RAM free, you'll get a maximum of 8 cores used for the build.

The script is intended to be friendly and not kill the user's machine through memory exhaustion, so it's intentionally very conservative. You can specify a higher numer if you wish.

## Contact

For questions and support, contact Dale Glass#8576 on Discord.
