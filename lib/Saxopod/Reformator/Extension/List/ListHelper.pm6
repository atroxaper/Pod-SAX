use Saxopod::Reformator::Extension;
use Saxopod::Reformator::Extension::List::ItemHelper;
use Saxopod::Reformator::Extension::List::ItemType;

unit class ListHelper does Extension;

my constant IT = ItemType;

method produce-args(Pod::Block $pod --> List) {
  my @contents := $pod.contents;
  my @result[@contents.elems];
  my @addresses = [0];

  my ($current-index, $current-pod, $current-item, $was-middle-block)
      = self!get-next(-1, @contents);
  return @result if $current-index == -1;

  #first fake item pattern.
  my $prev-item = ItemHelper.new(:0level);

  while ($current-index != -1) {
    @result[$current-index] = %('item-helper' => $current-item);

    self!calc-items($current-pod, $current-item, $prev-item, $was-middle-block, @addresses);

    $prev-item = $current-item;
    ($current-index, $current-pod, $current-item, $was-middle-block)
          = self!get-next($current-index, @contents);
  }
  self!calc-items($current-pod, $current-item, $prev-item, $was-middle-block, @addresses);

  return @result;
}

method !calc-items($current-pod, $current-item, $prev-item, $was-middle-block, @addresses) {
  my ($c-level, $p-level) = ($current-item.level, $prev-item.level);
  if $was-middle-block {
    my $c-continued = self!retrieve-continued($current-pod);
    if $c-continued {
      # was break with continue in the same list
      $prev-item.paused = True;
      $current-item.continued = True;
      if $c-level > $p-level {
        $current-item.first = True;
        $current-item.opens-lists = $c-level - $p-level;
        push @addresses, 0 for ^($c-level - $p-level);
      } elsif $c-level < $p-level {
        $prev-item.last = True;
        $prev-item.closes-lists = $p-level - $c-level;
        @addresses.splice($c-level + 1);
      }
    } else {
      # that is break of two lists
      $prev-item.last = True;
      $prev-item.closes-lists = $p-level;
      @addresses.splice(1);

      $current-item.first = True;
      $current-item.opens-lists = $c-level;
      push @addresses, 0 for ^($c-level);
    }
  } else {
    # no break at all
    if $c-level > $p-level {
      $current-item.first = True;
      $current-item.opens-lists = $c-level - $p-level;
      push @addresses, 0 for ^($c-level - $p-level);
    } elsif $c-level < $p-level {
      $prev-item.last = True;
      $prev-item.closes-lists = $p-level - $c-level;
      @addresses.splice($c-level + 1);
    }
  }
  # fill general fields
  $current-item.type = self!retrieve-type($current-pod);
  ++@addresses[* - 1];
  $current-item.position = @addresses[* - 1];
  $current-item.tree-address = @addresses.clone;
}

method !get-next($current-index, @contents) {
  my $was-middle-block = False;
  for ($current-index + 1)..^+@contents -> $i {
    my $pod = @contents[$i];
    if $pod !~~ Pod::Item {
      $was-middle-block = True;
    } else {
      return $i,$pod, ItemHelper.new(level => self!retrieve-level($pod)),
          $was-middle-block && $current-index != -1;
    }
  }
  # last fake item pattern
  return -1, Pod::Item.new(:0level), ItemHelper.new(:0level), False;
}

method !retrieve-level(Pod::Item:D $pod) {
  return $pod.level;
}

method !retrieve-continued(Pod::Item:D $pod) {
  $pod.config<continued> // False;
}

method !retrieve-type(Pod::Item:D $pod) {
  return IT::Ordered if $pod.config<numbered>;
  return IT::Unordered;
}
