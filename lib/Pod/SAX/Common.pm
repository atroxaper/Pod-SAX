module Pod::SAX::Common {

	sub get-pod(Str $source) is export {
		EVAL $source ~ "\n\$=pod";
	}

	sub under-name(@history, $name --> Bool) is export {
		return so @history && @history[*-1] ~~ Pod::Block::Named && @history[*-1].name ~~ $name;
	}

	sub under-type(@history, $type --> Bool) is export {
		return so @history && @history[*-1] ~~ $type;
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

	sub filter-args($sub,  %args) is export {
		my @param-names = $sub.signature.params.map: *.name.substr(1);
		my %result;
		for %args.keys -> $key {
			%result{$key} = %args{$key} if $key eq any(@param-names);
		}
		return %result;
	}
}