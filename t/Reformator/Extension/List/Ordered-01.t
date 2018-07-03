use v6;
use Test;
use lib 'lib';
use Saxopod::Reformator::Common;
use Saxopod::Reformator::Extension::List::ListHelper;
use Saxopod::Reformator::Extension::List::ItemHelper;
use Saxopod::Reformator::Extension::List::ItemType;

my constant IT = ItemType;

plan 14;

my $pod-string = qq:to[END];
    =begin pod
    Numbered list:

    =for item1 :numbered
    Visito

    =for item2 :numbered
    Veni

    =for item3 :numbered
    Vidi

    =for item2 :numbered
    Vidi

    =for item3 :numbered
    Vidi

    =for item1 :numbered
    Vidi

    Numbered list from number 1 again:

    =for item1 :numbered
    Visito

    And next list continue numbers:

    =for item1 :numbered :continued
    Veni

    =for item2 :numbered
    Vidi

    And next list continue numbers (difficult case):

    =for item3 :numbered :continued
    Veni

    =end pod
    END

my $pod = get-pod $pod-string;
#say $pod[0];
#Pod::Block::Named{:name("pod")}
#  Pod::Block::Para
#    Numbered list:
#  Pod::Item{:config("\$\{:numbered}"), :level("1")}
#    Pod::Block::Para
#      Visito
#  Pod::Item{:config("\$\{:numbered}"), :level("2")}
#    Pod::Block::Para
#      Veni
#  Pod::Item{:config("\$\{:numbered}"), :level("3")}
#    Pod::Block::Para
#      Vidi
#  Pod::Item{:config("\$\{:numbered}"), :level("2")}
#    Pod::Block::Para
#      Vidi
#  Pod::Item{:config("\$\{:numbered}"), :level("3")}
#    Pod::Block::Para
#      Vidi
#  Pod::Item{:config("\$\{:numbered}"), :level("1")}
#    Pod::Block::Para
#      Vidi
#  Pod::Block::Para
#    Numbered list from number 1 again:
#  Pod::Item{:config("\$\{:numbered}"), :level("1")}
#    Pod::Block::Para
#      Visito
#  Pod::Block::Para
#    And next list continue numbers:
#  Pod::Item{:config("\$\{:continued, :numbered}"), :level("1")}
#    Pod::Block::Para
#      Veni
#  Pod::Item{:config("\$\{:numbered}"), :level("2")}
#    Pod::Block::Para
#      Vidi

my ListHelper $helper .= new;
my @args = $helper.produce-args($pod[0]);
my $item;

$item = @args[0];
nok $item, Any.DEFINITE;
#=for item1 :numbered
$item = @args[1]<item-helper>;
is-deeply $item, ItemHelper.new(:1opens-lists, :first, :1level, :1position, type => IT::Ordered, tree-address => @(0, 1));
#=for item2 :numbered
$item = @args[2]<item-helper>;
is-deeply $item, ItemHelper.new(:1opens-lists, :first, :2level, :1position, type => IT::Ordered, tree-address => @(0, 1, 1));
#=for item3 :numbered
$item = @args[3]<item-helper>;
is-deeply $item, ItemHelper.new(:1opens-lists, :first, :1closes-lists, :last, :3level, :1position, type => IT::Ordered, tree-address => @(0, 1, 1, 1));
#=for item2 :numbered
$item = @args[4]<item-helper>;
is-deeply $item, ItemHelper.new(:2level, :2position, type => IT::Ordered, tree-address => @(0, 1, 2));
#=for item3 :numbered
$item = @args[5]<item-helper>;
is-deeply $item, ItemHelper.new(:1opens-lists, :first, :2closes-lists, :last, :3level, :1position, type => IT::Ordered, tree-address => @(0, 1, 2, 1));
#=for item1 :numbered
$item = @args[6]<item-helper>;
is-deeply $item, ItemHelper.new(:1closes-lists, :last, :1level, :2position, type => IT::Ordered, tree-address => @(0, 2));

$item = @args[7];
nok $item, Any.DEFINITE;

#=for item1 :numbered
$item = @args[8]<item-helper>;
is-deeply $item, ItemHelper.new(:1opens-lists, :first, :paused, :1level, :1position, type => IT::Ordered, tree-address => @(0, 1));

$item = @args[9];
nok $item, Any.DEFINITE;

#=for item1 :numbered :continued
$item = @args[10]<item-helper>;
is-deeply $item, ItemHelper.new(:continued, :1level, :2position, type => IT::Ordered, tree-address => @(0, 2));
#for item2 :numbered
$item = @args[11]<item-helper>;
is-deeply $item, ItemHelper.new(:1opens-lists, :first, :paused, :2level, :1position, type => IT::Ordered, tree-address => @(0, 2, 1));

$item = @args[12];
nok $item, Any.DEFINITE;

#=for item3 :numbered :continued
$item = @args[13]<item-helper>;
is-deeply $item, ItemHelper.new(:1opens-lists, :first, :3closes-lists, :last, :continued, :3level, :1position, type => IT::Ordered, tree-address => @(0, 2, 1, 1));

done-testing;