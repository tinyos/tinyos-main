
****

HI!  Hey, now that I've got your attention.  Current active development is
occurring over at gh:tp-freefall/prod.git.

Now the time has come to transition the tinyprod/tp-freeforall code to the main
tinyos-main tree.  The plan is to archive the current tinyos-main tree as tinyos-old.

SO.  If you are actively using tinyos-main please let me know.  I do not want to
yank things out from underneath you or annoy anyone unnecessarily.

(cire831@gmail.com)

****

TinyOS
======

[TinyOS](http://tinyos.net) is an open source, BSD-licensed operating system
designed for low-power wireless devices, such as those used in sensor networks,
ubiquitous computing, personal area networks, smart buildings, and smart meters.

---

- TinyProd
> The main Tinyos-Main tree has seen less activity over the years.  That doesn't
> mean TinyOS is dead, rather most new work has been concentrated on the ```tinyprod```
> repository.  See [tinyprod/prod](https://github.com/tinyprod/prod)
> and its working development repository [tp-freeforall/prod](https://github.com/tp-freeforall/prod)

- Make 3
> The main TinyOS trees have been converted to using the new *Make3* build system.
> See the *(Make Version 3)* section below.

----

Where to Begin
--------------

- `doc/00a_Getting_Started_w_Git`: Overview of getting started using git, github.

- `doc/00c_Setting_Up_Debian_Development`: Setting up development on Debian
  based Linux machines. Debian and Ubuntu.

- `doc/00d_MacOSX_Development`: Setting up development on Mac OS X.


TinyOS Wiki
-----------

***
Sorry.  The wiki appears to be dead.  Sorry about that but I (we) don't have
write access to the old TinyOS wiki at Stanford and haven't built a new one.
(let me know if you want to put one together, cire831@gmail.com).
***

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

For the immediate future, branching should be done in private user repositories.
until the community gets used to how they work.

The general form for a repository/branch reference is: <github_context>/<repo>(branch)
ie. gh:tinyos/tinyos-main(master) is the master branch in the tinyos/tinyos-main
repository.   Note that github repositories have a specific default branch controlled
by github repository settings.   gh:tinyos/tinyos-main refers to the repository but
if that repository is pulled it will reference the default branch.

Local repositories are referenced using local(branch).


## (Make Version 3)
TinyOS development repositories (tinyos/tinyos-main, tinyprod/prod) use the Version
3 make build system (issue #190).  (see below).

Releases 2.1.2 and prior uses pre-version 3 tools and requires tinyos-tools-14.  The
development tree (tinyos-main, tinyprod) requires the new version 3 compatible tools,
tinyos-tools-devel.

TinyOS releases after 2.1.2 will use tinyos-tools that are compatabile with the version
3 make system.


Version 3 Make system and tinyos-tools
------------------------------------------
The TinyOS make system has been upgraded to version 3. This brings many new
improvements, see `support/make/README.md` for details.

The simplest way to obtain the tools is the install from the main tinyprod
repository (see doc/00c_Setting_Up_Debian_Development).  See the repository
Readme at http://tinyprod.net/repos/debian/README.html).

    sudo -s
    apt update
    apt purge tinyos-tools              # remove earlier incompatible version
    apt install tinyos-tools-devel


Alternatively, one can build the tools manually:

    cd tools
    ./Bootstrap
    ./configure
    make
    sudo make install
