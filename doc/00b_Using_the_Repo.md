Using the Repo
==============

This document details mechanisms for read and write access to the main
tinyos development repository.

If you have problems or questions please feel free to contact me,
Eric (cire831@gmail.com).  I'll be glad to help.

Notation
--------

  * We reference a fictional developer throughout this document, Robert Hunter,
    whose initials are rh.

  * Github has a notion of context and repositories are owned by that context.
    Contexts maybe a github owner or maybe a github organization which can
    associate owners and contributors and associate them to a repository.  This
    allows one to build teams of contributors who have various access rights
    to a repository.

    gh:<context>/<repo> is used to refer to a repository hosted on
    github.com.

    local: refers to your local working repository.

  * Branch names are presented in parentheses.
    ie: "gh:tinyos/tinyos-main(master)" is the master branch in the
    tinyos/tinyos-main.git repository (on github.com).

    "local(master)" refers to the master branch in your local
    working repository.

    Note: local(master) and gh:tinyos/tinyos-main(master) are not
    necessarily the same set of git objects.   If the local repository has
    diverged (or if gh:tinyos/tinyos-main has diverged) then these objects
    will most certainly not be the same.

  * Remote branch names.

    Remote branches take the form "remotes/<remote>/<branch_name>".   A local
    git repository can be configured to refer to remote git repositories using
    the "git remote add" command.  When data is fetched from that repository
    the branches references will be prepended with the "remotes/<remote>"
    prefix.

    Remote branches when unique may be referenced using any of the following
    forms:

        remotes/<remote>/<branch_name>  full specification.

        <remote>/<branch_name>

        <branch_name>           needs to be unique


Where do you do your work?
--------------------------

We are using Github to coordinate and host our main repositories.  GitHub
is the publishing vehicle so we can see each others work as well as the
main development repository.

Each contributor has access to the following:

* **gh:tinyos/tinyos-main**     main development repository.
* **gh:tinyos/tinyos-release**  main release repository.

* **gh:<github_user>/tinyos-main** developer fork of tinyos-main.  Used to host
    published developer branches.  Refered to as the
    published developer repo.

* **local**         local developer repository.  Located on the
    development system.  Where the actual work
    gets done.  Refered to as Developer Local or
    just "local".

    pushes and pulls to gh:<github_user>/tinyos-main


Common Branch Names
-------------------

   There are several persistent branches in the tinyos-main and tinyos-release
   repos.   Also persistent branches will be created for ongoing integration
   efforts for various features or efforts.

* Development Repository: (gh:tinyos/tinyos-main)

   **master**:      The main development branch tip.

   **integration**:     If multiple features need to be merged into a single
            whole this is where that happens.

   **<feature>-int**:   main integration branch for a feature.  ie.
            gh:tinyos/tinyos-main(msp430-int) is the
            integration branch for the new msp430 core
            being brought into tinyos.


* Release Repository: (gh:tinyos/tinyos-release)

   The release repository will always have a default branch that points to
   the current release point for TinyOS.

   As the release point is moved forward, previous release branches will
   be converted to appropriately named tags.

   **tinyos-2_1_2**:    initial release of TinyOS 2.1.2

   **tinyos-2_1_2_1**:  1st maint release.   etc.

   **tos-maint-next**:  branch holding proposed commits for the next maint
            release.



* Local repository:

    A typical structure.

    The above branches will show up in the local repository based off the
    referenced remotes.

    Typically there will be an origin remote ("origin") for the developer's
    repo from github, and an upstream remote ("up") for the source repo that
    the developer forked, (gh:tinyos/tinyos-main).  The upstream tracks
    changes as they become integrated and allows the developer to track these
    changes locally.

    For example, we might see the following (assuming the developer Robert
    Hunter):

        bash(30): git remote -v show
        origin  git@github.com:roberthunter/tinyos-main.git
        up      git://github.com/tinyos/tinyos-main.git

        remotes/up/master           current tip of the development main branch

        remotes/origin/rh           private branch on rh's repo.
        remotes/origin/master       rh repo copy of master.


