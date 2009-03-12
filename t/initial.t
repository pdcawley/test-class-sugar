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

testclass MultipleHelpers helpers Test::More, Test::Exception {
    sub multi_test : Test(2) {
        ok 4;
        lives_ok { 5 };
    }
}

testclass ShortcutHelper helper -Exception {
    sub exception_test : Test {
        lives_ok { 1 }
    }
}

testclass TestClass exercises Test::Class::Sugar {
    sub test_requirement : Test {
        my $self = shift;
        ok $self->class_under_test->isa( 'UNIVERSAL' );
    }
}


Test::Class->runtests;
