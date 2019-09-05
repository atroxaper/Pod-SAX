Pod::SAX
========

System for making Pod::To::Something converters

## Pod::SAX::Goes::HTML

System that uses Pod::SAX to reform Pod objects to HTML representation.
On work currently. You can see example of the module's work at http://atroxaper.github.io/Pod-SAX/. This is the part of S26.

### Current highlighted features

* Most part of L<>
* Case then we have D<> (or D<|;>) and corresponding L<defn:>
* Formatting B<> R<> I<> C<>
* Code blocks with formatting
* Tables
* Table of contents

### Known issues

* Pod::SAX::Goes::HTML can throw SIGSEGV on Rakudo Parrot
* =output blocks work not so good because current Grammar parses it not good enough
* We can't use formatting inside tables - Grammar issues