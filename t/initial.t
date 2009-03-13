use Modern::Perl;
use Test::Class::Sugar;

testclass Some::Class::Name {
    sub simple_test : Test {
        ok 1;
    }
}

testclass Some::Other::Class::Name {
    sub simple_test : Test {
        ok 1;
    }
}

testclass DocumentedClass
"This is a \"DOCSTRING\" a la Emacs"
{
    sub simple_test : Test {
        ok 1;
    }
}

testclass ChildClass extends Some::Class::Name {
    sub extra_test : Test {
        ok 2, 'Child class test';
    }
}

testclass Child2 extends Some::Class::Name, Some::Other::Class::Name {
    sub child_test : Test {
        ok 3;
    }
}

testclass MultipleHelpers uses Test::More, Test::Exception {
    sub multi_test : Test(2) {
        ok 4;
        lives_ok { 5 };
    }
}

testclass ShortcutHelper uses -Exception {
    sub exception_test : Test {
        lives_ok { 1 }
    }
}

testclass AddsCarp +uses Carp, -Warn {
    sub warning_test : Test {
        warning_like { carp "foo" } qr/foo/, "expects a warning";
    }
}

testclass TestClass exercises Test::Class::Sugar {
    sub test_requirement : Test {
        my $test = shift;
        ok $test->class_under_test->isa( 'UNIVERSAL' );
    }
}

BEGIN {
    package Foo;
    sub foo {'foo'}
}

testclass exercises Foo {
    sub test_class_name : Test {
        my $test = shift;
        is ref($test) => 'Test::Foo';
    }

    sub test_class_under_test : Test {
        my $test = shift;
        is $test->class_under_test => 'Foo';
    }
}

testclass WithInnerKeywords {
    test simpletest {
        is $test->current_method, 'simpletest';
    }

    test 'named with a string' {
        is $test->current_method, 'named_with_a_string';
    }

    test named with multiple symbols {
        is $test->current_method, 'test_named_with_multiple_symbols';
    }

    test with multiple assertions >> 3 {
        ok 1;
        ok 2;
        ok 3;
    }
}

testclass LifeCycle {
    my $log = '';

    startup       { $log .= 'startup ' }
    setup         { $log .= 'setup '}
    test one >> 0 { $log .= 'test ' }
    test two >> 0 { $log .= 'test ' }
    teardown      { $log .= 'teardown '}
    shutdown >> 1 {
        is $log, 'startup setup test teardown setup test teardown ',
    }
}

Test::Class->runtests;
