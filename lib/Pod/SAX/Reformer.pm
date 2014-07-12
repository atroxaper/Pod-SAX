class Reformer {

	use Pod::SAX::Iter;
	use Pod::SAX::Anchors;
	use Pod::SAX::Common;

	has %.callbacks is rw;
	has @.allowable-pod-classes is rw = Pod::Block, Pod::Config;
	has @.draft;
	has %.storage;
	has PodIterator $!iter;

	method clear() {
		@.draft = ();
		%.storage = ();
	}

	multi method reform(@pod) {
		return so (self.reform($_) for @pod);
	}

	multi method reform($pod) {
		$!iter .= new;
		$!iter.init($pod);
		my @history;
		self!visit(($!iter.get-next)[0], @history);
		return True;
	}

	method !visit($pod, @history) {
		my %attrs = self.make-attrs($pod, self, @history, {});
		my @need-to-call = self!get-satisfy($pod.^name, %attrs);

		self!call(@need-to-call, 'start', %attrs);

		my @next;
		while (@next = $!iter.get-next)[1] > -1 {
			if (@next[1] == 1) {
				self!visit(@next[0], @history.clone.push($pod));
			} else {
				%attrs{'content'} = @next[0];
				self!call(@need-to-call, 'in', %attrs);
			}
		}

		self!call(@need-to-call, 'stop', %attrs);
	}

	method !call(@need-to-call, $type where any('start', 'stop', 'in'), %attrs) {
		for @need-to-call.grep({? $_{$type}}).map({$_{$type}}) -> $sub {
			my %args = filter-args($sub.signature, %attrs);
			if %args ~~ $sub.signature {
				return if $sub(|%args);
			}
		}
	}

	method !get-satisfy($pod-name, %args) {
		my @result = ();
		for self.callbacks{$pod-name}>>.kv -> $selector, $functions {
			if filter-args($selector, %args) ~~ $selector {
				@result.push($functions);
			}
		}
		return @result;
	}

	method get-result() {
		# sort by priority and get anchor and its index in draft #
		my @anchors = @.draft.grep({$_ ~~ Anchor}).sort({$^a.priority <=> $^b.priority});
		init-anchor($_, {:draft(@.draft), :storage(%.storage)}) for @anchors;

		loop (my $i = 0; $i < +@anchors; ++$i) {
			my $is-somebody-false = True;
			for @anchors -> $anchor {
				unless $anchor.prepared {
					$is-somebody-false = $anchor.prepare() && $is-somebody-false;
				}
			}
			last if $is-somebody-false;
		}
		return @.draft.join;
	}

	# static methods #
	method get-attributes($obj where {defined $obj}) {
		my %result;
		for $obj.^attributes {
			if ($_.has_accessor) {
				my $name-str = $_.name.substr(2);
				%result{$name-str} = $obj."$name-str"();
			}
		}
		return %result;
	}

	method make-attrs($pod, $caller, @history, %state) {
		my %result = self.get-attributes($pod);
		%result<instance> = $pod;
		%result<draft> = $caller.draft;
		%result<history> = @history;
		%result<storage> = $caller.storage;
		%result<state> = %state;
		return %result;
	}
}
