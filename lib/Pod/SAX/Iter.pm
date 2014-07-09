module Pod::SAX::Iter {

	our sub has-content($obj) {
		return $obj.^attributes.grep({.has_accessor && .name eq '@!content'});
	}

	our class Start {
		has @.content;
	}

	class PodIterator is export {
		has $!current;	# pair of pod object and next index of its content
		has @!parent;	# array of currents
		has $!index;	# index of next element in @content
		has Bool $!stop;

		method get-next(--> Parcel) {
			return (Nil, 0) if $!stop;
			if ($!index >= +$!current.content) {
				if (@!parent) {
					($!current, $!index) = @!parent.pop.kv;
					return -1, -1;
				}
				$!stop = True;
				return (Nil, 0);
			}
			my $next = $!current.content[$!index++];
			if $next ~~ Pod::Block || $next.&has-content {
				@!parent.push(Pair.new(:key($!current), :value($!index)));
				$!current = $next;
				$!index = 0;
				return $next, 1
			} else {
				return $next, 0;
			}
		}

		method init($start) {
			$!current = Start.new(:content($start)), 0;
			$!index = 0;
			$!stop = False;
		}

		method stop(--> Parcel) {
			return Nil, 0;
		}
	}
}