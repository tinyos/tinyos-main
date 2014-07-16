Getting Started with Git.
=========================

Contents:

- Introduction
- Documentation
- GitHub
- Set up Git
- Set up your working repository
- Further Reading
- Guidelines


Introduction
------------

The tinyos-main (development) repository is hosted on GitHub as part
of the tinyos organizational context.  It can be found at
https://github.com/tinyos/tinyos-main.


You can directly access the repository via:

    git clone git://github.com/tinyos/tinyos-main.git <local dir name>

    (note: if <local dir name> is not specified, it defaults to the name
    of the repository being cloned).

The above will make a complete local copy of the main development repository.
The checked out branch will be the tip of development repository (master).

The above will make a copy of the development trunk.  If instead you want
to work with the latest release use the following:

    git clone git://github.com/tinyos/tinyos-release.git <local dir name>


This will allow one to make use of the code.   That's good.

However, if one makes changes, some of those changes should be published and
commited back to the collective code base.  Potentially back to the main 
development trunk.

GitHub is used to facilitate this publishing and to provide an environment
that promotes interactions between common developers.

In addition to the main development repository published as tinyos/tinyos-main,
github allows controlled forking of repositories into a user's personal
space.  This allows a github user to publish their changes so other community
members review, comment, and make use of these changes.  When appropriate
these changes can then be brought in to the central development repository
(tinyos/tinyos-main).

The mechanism that makes all this work is git and its core concept of SHAs
that reflect the objects that are being managed by the DVCS.

Contributing back to the TinyOS effort can be streamlined by joining the 
github community (since that is where the main tinyos repositories are hosted).


Documentation
-------------

We use GIT as the SCM.  Here are some pointers to get you started:

   Start here:   http://book.git-scm.com/2_setup_and_initialization.html
   Everyday GIT: http://www.kernel.org/pub/software/scm/git/docs/everyday.html
   Cheat Sheet:  http://zrusin.blogspot.com/2007/09/git-cheat-sheet.html
   SVN to GIT:   http://git-scm.com/course/svn.html
   GIT Book:     http://book.git-scm.com/
   Another Book: http://progit.org/book/


Documentation on getting started with T2 can be found at:

    http://docs.tinyos.net
    http://docs.tinyos.net/index.php/Getting_started



Using GitHub
------------

* Go to github.com and get yourself a logon.  Choose your login name
  carefully.   You can rename it once (but only once).
  
  Once you are logged in, You'll be presented a start up page which
  includes things like "Set Up Git", "Create a Repository", "Fork a
  Repository", etc.

  We use existing repositories.

* Do make use of the help files, help.github.com.  (ie. Set Up Git)

* See doc/00b_Using_the_Repo for examples of access and contributing
  to github repositories.


Set Up Git.
-----------

This section details items that only need to be done once.
For more information on using git, github, and contributing to the
project please see doc/00b_Using_the_Repo.

* set up SSH keys.  If you have an existing SSH key you can use it.
   Existing keys can typically be found in ~/.ssh.   The instructions have
   you backup and remove and then regenerating a new ssh key.  You don't
   need to do that but can use your existing key if you wish.  For
   example: you could use ~/.ssh/id_rsa.pub as your key.

* Set your username and email

        $ git config --global user.name "Firsname Lastname"
        $ git config --global user.email "your_email@youremail.com"

* Set your GitHub token.

   Follow the instructions on the github help page (Set Up Git).


* Other things to put into your git config.   (global for the user,
  which lives at ~/.gitconfig)

  *  To avoid problems with DOS EOL sequences, we always store in the
    repository using UNIX EOL sequences.   Set autocrlf to input to
    avoid these problems.

        $ git config --global core.autocrlf input

  * It is handy to set up local copies of remote branches automatically.

        $ git config --global branch.autosetupmerge true

  * And set default pushing behaviour to only push the current branch,
    (the most common activity).

        $ git config --global push.default current

  * Aliases are nice for common commands.

        $ git config --global alias.b branch
        $ git config --global alias.ci commit

    will define two aliases, b for branch and ci for commit.  You can do
    things like:

        $ git b                   # display current branch
        $ git ci                  # same as git commit


