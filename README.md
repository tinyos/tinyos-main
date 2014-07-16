
TinyOS
======

**Warning**: The main development tree (tinyos/tinyos-main) has been converted
over to the new version 3 make system (issue #190 has been merged).   (see below).

[TinyOS](http://tinyos.net) is an open source, BSD-licensed operating system
designed for low-power wireless devices, such as those used in sensor networks,
ubiquitous computing, personal area networks, smart buildings, and smart meters.
A worldwide community from academia and industry use, develop, and support the
operating system as well as its associated tools, averaging 35,000 downloads a
year.


============================================================================

**Note**: New Make system and tinyos-tools
------------------------------------------

The TinyOS make system has been upgraded to version 3. This brings many new
improvements (see `support/make/README.md` for details) but also requires
the `tools` to be rebuilt. To use TinyOS make version 3:

    cd tools
    ./Bootstrap
    ./configure
    make
    sudo make install

alternatively you can use the tinyos-tools-devel package from tinyprod.net/
repos/debian.   See the Readme at the top level (http://tinyprod.net/repos/debian).
You need to modify /etc/apt/sources.list.d/tinyprod-debian.list.  Change "squeeze"
to "wheezy".

    sudo -s
    apt-get update
    apt-get purge tinyos-tools
    apt-get install tinyos-tools-devel


============================================================================



Where to Begin
--------------
 
- `doc/00a_Getting_Started_w_Git`: Overview of getting started using git, github.

- `doc/00c_Setting_Up_Debian_Development`: Setting up development on Debian
  based Linux machines. Debian and Ubuntu.

- `doc/00d_MacOSX_Development`: Setting up development on Mac OS X.


TinyOS Wiki
-----------

Much information about how to setup and use TinyOS can be found on the
[wiki](http://tinyos.stanford.edu/tinyos-wiki/index.php/Main_Page).
It is also editable by the community if you have information to add or update.



About tinyos-main
-----------------

Long ago (well not that long ago), in a galaxy not too distant, tinyos
development was hosted on Google Code as a
[subversion repository](http://tinyos-main.googlecode.com/svn/trunk).
This repository was writeable by a select group of core developers.

TinyOS development has moved to a fully distributed model to encourage more
participation by switching to the git distributed version control system.

The Github tinyos-main repository will still be writeable by those same core
developers. Pull requests are welcome and will be reviewed by the core
developer most familiar with the relevant code.





Repo Structure
--------------

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
