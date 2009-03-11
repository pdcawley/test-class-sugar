package Test::Class::Sugar::Context;
use Modern::Perl;
use base qw/Devel::Declare::Context::Simple/;

sub strip_docstring {
    my $self = shift;
    $self->skipspace;

    my $linestr = $self->get_linestr();
    if (substr($linestr, $self->offset, 1) eq q{"}) {
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
    return;
}

sub strip_options {
    my $self = shift;

    return {};
}

1;
