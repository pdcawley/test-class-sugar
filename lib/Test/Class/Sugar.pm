package Test::Class::Sugar;

use Modern::Perl;

use Devel::Declare ();
use Devel::Declare::Context::Simple;
use Test::Class::Sugar::Context;
use Carp qw/croak/;

use namespace::clean;

use Sub::Exporter -setup => {
    exports => [qw/testclass/],
    groups => {default => [qw/testclass/]},
    installer => sub {
        my ($args, $to_export) = @_;
        my $pack = $args->{into};
        foreach my $name (@$to_export) {
            if (my $parser = __PACKAGE__->can("_parse_${name}")) {
                Devel::Declare->setup_for(
                    $pack,
                    { $name => { const => sub { $parser->($pack, @_) } } },
                );
            }
            if (my $code = __PACKAGE__->can("_extras_for_${name}")) {
                $code->($pack);
            }
        }
        Sub::Exporter::default_installer(@_);
    }
};

sub _parse_testclass {
    my $pack = shift;

    local $Carp::Internal{'Devel::Declare'} = 1;

    my $ctx = Test::Class::Sugar::Context->new->init(@_);
    my $initial_offset = $ctx->offset;
    my $preamble = '';
    my $classname;

    $ctx->skip_declarator;
    $ctx->skipspace;
    unless ($ctx->looking_at(qr/^(?:\+?uses|ex(?:tends|ercises)|extends)/, 9)) {
        $classname = $ctx->strip_name;
    }

    my $options = $ctx->strip_options;

    unless ($classname) {
        $options->{class_under_test} 
          // croak "Must specify a testclass name or a class to exercise";
        $classname = "Test::" . $options->{class_under_test} ;
    }

    $preamble .= "package ${classname}; use strict; use warnings;";

    my $baseclasses = $options->{base} || "Test::Class";
    $options->{helpers} //= ['Test::Most'];

    $preamble .= "use base qw/${baseclasses}/;";

    foreach my $helper (@{$options->{helpers}}) {
        $preamble .= "use ${helper};";
    }

    if (my $testedclass = $options->{class_under_test}) {
        $preamble .= "require ${testedclass}; sub class_under_test { \"${testedclass}\" };"
    }

    if (my $docstr = $ctx->strip_docstring()) {
        $preamble .= qq{sub _print_DOCSTRING : Test(startup) { diag ref(\$_[0]),"\n", q{${docstr}} };};
    }

    $ctx->skipspace;

    $ctx->inject_if_block($ctx->scope_injector_call() . $preamble)
        || croak "Expecting an opening brace";
}

sub testclass (&) {}

1;

