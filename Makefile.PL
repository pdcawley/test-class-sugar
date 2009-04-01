use strict;
use warnings;

use inc::Module::Install 0.77;

name  'Test-Class-Sugar';
perl_version '5.010000';
all_from 'lib/Test/Class/Sugar.pm';

recommends 'Test::Most';

requires "Modern::Perl";
requires "Test::Class" => '0.32_1';
requires "Sub::Name";
requires "Devel::Declare" => '0.003005';
requires "B::Hooks::EndOfScope";
requires "MooseX::Declare";

test_requires 'Test::Most';


repository 'git://github.com/pdcawley/test-class-sugar.git';

WriteAll;

