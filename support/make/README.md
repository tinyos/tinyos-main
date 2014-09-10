TinyOS Make System Version 3
============================

Building a TinyOS application consists of running `make` followed by a target
and a series of optional extras. For example, to compile Blink, a very basic
app, for the `telosb` platform you simply run:

    $ cd ../../apps/Blink
    $ make telosb

Compiling an application requires `nesc` to be installed, as well as the correct
toolchain for the hardware you are compiling for.

Targets tell the Make system which hardware platform you are intending to build
the application for. Extras allow you to further configure how an application is
built or run additional commands after compilation is complete. One example is
loading the executable onto the hardware itself. This typically looks like:

    $ make telosb install

To get a list of all valid targets and extras, run `make` in any application
directory.

The remainder of this README explains in depth how the TinyOS make system works,
how to configure it, how to add a new target, platform, or extra, how to setup
an external TinyOS tree and how to adapt TinyOS make system version 2 files
to the current make system.

Unlike prior versions of the TinyOS Make system, version 3 does not require
configuring any environment variables: it automatically finds directories
and files based on your current location. If you need to configure where
the compilation toolchain looks for source files, see "External TinyOS
Trees" below.


Updated Make System (Summer 2014)
---------------------------------

The new version of the make system started out as a method to remove the
environment variable requirement from the TinyOS install. All parts of the build
system that relied on having those environment variables set now use reasonable
defaults. It has since expanded to include getting rid of `ncc` which hides what
commands are actually being run. It also consolidates all of the files and code
relevant to building apps to the /support/make folder (with the exception of the
application specific Makefile).


Major Changes from Version 2
----------------------------

There are several main changes from version two:

  - **Removed `ncc`.** Having a [poorly named] script between tinyos and nesc
    was a useful way to bridge the two initially, but I think it at this point
    it is quite unnecessary and confusing. First, it does magic things (like add
    include directories) and provides useless error messages. Second, `make` is
    a reasonably competent tool that can take over a lot of the burden. By
    removing `ncc` the make system calls `nescc` directly (which is more
    intuitive) and forces TinyOS to be slightly more explicit about what it is
    doing. Following similar logic, I also removed `mic` and `ncg` and now call
    `nescc-mig` directly.

  - **Moved platform/family/sensor files to /support/make.** These perl scripts
    are really just build instructions that are conflated with source code when
    there is a separate directory where all of the rest of the make information
    is housed. Therefore, I moved all of the content that was in the
    platform/family/sensor files to `/support/make` so that all the build
    information is co-located. These files are now parsed by `make` so they can
    include any make syntax.

  - **Changed the function of %T**. Instead of simply expanding to `$TOSDIR`, %T
    is now actually useful. It expands to all TinyOS /tos directories that are
    specified in TINYOS_ROOT_DIR_ADDITIONAL (followed by TINYOS_ROOT_DIR) where
    the expansion references a folder that exists. This makes out-of-tree builds
    and multiple TinyOS trees first class citizens. My goal was to allow a new
    platform to be developed in a separate tree and require no code changes to
    be merged into tinyos-main, and this new %T makes that possible.

  - **Tried to separate "platforms" from "targets".** Targets should be a
    complete hardware system one wants to compile software for. Platforms are the
    base hardware and the microcontroller. This way a target can logically include
    multiple sensorboards and a platform. For instance, the target "micaz" is just
    the base board, but the theoretical target "supermicaz" also compiles the code
    for the sensorboard that is attached to it.

  - **Simplified and moved all of the primary make targets to Makerules.** All
    the .rules files were just copies of each other, so I consolidated the
    targets into Makerules and turned the .rules files into setup config
    Makefiles. This makes them shorter and easier to read. I was worried that
    there would be too much platform specific variation to make this clean and
    simple, but it turned out that all of the platforms were doing mostly the
    same things. I think I balanced brevity and flexibility well.

  - **Added dependencies to the make targets.** Instead of relying on targets
    to be executed in order, targets now specify which targets they depend on.
    This is much more make-y. I didn't go so far as to make the .nc files
    dependencies, however.

  - **General cleanup.** I got the sense that the make system evolved over time,
    and I took this opportunity to make the files more consistent across
    platforms and targets.

  - **Colored output.** I added colored tags to the stdout to make the output
    easier to read.





Directory Structure and Naming Conventions
------------------------------------------

