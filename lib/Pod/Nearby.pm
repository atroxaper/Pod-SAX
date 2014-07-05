module Pod::Nearby {
	sub get-pod(Str $source) is export {
		EVAL $source ~ "\n\$=pod";
	}

	sub get-attributes($obj where {defined $obj}) is export {
		my %result;
		for $obj.^attributes {
			if ($_.has_accessor) {
				my $name-str = $_.name.substr(2);
				%result{$name-str} = $obj."$name-str"();
			}
		}
		return %result;
	}

	sub filter-args($sub,  %args) {
		my @param-names = $sub.signature.params.map: *.name.substr(1);
		my %result;
		for %args.keys -> $key {
			%result{$key} = %args{$key} if $key eq any(@param-names);
		}
		return %result;
	}

	#= Initialize Anchor object some dates by is rw fields ob object.
	#= Now we can insert only current %storage and @draft.
	sub init-anchor($anchor, %args) is export {
		for $anchor.^attributes.grep({.rw}) {
			my $name = $_.name.substr(2);
			if ($name ~~ any(%args.keys)) {
				$anchor."$name"() = %args{$name};
			}
		}
	}

	sub make-attrs($pod, $caller, @history, %state) {
		my %result = get-attributes($pod);
		%result<instance> = $pod;
		%result<draft> = $caller.draft;
		%result<history> = @history;
		%result<storage> = $caller.storage;
		%result<state> = %state;
		return %result;
	}

	role Anchor is export {
		method prepared(--> Bool) { ... }
		method priority(--> Int) { ... }
		method prepare(--> Bool) { ... }
	}

	class Nearer is export {
		has %.callbacks is rw;
		has @.allowable-pod-classes is rw = Pod::Block, Pod::Config;
		has @.draft;
		has %.storage;

		method clear() {
			@.draft = ();
			%.storage = ();
		}

		multi method approach-to(@pod) {
			return so (self.approach-to($_) for @pod);
		}

		multi method approach-to($pod) {
			my @history;
			self!visit($pod, @history);
			return True;
		}

		method !visit($pod, @history) {
			my %attrs = make-attrs($pod, self, @history, {});
			my @need-to-call = self!get-satisfy($pod.^name, %attrs);

			self!call(@need-to-call, 'start', %attrs);

			for $pod.content -> $cont {
				if $cont ~~ any(@.allowable-pod-classes) {
					self!visit($cont, @history.clone.push($pod));
				} else {
					%attrs{'content'} = $cont;
					self!call(@need-to-call, 'in', %attrs);
				}
			}

			self!call(@need-to-call, 'stop', %attrs);
		}

		method !call(@need-to-call, $type where any('start', 'stop', 'in'), %attrs) {
			for @need-to-call.grep({? $_{$type}}).map({$_{$type}}) -> $sub {
				my %args = filter-args($sub, %attrs);
				if %args ~~ $sub.signature {
					return if $sub(|%args);
				}
			}
		}

		method !get-satisfy($pod-name, %args) {
			my @result = ();
			for self.callbacks{$pod-name}.list.map({.key, .value}) -> $selector, $functions {
				my %need-args = filter-args($selector, %args);
				if ((%need-args ~~ $selector.signature) && ($selector(|%need-args))) {
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
	}

	class SimpleAnchor does Anchor is export {
		# for role satisfaction  #
		has Bool $.prepared is rw = False;
		has Int $.priority = 0;

		has $.template is rw;
		has %.storage is rw;

		has $!result = '';

		multi method gist() {
			return $!result;
		}

		multi method Str() {
			return $!result;
		}

		method prepare() {
			my $this = self;
			self.template ~~ m:g/ '<%' ['=']? $<key>=[ [ <!before '%>' > . ]* ] '%>' { unless $this.storage{$<key>.Str} {
				$this.prepared = False;
				return $this.prepared;
			}} /;
			$!result = $.template;
			$!result ~~ s:g/ '<%' ['=']? $<key>=[ [ <!before '%>' > . ]* ] '%>' /%.storage{$<key>.Str}/;
			$.prepared = True;
			return $.prepared;
		}
	}

	sub under-name(@history, $name --> Bool) is export {
		return so @history && @history[*-1] ~~ Pod::Block::Named && @history[*-1].name ~~ $name;
	}

	sub under-type(@history, $type --> Bool) is export {
		return so @history && @history[*-1] ~~ $type;
	}
}