package Test::Class::Sugar::Context;
use Modern::Perl;
use base qw/Devel::Declare::Context::Simple/;

use Carp qw/croak/;

sub strip_docstring {
    my $self = shift;
    $self->skipspace;

    my $linestr = $self->get_linestr();
    return unless $self->looking_at('"');

    my $length = Devel::Declare::toke_scan_str($self->offset);
    my $docstring = Devel::Declare::get_lex_stuff();
    Devel::Declare::clear_lex_stuff();
    if ( $length < 0 ) {
        $linestr .= $self->get_linestr();
        $length = rindex($linestr, q{"}) - $self->offset + 1;
    }
    else {
        $linestr = $self->get_linestr();
    }

    substr($linestr, $self->offset, $length) = '';
    $self->set_linestr($linestr);

    return $docstring;
}

sub looking_at {
    my($self, $expected, $len) = @_;
    $len //= ref($expected) ? 1 : length($expected);

    my $linestr = $self->get_linestr;
    substr($linestr, $self->offset, $len) ~~ $expected;
}

sub strip_options {
    my $self = shift;
    $self->skipspace;

    my %ret;

    while (!$self->looking_at(qr/[{"]/)) {
        $self->strip_base_classes(\%ret)
          // croak 'Expected option name';
    }

    return \%ret;
}

sub strip_base_classes {
    my($self, $ret) = @_;
    $self->skipspace;

    Carp::carp(substr($self->get_linestr, $self->offset));
    return unless $self->strip_string('extends');

    while (1) {
        $self->skipspace;

        my $baseclass = $self->strip_name
          // croak 'expecting a base class';
        $ret->{base} .= "$baseclass ";
        return 1 unless $self->strip_comma;
    }
}

sub strip_comma {
    my $self = shift;
    $self->skipspace;
    $self->strip_string(',');
}

sub strip_string {
    my($self, $expected) = @_;

    return unless $self->looking_at($expected);
    my $linestr = $self->get_linestr;

    substr($linestr, $self->offset, length($expected)) = '';
    $self->set_linestr($linestr);
    return 1;
}

1;
