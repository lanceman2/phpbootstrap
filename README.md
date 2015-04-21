phpbootstrap - compiling PHP with PHP
=====================================

Nuts but true.  Why not make PHP and HTML files with PHP as a
pre-processor before server requests?  Make your web content as static as
possible.  Why have PHP generate the same page every time?  Why not run
PHP at serve time, only when you need to.  It's PHP caching in a very
simple way.


## Ports

GNU/Linux.  We are currently developing phpbootstrap on debian GNU/Linux.
We are not interested in MS windows, hence we have `/` hard coded in local
paths.


## Brief Description

phpbootstrap is a small web content build system that makes PHP based HTTP
server web content files like a standard software package build process
that is running the following:

>  `configure`  
>  `make`  
>  `make install`

and run

>  `configure --help`

to get configure options.

It sets up GNU make files and make dependences for the HTTP server files
so that files are only regenerated when depending files change.  So if you
have a HTML file that is built from 10 PHP files, this will only rebuild
it if one or more of the files that it depends on changes.

By adding a "build" steps into the initial web server content development
we pre-compose web pages in as much as possible before serving the pages,
which makes installed/generated files that are served.  We are making the
web service package like a regular software package.  Having a
non-interactive installation process tends to make the web service package
a more managable software package.  If you've spend a lot of time
developing compiled software packages like say the firefox web browser, or
the apache HTTP web server, this should be obvious.  Forcing users of
software to interactively install software is not friendly.  Think about
it, it takes away user freedom.  Software packages should be able to be
non-interactively built and installed.  A web service is a software package.

With a build system, like phpbootstrap, web services may be more easily
installed on a source based system like gentoo.   i.e. you could make an
ebuild from the source of the package.  It would make OpenStack so easy to
do, that it would be pointless.  It's fucking obvious.  Having to edit
shit.conf.php and than interact with a browser to install software is
total bullshit.  It's a software development mindset that somehow never
got into the heads of web service software developers.  Granted you can
write script workarounds that make a would-be interactive install process
be non-interactive; we don't see these scripts being distributed with the
software.  phpbootstrap may be very difficult to retrofit into an
existing web service.  Retrofitting is just not in the current development
scope of phpbootstrap.  phpbootstrap is using very simple and restrictive
file name rules, in order to keep things as simple as possible, where-by
making the build system configuration flexibility a secondary concern.
phpbootstrap is a very simple build system for web service software.

phpbootstrap is a ruby script, that installs in a single self contained
file, which may remind you of WAF, The meta build system.  phpbootstrap is
a small software package and is not expected be a script that is longer
than say, 5,000 lines of: ruby, bash, PHP, GNU make, HTML5, javaScript,
and CSS code.  It's about 2,000 lines now as we write this, and it works
to a limited extent now as we write this.


## What is the Name phpbootstrap

The name phpbootscrap implies that we use PHP to bootstrap the generation
of web served files.  bootstrap is the name given to the script that is
run before configure in a standard GNU autotools software package.
Running bootscript generates the configure script.  In our case we run
phpbootstrap to generate a configure script.  [autogen.sh is totally
stupid; see https://www.sourceware.org/autobook/autobook/autobook_43.html]


## Web File Types

Basic web served file types are PHP, HTML5, javaScript, CSS 2.2, and ASCII
text.  This build system uses files suffixes, a crazy amount of them.
That keeps custom package configuration code down, at the cost of using
these stupid file suffixes.  Consequently, existing packages will be very
hard to retrofit to use phpbootstrap.

It makes two compilers by script wrapping PHP, YUI, and cat.  The running
of these compilers is driven purely by file suffixes, using GNU make
files, with auto-generated depend files.


## What About a Data Base Server

If you build your service on a data base server, phpbootstrap way not be
what you want.  Who are we kidding, phpbootstrap will never be used by
anyone but phpbootstrap developers.


## See examples/

See examples in the `examples/` directory.  Just run `make` in the `examples/`
directory.  These examples are used as a test of phpbootstrap.
If `make` fails, you likely need some prerequisite software installed.
Get it from your GNU/Linux package manager `yum`, `apt-get`, or whatever.


## License

phpbootstrap - a PHP web build system  
Copyright (c) 2015  Lance Arsenault

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU Affero General Public License as
published by the Free Software Foundation, either version 3 of the
License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public
License along with this program.  If not, see
http://www.gnu.org/licenses/.

