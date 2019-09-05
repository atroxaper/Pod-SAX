use Saxopod::Reformator::Extension::List::ItemType;
unit class ItemHelper;

#|How many lists are opened by this item.
has Int $.opens-lists is rw = 0;
#|How many lists are closed by this item.
has Int $.closes-lists is rw = 0;
#|Is it first item in list or sublist.
has Bool $.first is rw = False;
#|Is it last item in list or sublist.
has Bool $.last is rw = False;
#|Is it break item. Next item will be 'continue' and with the same level.
has Bool $.paused is rw = False;
#|Is it continued item after list break.
has Bool $.continued is rw = False;
#|Type of current item (ordered, unordered).
has ItemType $.type is rw;
#|Level of item. Minimal level is 0.
has Int $.level is rw;
#|[Position of item in his level. Minimal position is 0.
# For Numbered item type it means item's number]
has Int $.position is rw;
#|[Array of positions of all item's parents.
# 0-level-parent position stored in 0 element,
# current element position stored in $!level element.]
has @.tree-address is rw;

multi method WHICH(ItemHelper:D:) {
  ObjAt.new('ItemHelper|' ~
    $!opens-lists.WHICH ~
    $!closes-lists.WHICH ~
    $!first.WHICH ~
    $!last.WHICH ~
    $!paused.WHICH ~
    $!continued.WHICH ~
    $!type.WHICH ~
    $!level.WHICH ~
    $!position.WHICH ~
    @!tree-address
  );
}