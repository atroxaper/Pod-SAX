module Saxopod::Reformator::Iter {

	our sub has-content($obj) {
		return $obj.^attributes.grep({.has_accessor && .name eq '@!contents'});
	}

	our class Start {
		has @.contents;
	}

	class PodIterator is export {
		has $!current;	# pair of pod object and next index of its content
		has @!parent;	# array of currents
		has $!index;	# index of next element in @content
		has Bool $!stop;

		method new($pod) {
			self.bless(:$pod);
		}

		submethod TWEAK(:$pod where *.defined) {
			$!current = (Start.new(contents => $pod.Array), 0);
			$!index = 0;
			$!stop = False;
		}

		method get-next(--> List) {
			return (Nil, 0) if $!stop;
			if ($!index >= +$!current[0].contents) {
				if (@!parent) {
					($!current, $!index) = @!parent.pop.kv;
					return (-1, -1);
				}
				$!stop = True;
				return (Nil, 0);
			}
			my $next = $!current[0].contents[$!index++];
			if $next ~~ Pod::Block || $next.&has-content {
				@!parent.push(Pair.new(:key($!current), :value($!index)));
				$!current = $next;
				$!index = 0;
				return ($next, 1)
			} else {
				return ($next, 0);
			}
		}

		method stop(--> List) {
			return (Nil, 0);
		}
	}
}