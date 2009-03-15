use Modern::Perl;
use MooseX::Declare;

class Test::Class::Sugar::CodeGenerator {
    use Sub::Name;

    has name    => (is => 'rw', isa => 'Str');
    has plan    => (is => 'rw');
    has context => (is => 'rw');

    method test_preamble {
        $self->context->scope_injector_call() . q{my $test = shift;};
    }

    method shadow_test {
        my $ctx = $self->context;
        my $name = $self->name;
        my $plan = $self->plan;

        my $classname = $ctx->get_curstash_name;

        my $longname = ($name !~ /::/)
          ? join('::', $classname, $name)
          : $name;

        $ctx->shadow(
            sub (&) {
                my $code = shift;
                no strict 'refs';
                *{$longname} = subname $longname => $code;
                $classname->add_testinfo($name,
                                         $ctx->declarator,
                                         $plan);
            }
        );
    }

    method inject_test {
        my $ctx = $self->context;
        $ctx->skipspace;
        $ctx->inject_if_block($self->test_preamble);
    }

    method install_test {
        $self->inject_test;
        $self->shadow_test;
    }
}
