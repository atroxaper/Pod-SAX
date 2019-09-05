module Saxopod::Reformator::Common {

	use Saxopod::Reformator::Iter;

	#| Retrieve POD object from source content.
	sub get-pod(Str:D $source) is export {
    use MONKEY-SEE-NO-EVAL;
		EVAL $source ~ "\n\$=pod";
	}

	#|[Check that specified @history has Named pod block with specified name as \
	#| the last its element. The sub is useful in case you want to filter pod
	#| elements.]
	sub under-name(@history, $name --> Bool:D) is export {
		return so @history && @history[*-1] ~~ Pod::Block::Named && @history[*-1].name ~~ $name;
	}

	#|[Check that specified @history has pod block with specified type as \
	#| the last its element. The sub is useful in case you want to filter pod
	#| elements.]
	sub under-type(@history, $type --> Bool:D) is export {
		return so @history && @history[*-1] ~~ $type;
	}

	#| Append specified arguments to Reformator's draft.
  sub append(*@a) is export {
      push @*draft, |@a;
  }

	#| Grammar for links metadata.
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
			$<from-root>=['//']? $<path>=<-[\#]>+
		}
		token intern {
			'#' .+
		}
	}

	sub get-bare-content($pod) is export {
		my @result;
		my PodIterator $iter .= new($pod);
		my @pair;
		while (@pair = $iter.get-next)[0].DEFINITE {
			@result.push(@pair[0]) if @pair[1] == 0;
		}
		return @result.join;
	}

	sub get-attributes($obj where *.defined) is export {
	return $obj.^attributes
		.grep(*.has_accessor)
		.map(*.name.substr: 2)
		.map(-> $name { ($name => $obj."$name"()) })
		.Hash;
	}
}
