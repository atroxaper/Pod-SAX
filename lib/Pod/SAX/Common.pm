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
}