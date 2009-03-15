package Test::Class::Sugar;

use Modern::Perl;

use Devel::Declare ();
use Devel::Declare::Context::Simple;
use B::Hooks::EndOfScope;
use Test::Class::Sugar::Context;
use Test::Class::Sugar::CodeGenerator;
use Carp qw/croak/;

use namespace::clean;

my %PARSER_FOR = (
    testclass => '_parse_testclass',
    startup   => '_parse_inner_keyword',
    setup     => '_parse_inner_keyword',
    test      => '_parse_inner_keyword',
    teardown  => '_parse_inner_keyword',
    shutdown  => '_parse_inner_keyword',
);

use Sub::Exporter -setup => {
    exports => [qw/testclass startup setup test teardown shutdown/],
    groups => {default => [qw/testclass/],
               inner   => [qw/startup setup test teardown shutdown/]},
    installer => sub {
        my ($args, $to_export) = @_;
        my $pack = $args->{into};
        foreach my $name (@$to_export) {
            if (my $parser = __PACKAGE__->can($PARSER_FOR{$name}//'-NOTHING-')) {
                Devel::Declare->setup_for(
                    $pack,
                    { $name => { const => sub { $parser->($pack, @_) } } },
                );
            }
        }
        Sub::Exporter::default_installer(@_);
    }
};

sub _test_generator {
    my($ctx, $name, $plan) = @_;
    Test::Class::Sugar::CodeGenerator->new(
        context => $ctx,
        name    => $name,
        plan    => $plan,
    );
}

sub _testclass_generator {
    my($ctx, $classname, $options) = @_;
    my $ret = Test::Class::Sugar::CodeGenerator->new(
        context   => $ctx,
        options   => $options,
    );
    $ret->classname($classname) if $classname;
    return $ret;
}


sub _parse_inner_keyword {
    my $pack = shift;

    local $Carp::Internal{'Devel::Declare'} = 1;

    my $ctx = Test::Class::Sugar::Context->new->init(@_);
    my $preamble = '';

    $ctx->skip_declarator;

    my $name = $ctx->strip_test_name
        || croak "Can't make a test without a name";
    my $plan = $ctx->strip_plan;

    _test_generator($ctx, $name, $plan)->install_test();

    return;
}

sub _testclass_preamble {
    my($ctx, $classname, $options) = @_;
    my $preamble = '';

    unless ($classname) {
        $options->{class_under_test}
        // croak "Must specify a testclass name or a class to exercise";
        $classname = "Test::" . $options->{class_under_test} ;
    }

    $preamble .= "package ${classname}; use strict; use warnings;";
    $preamble .= "use " . __PACKAGE__ . " qw/-inner/;";

    my $baseclasses = $options->{base} || "Test::Class";
    $options->{helpers} //= ['Test::Most'];

    $preamble .= "use base qw/${baseclasses}/;";

    foreach my $helper (@{$options->{helpers}}) {
        $preamble .= "use ${helper};";
    }

    if (my $testedclass = $options->{class_under_test}) {
        $preamble .= "require ${testedclass} unless \%${testedclass}::; sub subject { \"${testedclass}\" };"
    }
     $ctx->scope_injector_call() . $preamble;
}

sub _parse_testclass {
    my $pack = shift;

    local $Carp::Internal{'Devel::Declare'} = 1;

    my $ctx = Test::Class::Sugar::Context->new->init(@_);

    $ctx->skip_declarator;
    my $classname = $ctx->strip_testclass_name;
    _testclass_generator($ctx, $classname, $ctx->strip_options)
        ->install_testclass;
}

sub testclass (&) {}

sub startup (&) {}
sub setup (&) {}
sub test (&) { croak "Should not be called" }
sub teardown (&) {}
sub shutdown (&) {}

1;
__END__

=head1 NAME

Test::Class::Sugar - Helper syntax for writing Test::Class tests

=head1 SYNOPSIS

    use Test::Class::Sugar;

    testclass exercises Person {
        # Test::Most has been magically included

        startup >> 1 {
            use_ok $test->subject;
        }

        test autonaming {
            is ref($test), 'Test::Person';
        }

        test the naming of parts {
            is $test->current_method, 'test_the_naming_of_parts';
        }

        test multiple assertions >> 2 {
            is ref($test), 'Test::Person';
            is $test->current_method, 'test_multiple_assertions';
        }
    }

    Test::Class->runtests;

=head1 DESCRIPTION

Test::Class::Sugar provides a new syntax for setting up your Test::Class based
tests. The idea is that we bundle up all the tedious boilerplate involved in
writing a class in favour of getting to the meat of what you're testing. We
made warranted assumptions about what you want to do, and we do them for
you. So, when you write

    testclass exercises Person {
        ...
    }

What Perl sees, after Test::Class::Sugar has done it's work is, roughly:

    {
        package Test::Person;
        use base qw/Test::Class/;
        use strict; use warnings;
        require Person;

        sub subject { 'Person' };

        ...
    }

Some of the assumptions we made are overrideable, others aren't. Yet. Most of
them will be though.

=head2 Why you shouldn't use Test::Class::Sugar

Test::Class::Sugar is very new, pretty untested and is indadvertently hostile
to you if you confuse it's parser. Don't use it if you want to live.

=head2 Why you should use Test::Class::Sugar

But it's so shiny. Test::Class::Sugar was written to scratch an itch I had
when writing some tests for a L<MooseX::Declare> based module. Switching from
the implementation code to the test code was like shifting from fifth to first
gear in one fell swoop. Not fun. This is my attempt to sprinkle some
C<Devel::Declare> magic dust over the testing experience.

=head2 Bear this in mind

B<Test::Class::Sugar is not a source filter>

I know it looks like a source filter in the right light, but it isn't. Source
filters fall down because only perl can parse Perl, so it's easy to confuse
them. Devel::Declare based modules work by letting perl parse Perl until it
comes across a new keyword, at which point it temporarily hands parsing duty
over to a new parser which has the job of parsing the little language
introduced by the keyword, turning it into real Perl, and handing the
responsibility for parsing that back to Perl. Obviously, it's still possible
for that to screw things up royally, but there are fewer opportunities to fuck
up.

We now return you to your regularly schedule documentation.

=head1 SYNTAX

Essentially, Test::Class::Sugar adds some new keywords to perl. Here's what
they do, and what they expect.

=over

=item B<testclass>

    testclass NAME?
      ( exercises CLASS
      | extends CLASS (, CLASS)*
      | +?uses HELPER (, HELPER)*
      )*

Where B<NAME> is is an optional test class name - the sort of thing you're
used to writing after C<package>. You don't have to name your C<testclass>,
but if you don't supply a name, you MUST supply an exercises clause.

=over

=item exercises CLASS

You can supply at most one C<exercises> clause. This specifies the class under
test. We use it to autoname the class if you haven't provided a NAME of your
own (the default name of the class would be C<< Test::<CLASS> >>). Also, if
you supply an exercises clause, the class will be autorequired and your test
class will have a C<subject> helper method, which will return the name of the
class under test.

=item extends CLASS (, CLASS)*

Sometimes, you don't want to inherit directly from B<Test::Class>. If that's
the case, add an C<extends> clause, and your worries will be over. The extends
clause supports, but emphatically does not encourage, multiple
inheritance. Friends don't let friends do multiple inheritance, but
Test::Class::Sugar's not a friend, it's a robot servant which will provide you
with more than enough rope.

=item +?uses HELPER (, HELPER)*

Ah, the glory that is the C<uses> clause. If you don't provide a uses clause,
Test::Class::Sugar will assume that you want to use L<Test::Most> as your
testing only testing helper library. If you would rather use, say,
L<Test::More> then you can do:

    testclass ExampleTest uses -More {...}

Hang on, C<-More>, what's that about? It's a simple shortcut. Instead of
making you write C<uses Test::This, Test::That, Test::TheOther>, you can write
C<uses -This, -That, -TheOther> and we'll expand the C<-> into C<Test::> and
do the right thing.

If, like me, you like Test::Most, but you want to use some other helper
modules, then you'd do:

    testclass AnotherExample +uses -MockObject, Moose {...}

C<+uses> extends the list of helper classes, so as well as autousing
Test::Most, you'll get L<Test::MockObject> and L<Moose>.

Note that, if you need to do anything special in the way of import arguments,
you should do the C<use> yourself. We're all about the 80:20 rule here.

=back

=item B<test>

    test WORD ( WORD )* (>> PLAN) { ... }

I may be fooling myself, but I hope its obvious what this does. Here's a few
examples to show you what's happening:

    test with multiple subtests >> 3 {...}
    test with no_plan >> no_plan {...}
    test 'a complicated description with "symbols" in it' {...}

Gets translated to:

    sub test_with_multiple_subtests : Test(3) {...}
    sub test_with_no_plan : Test(no_plan) {...}
    sub a_complicated_description_with_symbols_in_it : Test {...}

See L<Test::Class/Test) for details of C<PLAN>'s semantics.

