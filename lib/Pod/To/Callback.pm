module Pod::To::Callback {
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

	sub make-attrs($pod, $caller, @history) {
		my %result = get-attributes($pod);
		%result{'instance'} = $pod;
		%result{'draft'} = $caller.draft;
		%result{'history'} = @history;
		%result{'storage'} = $caller.storage;
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

	class Caller is export {
		has %.callbacks is rw;
		has @.allowable-pod-classes is rw = Pod::Block, Pod::Config;
		has @.draft;
		has %.storage;

		multi method call-for(@pod) {
			return so (self.call-for($_) for @pod);
		}

		multi method call-for($pod) {
			my @history;
			self!visit($pod, @history);
			return True;
		}

		method !visit($pod, @history) {
			my %attrs = make-attrs($pod, self, @history);
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
	}
}