# My Motivation and Why This Exists

This is not a technical document, it's a not-so-brief answer to the question
of "why?"

## Why Are We Here?

Well, there are a couple of reasons driving this project, some more technical
than others.  The direct, immediate, and proximate cause is that my main
laptop's hard drive recently failed after a year of light usage.  While that
was disturbing, I found myself staring at a fresh Ubuntu install and
continually running into "command not found" errors.  I could have run
`sudo apt install` and made the problem gone away.  That is, the first problem
would go away.  Things would be fine until the next missing package.

What's worse than trying to run a tool that's not installed is that it happens
right in the middle of when you're trying to do something.  While I will admit
that there have been times when I woke up in the middle of the night, jumped
out of bed, and asked, "Wait!!  Did I remember to install yq on that new
system?!?!"  So, the pattern becomes:

1. mentally focus on doing something
2. try to do something
3. something breaks because a dependency is missing
4. switch focus and context to finding what's missing
5. install what's missing
6. switch focus and context back to doing something
7. go back to step 1
8. seemingly never get to the finish line

If I had one system, this would be less of an issue for me.  If all of my
systems ran the same version of the same distribution of the same operating
system, this would be less of an issue for me.  If durable storage was as
dependable as marketing materials suggest it to me, this would be less of a
problem for me.

## Why Not Xargs

The following would probably work:

```bash

cat packages.manifest | xargs sudo apt install -fy
```

Done and dusted, right?

Well, I wanted something more robust than that.  I saw what folks in other
areas (Python, Node, etc.) have done with dependency management and I wanted
to take a note from them.  I wanted to be able to annotate my list of packages
not just with comments (which I could remove with `sed` and still use `xargs`)
but also empty lines (again, only a `sed` away).

The big thing was being able to specify package versions.  When I build with
Docker, I pin versions to system packages the same way I annotate versions
with Python, Node, etc..  The problem I found with pinning to specific versions
is that I'm *constantly* having to update Dockerfiles every time a patch to
anything comes out.  That sucks.

In the past, I tried to automate around this with Renovate using
[Repology as a datasource](https://docs.renovatebot.com/modules/datasource/repology/)
to automate package version management.  In fact, if their documentation even
uses package management on Alpine Linux as an example.

Tangentially, package version pinning is largely a non-issue with Alpine Linux,
but many Dockerfile tools don't take into that account.

This process -- especially with Alpine -- made build processes less than
repeatable in certain circumstances.  Ultimately, for Alpine, I found it
sufficient to pin to major versions.  Pinning to minor versions seems like it
would be a good idea; unfortunately, that requires developers to stick to the
semantics behind semantic versioning ([SemVer](https://semver.org/)).

So, anyways, since most of my systems are running a Debian-based distribution,
I could use the versioning supported with `apt`, but that becomes more of an
issue when I use other systems whose package managers don't support those
semantics or use a different syntax.

## Why Not Ansible

I know, right?  This is where I went next.  A simple playbook, a basic
inventory, and we're done.  In fact, in the past, this is exactly how I would
manage larger-scale deployments.  Moreover, I had all of the functionality
Ansible brought; I could do more than install packages, I could add users,
modify configuration files, start and stop services, etc..

Well, that's a great plan.  Truly.

I looked at two deployment models:

1. central system runs Ansible in one place and all I do is update the
   inventory to add the new system
2. run Ansible on each system

The centralized approach is nice, but for systems like Chromebooks, it doesn't
fit very well.  The decentralized approach is nice, but it requires me to have
Ansible running on each system.  To get there, Python and some other
dependencies need to be installed at which point we're back to that initial
loading of packages... that bootstrapping, if you will.

# Why so much infrastructure around a single shell script

Well, a couple of reasons:

## Treat This Like Real Engineering

Unit tests, repeatable builds, verifiable processes, organized project
layout, and lots of documentation.

I use this tool and I'm hoping others do, too.  That said, I judge that as
a building of tools others may use, I have a responsibility to model the
behavior I wish to see in the world, to champion good practices, to do
quality work.

If it was a script that did something with low stakes and had a small blast
radius, that would be one thing.  However, managing system packages comes with
a massive potential for bad things happening.  Stuff like this needs to be
done right.

## Documentation-Driven Development

I also wanted to continue to explore Documentation-Driven Development.  That is,
write the documentation first, make the major decisions early, document those
decisions (not just the decisions, but reasoning, the options considered and
rejected, the consequences, etc), and use them to drive the development
process.

Secondarily, the development process should have tests written first, before
the code to satisfy those tests is written.  That is, Test-Driven Development
(TDD).  The general thesis was to see how well an AI / LLM could adhere to
a documentation-first, test second development process.  I wanted to see how
much code was garbage, how much needed to be refactored continually, how much
rework was involved.  I wanted to see how often development steps would clobber
earlier work.