=item B<startup>, B<setup>, B<teardown>, C<shutdown>

These lifecycle helpers work in pretty much the same way as L</test>, but with
the added wrinkle that, if you don't supply a name, they generate method names
derived from the name of the test class and the name of the helper, so, for
instance: 

    testclass Test::Lifecycle::Autonaming {
        setup { ... }
    }

is equivalent to writing:

    testclass Test::Lifecycle::Autonaming {
        setup 'setup_Test_Lifecycle_Autonaming' {...}
    }

Other than that, the lifecycle helpers behave pretty much as described in
L<Test::Class|Test::Class/Test>. 

=back

=head1 DIAGNOSTICS

Right now, Test::Class::Sugar's diagnostics range from the confusing to the
downright misleading. Expect progress on this in the future, tuit supply
permitting. 

Patches welcome.

=head1 BUGS AND LIMITATIONS

=head2 Known bugs

=over

=item Screwy line numbers

Test::Class::Sugar can screw up the accord between the line perl thinks some
code is on and the line the code is I<actually> on. This makes debugging test
classes harder than it should be. Our error reporting is bad enough already
without making things worse.

=back

=head2 Unknown bugs

There's bound to be some.

=head2 Patches welcome.

Please report any bugs or feature requests to me. It's unlikely you'll get any
response if you use L<http://rt.cpan.org> though. Your best course of action
is to fork the project L<http://www.github.com/pdcawley/test-class-sugar>,
write at least one failing test (Write something in C<testclass> form that
should work, but doesn't. If you can arrange for it to fail gracefully, then
please do, but if all you do is write something that blows up spectacularly,
that's good too. Failing/exploding tests are like manna to a maintenance
programmer.

=head1 AUTHOR

Piers Cawley C<< <pdcawley@bofh.org.uk> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2009, Piers Cawley C<< <pdcawley@bofh.org.uk> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
