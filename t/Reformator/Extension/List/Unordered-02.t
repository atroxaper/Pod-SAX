use v6;
use Test;
use lib 'lib';
use Pod::SAX::Common;
use Pod::Reformer::Extension::List::ListHelper;
use Pod::Reformer::Extension::List::ItemHelper;
use Pod::Reformer::Extension::List::ItemType;

my constant IT = ItemType;

plan 11;

my $pod-string = qq:to[END];
    =begin pod

    Dotted list with two levels (check different indent):

    =item1  Animal
    =item2     Vertebrate
    =item2     Invertebrate
    =item3     Invertebrate
    =item2     Invertebrate

    =item1 Phase
    =item2 Solid
    =item3 Liquid
    =item1 Liquid

    Trail paragraph.

    =end pod
    END

my $pod = get-pod $pod-string;
#say $pod[0];
#Pod::Block::Named{:name("pod")}
#  Pod::Block::Para
#    Dotted list with two levels (check different indent):
#  Pod::Item{:level("1")}
#    Pod::Block::Para
#      Animal
#  Pod::Item{:level("2")}
#    Pod::Block::Para
#      Vertebrate
#  Pod::Item{:level("2")}
#    Pod::Block::Para
#      Invertebrate
#  Pod::Item{:level("3")}
#    Pod::Block::Para
#      Invertebrate
#  Pod::Item{:level("2")}
#    Pod::Block::Para
#      Invertebrate
#  Pod::Item{:level("1")}
#    Pod::Block::Para
#      Phase
#  Pod::Item{:level("2")}
#    Pod::Block::Para
#      Solid
#  Pod::Item{:level("3")}
#    Pod::Block::Para
#      Liquid
#  Pod::Item{:level("1")}
#    Pod::Block::Para
#      Liquid
#  Pod::Block::Para
#    Trail paragraph.

my ListHelper $helper .= new;
my @args = $helper.produce-args($pod[0]);
is +@args, 11;
my $item;

$item = @args[0];
nok $item, Any.DEFINITE;
#=item1 Animal
$item = @args[1]<item-helper>;
is-deeply $item, ItemHelper.new(:1opens-lists, :first, :1level, :1position, type => IT::Unordered, tree-address => @(0, 1));
#=item2 Vertebrate
$item = @args[2]<item-helper>;
is-deeply $item, ItemHelper.new(:1opens-lists, :first, :2level, :1position, type => IT::Unordered, tree-address => @(0, 1, 1));
#=item2 Invertebrate
$item = @args[3]<item-helper>;
is-deeply $item, ItemHelper.new(:2level, :2position, type => IT::Unordered, tree-address => @(0, 1, 2));
#=item3 Invertebrate
$item = @args[4]<item-helper>;
is-deeply $item, ItemHelper.new(:1opens-lists, :first, :1closes-lists, :last, :3level, :1position, type => IT::Unordered, tree-address => @(0, 1, 2, 1));
#=item2 Invertebrate
$item = @args[5]<item-helper>;
is-deeply $item, ItemHelper.new(:1closes-lists, :last, :2level, :3position, type => IT::Unordered, tree-address => @(0, 1, 3));
#=item1 Phase
$item = @args[6]<item-helper>;
is-deeply $item, ItemHelper.new(:1level, :2position, type => IT::Unordered, tree-address => @(0, 2));
#=item2 Solid
$item = @args[7]<item-helper>;
is-deeply $item, ItemHelper.new(:1opens-lists, :first, :2level, :1position, type => IT::Unordered, tree-address => @(0, 2, 1));
#=item3 Liquid
$item = @args[8]<item-helper>;
is-deeply $item, ItemHelper.new(:1opens-lists, :first, :2closes-lists, :last, :3level, :1position, type => IT::Unordered, tree-address => @(0, 2, 1, 1));
#=item1 Liquid
$item = @args[9]<item-helper>;
is-deeply $item, ItemHelper.new(:1closes-lists, :last, :1level, :3position, type => IT::Unordered, tree-address => @(0, 3));


done-testing;