| Folder           | Description                                                                                                             |
|------------------|-------------------------------------------------------------------------------------------------------------------------|
| **extras**       | Contains build targets that can contain extra variables or options                                                      |
| **families**     | Contains .family files that include options for specific families of sensorboards                                       |
| **platforms**    | Contains what used to be .platform files. Contains include paths and other information for building specific platforms. |
| **sensorboards** | Contains files that describe sensor modules that attach to platforms                                                    |
| **targets**      | Contains main build targets. These describe which platform, family, sensorboard, or microcontroller to use.             |
| **[others]**     | Contains build information and extras for specific microcontrollers.                                                    |

The general flow of building a TinyOS application for a specific piece of
hardware starts with the target. Users run

    make <target>

in the application directory. This loads the corresponding .target file from the
make/targets/ folder. The .target file then specifies which platform from the
make/platforms/ folder to use (these correspond to the platforms in
tos/platforms). The .target file also specifies which "make platform" to use,
basically which microcontroller to compile for. Beyond this, targets can
specify which family or sensorboard the application should be compiled for.

There's also a make/Makerules file. Do not edit make/Makerules. No new build
features should ever be exposed via make/Makerules, but rather though the
.rules, .target, and .extra files. make/Makerules is the frontend that defines
the structure and behavior on those special file extensions.

The make/Makedefaults file specifies many logical defaults for different TinyOS
parameters.



External TinyOS Trees
----------------------------------------------------------------------------

A major feature of version 3 is full support for TinyOS trees that are not
in tinyos-main. By setting the environment variable `TINYOS_ROOT_DIR_ADDITIONAL`
the make system will search that tree for files, targets, platforms, etc. Add
the following to something like `.bashrc`:

  TINYOS_ROOT_DIR_ADDITIONAL = /path/to/tinyos-other:$TINYOS_ROOT_DIR_ADDITIONAL

The major change from `TOSMAKE_PATH` is that the external tree can pretend
like it is the main tree. No hacks are needed and if the code is later
merged into tinyos-main it shouldn't have to change at all.

The build will search paths in each of the directories specified in order.
The final path searched will be specified by TINYOS_ROOT_DIR.

In order to compile apps in the external tree there must be a `Makefile.include`
file in the root of the TinyOS tree. A generic example looks like:

```makefile
TINYOS_ROOT_DIR?=/opt/tinyos-main
include $(TINYOS_ROOT_DIR)/Makefile.include
```

If TinyOS is not located in `/opt`, you must set the `TINYOS_ROOT_DIR`
environment variable.

Make System Variables
---------------------

This section outlines the key variables in the make system that new platforms
or `.extra` files might need.

### Environment Variables

Here is a table of all of the user facing Make system variables that can
be configured with environment variables. All variables have a default that
will automatically be set by the build system (mostly in `Makefile.include`)
which effectively removes setting environment variables from the TinyOS install.
If needed, these defaults can be overridden with user set environment variables.

| Old Variable          | New Variable Name               | Default Value                    | Purpose                                                             |
|-----------------------|---------------------------------|----------------------------------|---------------------------------------------------------------------|
| `TOSROOT`             | `TINYOS_ROOT_DIR`               | relative to application Makefile | Base for all other variable defaults                                |
| `TOSDIR`              | `TINYOS_OS_DIR`                 | `$TINYOS_ROOT_DIR/tos`           | Path to `/tos` folder containing main system source to compile with |
| `TINYOS_MAKE_PATH`    | `TINYOS_MAKE_DIR`               | `$TINYOS_ROOT_DIR/support/make`  | Path to `/make` that contains the targets, extras, and rules        |
| `MAKERULES`           | `TINYOS_MAKERULES`              | `$TINYOS_MAKE_DIR/Makerules`     | Path to main makefile                                               |
| `TINYOS_MAKELOCAL`    | `TINYOS_MAKELOCAL`              | `$TINYOS_MAKE_DIR/Makelocal`     | Path to optional Makelocal file                                     |
| `TINYOS_MAKEDEFAULTS` | `TINYOS_MAKEDEFAULTS`           | `$TINYOS_MAKE_DIR/Makedefaults`  | Path to Makedefaults                                                |
| `TOSMAKE_PATH`        | `TINYOS_ROOT_DIR_ADDITIONAL`    | unset                            | Colon separated paths of additional TinyOS trees                    |
| n/a                   | `TINYOS_NO_DEPRECATION_WARNING` | unset                            | Hide warnings about deprecated environment variables                |



