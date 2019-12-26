# Project Athena builder
Builds Project Athena, an Open Source fork of the High Fidelity codebase.

## Supported platforms

* Ubuntu 18.04
(more coming soon)

## Instructions:

    git clone https://github.com/daleglass/athena-builder.git
    cd athena-builder
	chmod +x athena_builder
    ./athena_builder

## What it does

* Installs all required packages
* Downloads the source from github
* Compiles it
* Creates a wrapper script to make it run correctly
* Creates a desktop icon

It will ask some questions, all of which can be left with their default values.

It will detect the system's core count and amount of available memory, and do a parallel build taking care not to exhaust the system memory on high core count systems.

## Contact

For questions and support, contact Dale Glass#8576 on Discord.
