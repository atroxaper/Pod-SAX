use v6;
use Test;
use lib 'lib';
use Pod::SAX::Common;
use Pod::Reformer::Extension::List::ListHelper;
use Pod::Reformer::Extension::List::ItemHelper;
use Pod::Reformer::Extension::List::ItemType;

my constant IT = ItemType;

plan 4;

my $pod-string = qq:to[END];
    =begin pod

    =comment Dotted list with one bold item:

    =begin item1
    The choices are:
    =end item1
    =item2 Liberty
    =item2 Death

    =end pod
    END

my $pod = get-pod $pod-string;
#say $pod[0];
#Pod::Block::Named{:name("pod")}
#  Pod::Block::Comment
#    Dotted list with one bold item:
#
#  Pod::Item{:level("1")}
#    Pod::Block::Para
#      The choices are:
#  Pod::Item{:level("2")}
#    Pod::Block::Para
#      Liberty
#  Pod::Item{:level("2")}
#    Pod::Block::Para
#      Death

my ListHelper $helper .= new;
my @args = $helper.produce-args($pod[0]);
my $item;

$item = @args[0];
nok $item, Any.DEFINITE;
#=begin item1
$item = @args[1]<item-helper>;
is-deeply $item, ItemHelper.new(:1opens-lists, :first, :1level, :1position, type => IT::Unordered, tree-address => @(0, 1));
#=item2 Liberty
$item = @args[2]<item-helper>;
is-deeply $item, ItemHelper.new(:1opens-lists, :first, :2level, :1position, type => IT::Unordered, tree-address => @(0, 1, 1));
#=item2 Death
$item = @args[3]<item-helper>;
is-deeply $item, ItemHelper.new(:2closes-lists, :last, :2level, :2position, type => IT::Unordered, tree-address => @(0, 1, 2));

done-testing;