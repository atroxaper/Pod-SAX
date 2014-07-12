module Pod::SAX::Common {

	use Pod::SAX::Iter;

	sub get-pod(Str $source) is export {
		EVAL $source ~ "\n\$=pod";
	}

	sub under-name(@history, $name --> Bool) is export {
		return so @history && @history[*-1] ~~ Pod::Block::Named && @history[*-1].name ~~ $name;
	}

	sub under-type(@history, $type --> Bool) is export {
		return so @history && @history[*-1] ~~ $type;
	}

    sub append(*@a) is export {
        push @*draft, |@a;
    }

	grammar MetaL is export {
		token TOP {
			<scheme>?
			<extern>?
			<intern>?
		}
		token scheme {
			^^ $<type>=['http'|'https'|'file'|'mailto'|'man'|'doc'|'defn'|'issn'|'isbn'] ':'
		}
		token extern {
			$<from-root>=['//']? $<path>=<-['#']>+
		}
		token intern {
			'#' .+
		}
	}

	sub filter-args(Signature $sig,  %args) is export {
		my @param-names = $sig.params.map: *.name.substr(1);
		my %result;
		for %args.keys -> $key {
			%result{$key} = %args{$key} if $key eq any(@param-names);
		}
		return %result;
	}

	sub get-bare-content($pod) is export {
		my @result;
		my PodIterator $iter .= new;
		$iter.init($pod);
		my @pair;
		while (@pair = $iter.get-next).elems > 1 {
			@result.push(@pair[0]) if @pair[1] == 0;
		}
		return @result.join;
	}
}
