use v6;
use Test;
use lib 'lib';
use Saxopod::Reformator::Common;
use Saxopod::Reformator::Extension::List::ListHelper;
use Saxopod::Reformator::Extension::List::ItemHelper;
use Saxopod::Reformator::Extension::List::ItemType;

my constant IT = ItemType;

plan 4;

my $pod-string = qq:to[END];
    =begin pod

    Simple dotted list:

    =item  Happy
    =item  Dopey
    =item  Sleepy

    =end pod
    END

my $pod = get-pod $pod-string;
#say $pod[0];
#Pod::Block::Named{:name("pod")}
#  Pod::Block::Para
#    Simple dotted list:
#  Pod::Item{:level("1")}
#    Pod::Block::Para
#      Happy
#  Pod::Item{:level("1")}
#    Pod::Block::Para
#      Dopey
#  Pod::Item{:level("1")}
#    Pod::Block::Para
#      Sleepy

my ListHelper $helper .= new;
my @args = $helper.produce-args($pod[0]);
my $item;

$item = @args[0];
nok $item, Any.DEFINITE;

$item = @args[1]<item-helper>;
is-deeply $item, ItemHelper.new(:1opens-lists, :first, :1level, :1position, type => IT::Unordered, tree-address => @(0, 1));

$item = @args[2]<item-helper>;
is-deeply $item, ItemHelper.new(:1level, :2position, type => IT::Unordered, tree-address => @(0, 2));

$item = @args[3]<item-helper>;
is-deeply $item, ItemHelper.new(:1closes-lists, :last, :1level, :3position, type => IT::Unordered, tree-address => @(0, 3));

done-testing;