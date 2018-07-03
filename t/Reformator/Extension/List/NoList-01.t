use v6;
use Test;
use lib 'lib';
use Saxopod::Reformator::Common;
use Saxopod::Reformator::Extension::List::ListHelper;

plan 3;

my $pod-string = qq:to[END];
    =begin pod

    There are not lists.

    And there too.

    =end pod
    END

my $pod = get-pod $pod-string;
my ListHelper $helper .= new;
my @args = $helper.produce-args($pod[0]);
is +@args, 2;
nok $_, Any.DEFINITE for @args;

done-testing;