An example ~/.gitconfig looks like:  (Its mine with the github token
redacted)...

	[user]
		name = Eric B. Decker
		email = cire831@gmail.com
	[core]
		editor = emacsclient
		autocrlf = input
	[alias]
		b  = branch
		br = branch
		c  = config
		ci = commit
		co = checkout
		cp = cherry-pick
		d  = diff
		lp = log -p
		r  = remote
		rem= remote
		st = status
		s  = status
		wc = whatchanged
	[branch]
		autosetupmerge = true
	[pack]
		threads = 0
	[push]
		default = current
	[github]
		user = cire831

* Set up your working repository

  See `00b_Using_the_Repo` for the structure of the repositories and their
  relationships and how to interact with the various branches and
  repositories.

  Typically, contributors work in a local repo linked to a working github
  repo that is forked from tinyos/tinyos-main.  This keeps a fair amount
  of independence between different developers.


* Other tools

  Learn to use gitk.  GitK is your friend.  It will give you a graphical
  representation of your repo, the branches, and the commits and how they
  are related to each other.

        gitk --all

  Will show you all branches in the repository.


* Further Reading

  * GitHub Help
    (http://help.github.com)

    GitHub has lots of help.

  * Main Git Site, Documentation
    (http://git-scm.com/documentation)

  * Git Reference
    (http://gitref.org)

  * Git from the bottom up.
    (http://ftp.newartisans.com/pub/git.from.bottom.up.pdf)

    Is an easy to understand description of how git works from the bottom up.

  * Pro Git is a book about git that is very good.
    (http://progit.org)

  * Distributed Git
    (http://progit.org/book/ch5-0.html)

    This chapter talks about using Git as part of a distributed workflow.


Repo Guidelines
---------------

* Commit guidelines.

  * First and foremost make commits logical units.

    Logically seperate changesets.   Don't code for weeks and then bring the
    whole piece in as one commit.

    Make a commit something that can be looked at and digested reasonably.
    Solves one problem.

    Keep the history clean and understandable.


  * Use meaningful commit messages.

    the first line (50 chars or less) is used as the short message.   This
    message is displayed in one line logs and other places.  Make it
    meaningful and concise if possible.

    Follow the first line by a blank line then a more detailed message which
    should provide more detailed information about what the commit does.  The
    GIT project itself requires motivation as well as contrasting the new
    behaviour to old behaviour.  Why was this change necessary?  Its not a
    bad habit to get into when it makes sense to do so.

  * Use the imperative present tense when writing commit messages.

  * Always include a blank line after the short message (the first line).

  * Always run `git diff --check` to make sure you aren't introducing trailing
    whitespace.  Some tools bitch about this and it is really annoying.


* Copyright.

  The main TinyOS code is copyrighted by individual authors using the 3 clause
  Modified BSD license.   The simplest thing to do is either use no copyright
  or use the BSD license.

  We are trying to get any new code to use the same boilerplate license.   The
  intent is to minimize any extraneous noise when generating diffs.   The
  boilerplate is written so the only part that needs to be modified as new
  authors are added is the actually Copyright (c) <year> <name> clause at
  the front.

  A template for this copyright can be found in `licenses/bsd.txt`.


* Coding style.  These are suggestions.  There isn't a style nazi.

  * First, don't change the style to just change the style.

  * Follow the coding standard conventions documented in TEP3. A copy can be
    found in `doc/txt/tep3.txt`.

  * When working in a section of code, try to adapt to the existing style.

  * When possible, use a compact style.

  * Indent:2

            if ( a == b) {
              c = d;
            }

  * Braces: same line  (see above), closing brace by itself.

  * single provides/uses: same line, multiple blocked.


            module xyz {
              provides interface NameInterface as NI;
              uses     interface AnotherInterface as AI;
            }

            module abc {
              provides {
                interface NameInterface as NI;
                interface AnotherInterface as AI;
              }
              uses {
                interface Inter1;
                interface Inter2;
              }
              implementation {
                ...
              }
            }


  * if then else

            if ( a == b)
              <then clause>
            else
              <else clause>

            if ( a == b) {
               block statements
            } else {
               block statements
            }


