use Test::Class::Sugar;

testclass Some::Class::Name {
    sub simple_test : Test {
        ok 1;
    }
};

Some::Class::Name->runtests;