Creating your published and working repositories and associated working branches
--------------------------------------------------------------------------------

  * Log in to your github account

  * Create a working fork.  Working repos are forked off the main development
  repository, gh:tinyos/tinyos-main.   See the url:

    https://github.com/tinyos/tinyos-main

    This will bring up the main page for the tinyos/tinyos-main repo.

    To create a working repo, click on the fork button.   This will create a
    fork of tinyos/tinyos-main in your local context (your login context).

    This will create the repository github.com/<github_username>/tinyos-main
    which is forked off github.com/tinyos/tinyos-main.  All working repos are
    forked off tinyos/tinyos-main repo.

    For our virtual user this will create the repository
    gh:roberthunter/prod

  * Create your local repo.

        mkdir -p w/rh       # create working directory
        cd w/rh
        git clone git@github.com:roberthunter/tinyos-main.git tinyos-2.x
        cd tinyos-2.x

        # you will now have w/rh/tinyos-2.x populated with the default branch
        # of the fork.  Your fork will inherit the default branch from
        # gh:tinyos/tinyos-main repo.  For the main development repo this is
        # "master".  In the future this may be different but for now we will
        # maintain "master" as the tip of the development repository.
        #
        # this will create the remote "origin" and link it to your working fork
        # on github.

        # you will also want to track changes coming into the main development
        # repository, tinyos/tinyos-main.  You do this by creating your upstream
        # remote to use for tracking.

        git remote add up git://github.com/tinyos/tinyos-main
        git fetch up

  * Create your working branch.  For Robert Hunter we use his initials
    as the working branch name.  This will be published as
    gh:roberthunter/tinyos-main(rh) if this branch is pushed (published)
    to Robert Hunter's working repository (on github).

        git branch              # make sure on the appropriate branch
                        # should show master which is the
                        # current default branch.
        git checkout -t up/master       # create a tracking branch.
        git checkout -b rh          # create the working branch off the
                        # current branch (master)

        <make changes>

        git add -u              # add changed files that are tracked.
        git commit              # commit.  editor will get invoked
                        # for the commit message.

        # please see Guidelines in 00a_Getting_Started for a guide on how to write
        # good commit messages.   It really is important to write decent commit
        # messages.

        # when you are ready to publish your changes, push the changes back to
        # your working fork on github.

        git push origin rh


Workflow:  (simulated github user: Robert Hunter)
-------------------------------------------------

typically, local work is done on the working branch, ie.
(local)tinyos-main(rh).

It is possible for changes to occur on the upstream, ie.
gh:tinyos/tinyos-main(master) and these changes must be
reflected in the current state of the rh branch.

The easiest way to do this is to locally rebase the rh
branch on to the current state of master.

* Local changes to rh:

        (on the branch rh)
        <make changes>
        git add -u
        git commit

        <make changes>
        git add -u
        git commit

* Update rh onto current upstream master:

        git fetch up            # get current state of upstream
        git checkout master         # switch to corresponding branch
        git pull up             # and merge in current state
                                # should be a fast forward.

        git rebase master rh        # rebase rh onto the upstream master
                                    # switches back to the rh branch

    NOTE: that the branch rh (even though it is published as
    gh:roberthunter/tinyos-main(rh)) is by convention considered
    a private branch.  It can be freely rebased and other developers shouldn't
    branch off it.  It is considered private so the developer can
    rebase it freely to the upstream.

    Another reason for using rebase is it keeps your work (your commits)
    grouped together in the history.   This makes it easier to see what you
    are doing and how you got there.


* Publish current results:   (still on rh branch, publish rh state)

        git push origin +rh         # -> gh:roberthunter/tinyos-main(rh)


    WARNING: The use of +rh forces an override when pushing your result
    to your github working repository.  This is because rebasing rewrites
    the history and the push to the repository isn't a simple fast forward.
    For the developer branch this is fine because it is considered private.

    Be very careful when using the '+' syntax.  Only use it on your own
    private repository.  Never use force when pushing to the main
    repositories.


* Looking at differences between working branch and upstream branch

        # To see what changes you have been working on...
        git log --oneline up/master..rh


* Commiting to the trunk

    Currently the most reliable way to get your changes into the trunk
    (tinyos-main(master) is to request a pull from your working branch into the
    the development trunk.

    As above, make sure that rh has been moved to the tip of the upstream
    master.

    publish the result on gh:roberthunter/tinyos-main(rh).

    Robert then requests a pull from his repository's main page.

        https://github.com/roberthunter/tinyos-main/pull/new/master

    Make sure that you request that the pull goes from the rh branch on
    gh:roberthunter/tinyos-main(rh) to the master branch on
    gh:tinyos/tinyos-main(master).

    A Lead Developer (a github user with push rights to the repository) will
    check to make sure there aren't any problems and then authorize the pull
    into the repository.


    After requesting the Pull, Robert Hunter to create a new working branch
    off of master for future work.   You do not want to continue to add
    commits to the rh branch while the pull is outstanding.



* Commiting to the trunk, with push rights.

    If you have push rights to the main repo and you know what you are doing
    you can commit directly to the trunk.

    Note: the local copy of master has been synced to gh:tinyos/tinyos-main(master)
    and the rh branch has been moved to the tip of master.

* add a remote that you can use to push to the main trunk.  Make sure current.

        git remote add tos git@github.com:tinyos/tinyos-main
        git fetch tos

        # note the current local master branch should match remotes/tos/master.
        # you can verify by running:

        git log -1 --decorate master

        you should see something like the following:  (note how master and
        tos/master show up next to the same SHA)

    zot (25): git log -1 --oneline --decorate master
    4449bba (tos/master, master) MDA300 support from Franco Di Persio.

        # at this point your work should be on rh which should be
        # directly off the end of master.  You should be able to fast forward
        # master to the tip of rh.

        git checkout master
        git merge rh
        git push tos master

    Under no circumstances should you perform a non-fast-forward push. See
    https://help.github.com/articles/dealing-with-non-fast-forward-errors
    for information on this.

That's it.
