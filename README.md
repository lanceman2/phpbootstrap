phpbootstrap - compiling PHP with PHP
=====================================

Nuts but true.  Why not make PHP and HTML files with PHP as a
pre-processor before server requests?  Make your web content as static as
possible.  Why have PHP generate the same page every time?  Why not run
PHP at serve time, only when you need to.  It's PHP caching in a very
simple way.


## Brief Description

phpbootstrap is a small web content build system that makes PHP based HTTP
server web content files like a standard software package build process
that is running the following:

> ```
> configure
> make
> make install
> ```

and run

> ```
> configure --help
> ```

to get configure options.

It sets up GNU make files and make dependences for the HTTP server files
so that files are only regenerated when files change.  So if you have a
HTML file that is built from 10 PHP files, this will only rebuild it if
one or more of the files that it depends on changes.

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
non-interactively.  A web service is a software package.

This new web service development paradigm does not have to conflict with
say for example the way WordPress is installed.  With a build system web
services could than be more easily be installed on a source based system
like gentoo.  It makes OpenStack easy to do.  It's fucking obvious.
Enough said.

phpbootstrap is a ruby script, that installs as is a single self contained
file.


## What is the Name phpbootstrap

The name phpbootscrap implies that we use PHP to bootstrap the generation
of web served files.  bootstrap is the name given to the script that is
run before configure in a standard GNU autotools software package.
Running bootscript generates the configure script.  In our case we run
phpbootstrap to generate a configure script.


## Web File Types

Basic file types are PHP, HTML5, javaScript, CSS 2.2, and ASCII text.
This build system used files suffixes, crazy ones.  Which keeps custom
package configuration down, at the cost of using file suffixes.  Old
packages will be very hard to retrofit.

It makes two compilers by script wrapping PHP, YUI and cat.  The use of
these compilers is driven purely by file suffixes, using make files.


## See examples/

See examples in the examples directory.


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
    <http://www.gnu.org/licenses/>.

