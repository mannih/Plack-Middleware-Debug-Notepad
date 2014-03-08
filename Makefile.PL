#!/usr/bin/env perl
use inc::Module::Install 1.01;

name 'Plack-Middleware-Debug-Notepad';

all_from 'lib/Plack/Middleware/Debug/Notepad.pm';

repository 'http://github.com/mannih/Plack-Middleware-Debug-Notepad.git';

requires 'Plack';
requires 'Text::Markdown';
requires 'Text::MicroTemplate';
test_requires 'Test::Most';
test_requires 'Test::MockModule';

auto_install;
WriteAll;

