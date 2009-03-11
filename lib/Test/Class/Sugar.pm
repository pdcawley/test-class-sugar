package Test::Class::Sugar;

use Modern::Perl;

use Devel::Declare ();
use Devel::Declare::Context::Simple;
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

    my $ctx = Devel::Declare::Context::Simple->new->init(@_);
    my $initial_offset = $ctx->offset;
    my $preamble = '';
    my $classname;

    $ctx->skip_declarator;
    if ($classname = $ctx->strip_name) {
        $preamble .= "package ${classname}; use base Test::Class; use Test::Most;";
    }
    else {
        croak "Expected a class name";
    }
    $ctx->skipspace;
    my $linestr = $ctx->get_linestr;

    Carp::carp '"', $ctx->get_linestr, '"';
    $ctx->inject_if_block($preamble);
}

sub testclass (&) {}

1;
