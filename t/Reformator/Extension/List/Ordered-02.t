use v6;
use Test;
use lib 'lib';
use Saxopod::Reformator::Common;
use Saxopod::Reformator::Extension::List::ListHelper;
use Saxopod::Reformator::Extension::List::ItemHelper;
use Saxopod::Reformator::Extension::List::ItemType;

my constant IT = ItemType;

plan 3;

my $pod-string = qq:to[END];
    =begin pod

    Multi-paragraph list:

    =begin item :numbered
    I<italic>

    Some paragraph.
    =end item

    =begin item :numbered
    I<Italic again>

    More paragraphs.
    =end item

    =end pod
    END

my $pod = get-pod $pod-string;
#say $pod[0];
#Pod::Block::Named{:name("pod")}
#  Pod::Block::Para
#    Multi-paragraph list:
#  Pod::Item{:config("\$\{:numbered}"), :level("1")}
#    Pod::Block::Para
#
#      Pod::FormattingCode{:type("I")}
#        italic
#
#    Pod::Block::Para
#      Some paragraph.
#  Pod::Item{:config("\$\{:numbered}"), :level("1")}
#    Pod::Block::Para
#
#      Pod::FormattingCode{:type("I")}
#        Italic again
#
#    Pod::Block::Para
#      More paragraphs.

my ListHelper $helper .= new;
my @args = $helper.produce-args($pod[0]);
my $item;

$item = @args[0];
nok $item, Any.DEFINITE;
#=begin item :numbered
$item = @args[1]<item-helper>;
is-deeply $item, ItemHelper.new(:1opens-lists, :first, :1level, :1position, type => IT::Ordered, tree-address => @(0, 1));
#=begin item :numbered
$item = @args[2]<item-helper>;
is-deeply $item, ItemHelper.new(:1closes-lists, :last, :1level, :2position, type => IT::Ordered, tree-address => @(0, 2));

done-testing;