class Reformator {

	use Saxopod::Reformator::Iter;
	use Saxopod::Reformator::Anchors;
	use Saxopod::Reformator::Common;
	use Signature::Filter;

	has %.callbacks is rw;
	has @.allowable-pod-classes is rw = Pod::Block, Pod::Config;
	has @.draft;
	has %.storage;
	has PodIterator $!iter;
	has @.extensions;

	method clear() {
		@!draft = ();
		%!storage = ();
	}

	multi method reform(@pod) {
		return so (self.reform($_) for @pod);
	}

	multi method reform($pod) {
		$!iter .= new($pod);
		my @history;
    my @*draft;
		self!visit(($!iter.get-next)[0], @history, %());
    @!draft.append: @*draft;
		return True;
	}

	method !visit($pod, @history, %ext-arg) {
		my %attrs = %(|$pod.&get-attributes, instance => $pod, :%!storage, :@history, state => %(), |%ext-arg);
    my @ext-args := self!make-extensions-args($pod);
		my @need-to-call := self!get-satisfy($pod.^name, %attrs);

		self!call(@need-to-call, 'start', %attrs);

		my @next;
		my $i = 0;
		while (@next = $!iter.get-next)[1] > -1 {
			if (@next[1] == 1) {
				self!visit(@next[0], @history.clone.push($pod), @ext-args[$i++]);
			} else {
			  %attrs.push(@ext-args[$i++].kv);
				%attrs{'contents'} = @next[0];
				self!call(@need-to-call, 'in', %attrs);
			}
		}

		self!call(@need-to-call, 'stop', %attrs);
	}

	method !call(@need-to-call, $type where any('start', 'stop', 'in'), %attrs) {
		@need-to-call.map({$_{$type}}).grep(*.defined).first(-> $sub {
			my %args = $sub.&filter-params(%attrs);
			so $sub.&can-call-with(%args) && $sub(|%args);
		});
	}

	method !get-satisfy($pod-name, %args) {
		with %!callbacks{$pod-name} -> $for-name {
			return $for-name.values.grep({
				my $selector = .key;
				my %need-args = $selector.&filter-params(%args);
				so ($selector.&can-call-with(%need-args)
				&& ($selector !~~ Sub || $selector(|%need-args)));
			}).map(*.value).List;
		}
		return ();
	}

	method get-result() {
		# sort by priority and get anchor and its index in draft #
		my @anchors = @!draft.grep({$_ ~~ Anchor}).sort({$^a.priority <=> $^b.priority});
		init-anchor($_, {:@!draft, :%!storage}) for @anchors;

		loop (my $i = 0; $i < +@anchors; ++$i) {
			my $is-somebody-false = True;
			for @anchors -> $anchor {
				unless $anchor.prepared {
					$is-somebody-false = $anchor.prepare() && $is-somebody-false;
				}
			}
			last if $is-somebody-false;
		}
		return @!draft.join;
	}

	#|[Use extensions (if they exists) and produce additional args for
	#| each need specified pod content.
	#|
	#| Returns: an array with additional args hashes for each element from
	#| pod's content.]
	method !make-extensions-args($pod) {
	  my @result;
	  push @result, %() for $pod.contents;

	  for @!extensions -> $ext {
	    my @from-ext := $ext.produce-args($pod);
	    for @from-ext.kv -> $i, $args {
	      @result[$i].push($args.kv);
	    }
	  }

	  return @result;
	}
}