### Internal Make System Variables

`make/Makerules` contains most of the logic that makes the build system work.
All of the chip and platform specific files configure how Makerules works
by defining specific variables. In version 2, much of the logic was in each
.rules file, but for the most part these were just duplicates of each other
with very little changed. Version 2 merges the common parts into Makerules.

The following are general variables the can be set anywhere.

| Variable                 | Description                                                                     |
|--------------------------|---------------------------------------------------------------------------------|
| `BUILD_DEPS`             | The starting list of make targets that will be executed.                        |
| `TOSMAKE_PRE_EXE_DEPS`   | All make targets that should be finished before running NesC.                   |
| `TOSMAKE_POST_EXE_DEPS`  | All make targets that should happen after the application is compiled.          |
| `TOSMAKE_DO_REINSTALL`   | Set to true to avoid the compilation step.                                      |
| `TOSMAKE_NO_COLOR`       | Set to true to remove color from being printed to stdout.                       |
| `TOSMAKE_FIRST_FLAGS`    | Flags that are passed to nescc before any other flags.                          |


### Variables for `.rules` Files

Each `.rules` file needs to specify a few thing such that Makerules knows how to
build the application for a given microcontroller. More can be specified if
need be, but the following is approximately the minimum. The easiest way to
write a `.rules` file is to use an existing one as a guide.

| Variable                | Description                                                                     |
|-------------------------|---------------------------------------------------------------------------------|
| `GCC`                   | The compiler.                                                                   |
| `OBJCOPY`               | GCC tools.                                                                      |
| `OBJDUMP`               | GCC tools. - for interspersed listing                                           |
| `SIZE`                  | GCC tools. - for object size display                                            |
| `NM`                    | GCC tools. - for symbol table                                                   |
| `LIBS`                  | Flags for libraries that need to be compiled in. (Example: -lm)                 |
| `TOSMAKE_BINARY_FORMAT` | Either `ihex`, `srec`, or `bin`. The format that will get loaded onto the chip. |
| `TOSMAKE_BINARY_IN`     | The name of binary file that is created by the compiler.                        |
| `TOSMAKE_BINARY_OUT`    | The name of the binary after TOS_NODE_ID has been set.                          |
| `PFLAGS`                | General flags for the compiler.                                                 |
|-------------------------|---------------------------------------------------------------------------------|



### Variables for `.platform` Files

`.platform` files (which used to be in the /tos/platforms/ directories) are no
longer written in Perl and are just Makefiles. Here any platform specific
variables can be set. Typically, these just hold `PFLAGS` setting include paths.

These are very similar to `.sensor` and `.family` files.

| Variable                         | Description                                                            |
|----------------------------------|------------------------------------------------------------------------|
| `PFLAGS`                         | General flags for the compiler.                                        |
| `TOSMAKE_FLASH_CHIP`             | The part number of the flash chip on board.                            |
| `TOSMAKE_VOLUME_ALLOCATOR_FLAGS` | Arguments to the tos-storage script.                                   |



### Variables for `.target` Files

`.target` files glue together different makefiles for the particular hardware
assembly the application is being compiled for.

| Variable                       | Description                                                              |
|--------------------------------|--------------------------------------------------------------------------|
| `TARGET`                       | The name of the particular target.                                       |

Beyond variables, there are a series of functions that `.target` files need
to call in order to include the correct makefiles for that target.

| Function                        | Description                                                              |
|---------------------------------|--------------------------------------------------------------------------|
| `TOSMake_include_platform`      | Call to include the correct `.platform` file.                            |
| `TOSMake_include_sensor`        | Includes the correct sensorboard file.                                   |
| `TOSMake_include_family`        | Includes the correct `.family` file.                                     |
| `TOSMake_include_make_platform` | Includes the correct `.rules` file.                                      |



Converting From Version 2 to Version 3
--------------------------------------

There are a few steps to migrate a platform that compiled with the old make
system to the new version.

### Converting Application Makefiles

There are some small changes that must be made to the Makefile in each
application to support the new make system.

First, is how the greater build system is included from each application.
Instead of:

```makefile
include $(MAKERULES)
```

it must be:

```makefile
TINYOS_ROOT_DIR?=../..
include $(TINYOS_ROOT_DIR)/Makefile.include
```

