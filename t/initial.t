use Test::Class::Sugar;

testclass Some::Class::Name {
    sub simple_test : Test {
        ok 1;
    }
};

testclass Some::Other::Class::Name {
    sub simple_test : Test {
        ok 1;
    }
};

testclass DocumentedClass
"This is a \"DOCSTRING\" a la Emacs"
{
    sub simple_test : Test {
        ok 1;
    }
};

testclass ChildClass extends Some::Class::Name {
    sub extra_test : Test {
        ok 2, 'Child class test';
    }
};

testclass Child2 extends Some::Class::Name, Some::Other::Class::Name {
    sub child_test : Test {
        ok 3;
    }
};

Test::Class->runtests;
