use Modern::Perl;
use MooseX::Declare;

class Test::Class::Sugar::CodeGenerator {
    use Sub::Name;
    use Carp qw/croak/;
    use B::Hooks::EndOfScope;

    has name    => (is => 'rw', isa => 'Str');
    has plan    => (is => 'rw');
    has context => (is => 'rw');

    has options => (
        is      => 'ro',
        isa     => 'HashRef',
        default => sub {{}},
    );

    has classname => (
        is => 'rw',
        isa => 'Str',
        lazy_build => 1,
    );

    method _build_classname {
        if ($self->options->{class_under_test}) {
            "Test::" . $self->options->{class_under_test};
        }
        else {
            $self->context->get_curstash_name
              || croak "Must specify a testclass name or a class to exercise";
        }
    }

    method test_preamble {
        $self->context->scope_injector_call() . q{my $test = shift;};
    }

    method inject_test {
        my $ctx = $self->context;
        $ctx->skipspace;
        $ctx->inject_if_block($self->test_preamble);
    }

    method shadow_test {
        my $ctx = $self->context;
        my $name = $self->name;
        my $plan = $self->plan;

        my $classname = $self->classname;

        my $longname = ($name !~ /::/)
          ? join('::', $classname, $name)
          : $name;

        $ctx->shadow(
            sub (&) {
                my $code = shift;
                no strict 'refs';
                *{$longname} = subname $longname => $code;
                $classname->add_testinfo(
                    $name,
                    $ctx->declarator,
                    $plan
                );
            }
        );
    }

    method testclass_preamble {
        my $preamble = '';
        my $ctx = $self->context;
        my $classname = $self->classname;
        my $options = $self->options;

        $preamble .= "package ${classname}; use strict; use warnings;";
        $preamble .= "use Test::Class::Sugar qw/-inner/;";

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

    method inject_testclass {
        $self->context->skipspace;
        $self->context->inject_if_block($self->testclass_preamble) //
          croak "Expecting an opening brace";
    }

    method shadow_testclass {
#        $self->context->shadow(sub (&) { shift->() });
    }

    method install_testclass {
        $self->has_classname
          // croak "You provide either a class name or an exercises clause";

        $self->inject_testclass;
        $self->shadow_testclass;
    }

    method install_test {
        $self->inject_test;
        $self->shadow_test;
    }
}