Keep in mind that `TINYOS_ROOT_DIR?=../..` must be set correctly if the depth
of the application is different from `apps/<app dir>`.

Additionally, all references to the old environment variables (mentioned above)
need to be changed to the new versions (i.e. `TINYOS_OS_DIR` instead of
`TOSDIR`).

### Converting the `.platform` File.

In the old system `.platform` files were used in `tos/platforms/<platform>`
folders to describe the search path of NesC for .nc files relevant to that
particular platform. Putting `.platform` files there had the odd property of
putting build information in where the code is, and away from the `make` folder
that one would expect to find it in. To remedy this, `.platform` files have
moved to `support/make/platforms` and are named `<platform>.platform`.

The main conversion that is needed is that instead of adding the directory
paths to Perl arrays they need to be added directly as arguments to `PFLAGS`.
So:

```perl
push( @includes, qw(
  %T/platforms/epic
  %T/platforms/epic/chips/at45db
  ...
));

@opts = qw(
  -gcc=msp430-gcc
  -mmcu=msp430f1611
  -fnesc-target=msp430
  -fnesc-no-debug
);
```

becomes:

```makefile
PFLAGS += -I%T/platforms/epic
PFLAGS += -I%T/platforms/epic/chips/at45db
...

PFLAGS += -mmcu=msp430f1611
PFLAGS += -fnesc-target=msp430
PFLAGS += -fnesc-no-debug
```

Other things like `-fnesc-scheduler`, etc. are taken care of elsewhere in the
Make system.


### Converting `.target` Files

Target files have not changed extensively, however, there are three key changes.

1. They are now located in `support/make/targets`.
2. The variable `PLATFORM` is now `TARGET` and should not be set conditionally
(this is the only logical place that would define `TARGET`).
3. The function name for include the microcontroller `.rules` file has changed.
Instead of using `TOSMake_include_platform`, `TOSMake_include_make_platform`
must be used to include `.rules` files. `TOSMake_include_platform` now includes
`.platform` files (as the `PLATFORM` variable no longer exists).

For example:

```makefile
PLATFORM ?= epic

# Include the epic-specific targets
$(call TOSMake_include_platform,epic)
# Include the msp extra targets
$(call TOSMake_include_platform,msp)

epic: $(BUILD_DEPS)
    @:
```

becomes:

```makefile
TARGET = epic

# Include the epic.platform file that adds the relevant include paths
$(call TOSMake_include_platform,epic)

# Include the epic-specific targets
$(call TOSMake_include_make_platform,epic)
# Include the msp extra targets
$(call TOSMake_include_make_platform,msp)

epic: $(BUILD_DEPS)
    @:
```


### Converting `.rules` Files

These have changed extensively. Most of the `.rules` files were mostly
duplicated code, and the common infrastructure has moved to `Makerules`.
Therefore, in the simple case `.rules` files just have to set the compiler and which
binary format to use. The simplest `.rules` files look something like:

```makefile
# Set the compiler and libraries
GCC     = msp430-gcc
OBJCOPY = msp430-objcopy
OBJDUMP = msp430-objdump
SIZE    = msp430-size
NM      = msp430-nm
LIBS    = -lm

# Set some compiler/microcontroller specific pflags
PFLAGS += -Wall -Wshadow

# Define the filename for the output file after the node id has been updated
INSTALL_IHEX = $(MAIN_IHEX).out$(if $(NODEID),-$(NODEID),)

# Define which binary format should be built
TOSMAKE_BINARY_FORMAT = ihex
TOSMAKE_BINARY_IN     = $(MAIN_IHEX)
TOSMAKE_BINARY_OUT    = $(INSTALL_IHEX)
```

Other features are not easy to describe in a general way. Check the existing
`.rules` files for examples of other checks or settings you may need.


### Converting `.extra` Files

The other make system files do not necessarily have to change much. If some
internal variables were used the names may have to change. The changes to
`.extra` files in tinyos-main from version 2 to 3 were primarily adding more
strict usage of Make target dependencies so that things get built in the correct
order.


History
-------

### Version 1

Original version with apps/Makerules

### Version 2

Created on 7 Jan 2004.

Rewritten version by Cory Sharp. Basically, new features can be added without
getting in the way of existing make platforms and rules.

### Version 3

Rewritten version by Brad Campbell. Consolidates make system to `support/make`
directory.

