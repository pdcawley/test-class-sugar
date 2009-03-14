use strict;
use warnings;

use inc::Module::Install 0.77;

name  'Test-Class-Sugar';
all_from 'lib/Test/Class/Sugar.pm';

perl_version '5.010000';

recommends 'Test::Most';

requires "Modern::Perl";
requires "Test::Class" => '0.31';
requires "Sub::Name";
requires "Devel::Declare" => '0.003004';
requires "B::Hooks::EndOfScope";

test_requires 'Test::Most';


repository 'git://github.com/pdcawley/test-class-sugar.git';

WriteAll;

