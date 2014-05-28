
This is the TinyOS main development GIT repository.

It is hosted at https://github.com/tinyos/tinyos-main, main branch master.
(aka gh:tinyos/tinyos-main(master))

============================================================================

** Where to begin: **

README.md (this file).  For a general overview of what this Repo is
  about.  This repository uses GIT as its DVCS.
 
doc/00a_Getting_Started_w_Git: Overview of getting started using git, github.

doc/00b_Using_the_Repo: Using and contributing back to the central Repository.

doc/00c_Setting_Up_Debian_Development: Setting up development on Debian
  based Linux machines.   Debian and Ubuntu.

doc/00d_MacOSX_Development: Setting up development on Mac OS X.

============================================================================

* To get started you need to a) install a development environment and b)
  obtain the TinyOS source code.  TinyOS is intended for small embedded
  systems and is always cross-compiled.  So you always need a cross-compiler
  toolchain.  The TinyOS source code can be obtained from a number of
  different places.   The primary development trunk is located at github.com
  and is called tinyos-main.   The release path is tinyos-release.


* About tinyos-main.

Long ago (well not that long ago), in a galaxy not too distant, tinyos
development was hosted on Google Code as a subversion repository, 
tinyos-main.googlecode.com/svn/trunk.  This repository was only writeable by
a select group of core developers.

TinyOS development has moved to a fully distributed model to encourage more
participation and is switching to the GIT distributed version control system
to support this.

To ease the transition the gh:tinyos/tinyos-main repository will support very
similar access mechanisms as formally used to write to the tinyos-main
subversion repository.  The core group of lead developers has push (write)
permission to the main development repository.


* Repo Structure

Currently there is a single mainline, master.  gh:tinyos/tinyos-main(master).
This is equivalent to the tip of the svn trunk.

Branches are very inexpensive and are encouraged for any significant development.
Typically, a feature will be implemented on a topic branch, ie. <feature>-int.
where <int> stands for integration.

For the immediate future, branching should be done in private user repositories
until the community gets used to how they work.

The general form for a repository/branch reference is: <github_context>/<repo>(branch)
ie. gh:tinyos/tinyos-main(master) is the master branch in the tinyos/tinyos-main 
repository.   Note that github repositories have a specific default branch controlled
by github repository settings.   gh:tinyos/tinyos-main refers to the repository but
if that repository is pulled it will reference the default branch.

Local repositories are referenced using local(branch).
