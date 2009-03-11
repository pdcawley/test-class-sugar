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

# testclass Still::Another::Class extends Some::Class::Name {
#     sub extra_test : Test {
#         ok 2, 'Child class test';
#     }
# };

Test::Class->runtests;
