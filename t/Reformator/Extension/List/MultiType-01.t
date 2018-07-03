use v6;
use Test;
use lib 'lib';
use Saxopod::Reformator::Common;
use Saxopod::Reformator::Extension::List::ListHelper;
use Saxopod::Reformator::Extension::List::ItemHelper;
use Saxopod::Reformator::Extension::List::ItemType;

my constant IT = ItemType;

plan 6;

my $pod-string = qq:to[END];
    =begin pod

    Multi-type list:

    =item  Happy

    =item  Dopey

    =for item1 :numbered
    num-1-level-1

    =item  Dopey

    =for item1 :numbered
    num-2-level-1

    =end pod
    END

my $pod = get-pod $pod-string;
#say $pod[0];
#Pod::Block::Named{:name("pod")}
#  Pod::Block::Para
#    Multi-type list:
#  Pod::Item{:level("1")}
#    Pod::Block::Para
#      Happy
#  Pod::Item{:level("1")}
#    Pod::Block::Para
#      Dopey
#  Pod::Item{:config("\$\{:numbered}"), :level("1")}
#    Pod::Block::Para
#      num-1-level-1
#  Pod::Item{:level("1")}
#    Pod::Block::Para
#      Dopey
#  Pod::Item{:config("\$\{:numbered}"), :level("1")}
#    Pod::Block::Para
#      num-2-level-1

my ListHelper $helper .= new;
my @args = $helper.produce-args($pod[0]);
my $item;

$item = @args[0];
nok $item, Any.DEFINITE;

#=item  Happy
$item = @args[1]<item-helper>;
is-deeply $item, ItemHelper.new(:1opens-lists, :first, :1level, :1position, type => IT::Unordered, tree-address => @(0, 1));
#=item  Dopey
$item = @args[2]<item-helper>;
is-deeply $item, ItemHelper.new(:1level, :2position, type => IT::Unordered, tree-address => @(0, 2));
#=for item1 :numbered
$item = @args[3]<item-helper>;
is-deeply $item, ItemHelper.new(:1level, :3position, type => IT::Ordered, tree-address => @(0, 3));
#=item  Dopey
$item = @args[4]<item-helper>;
is-deeply $item, ItemHelper.new(:1level, :4position, type => IT::Unordered, tree-address => @(0, 4));
#=for item1 :numbered
$item = @args[5]<item-helper>;
is-deeply $item, ItemHelper.new(:1closes-lists, :last, :1level, :5position, type => IT::Ordered, tree-address => @(0, 5));

done-testing;