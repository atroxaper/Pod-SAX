module Pod::SAX::Iter {

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

		# TODO make a special .new method to call init method inside

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

		method init($start) {
			$!current = (Start.new(contents => $start.Array), 0);
			$!index = 0;
			$!stop = False;
		}

		method stop(--> List) {
			return (Nil, 0);
		}
	}
}