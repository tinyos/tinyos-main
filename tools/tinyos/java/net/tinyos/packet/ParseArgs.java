    /**
     * Parse a string into tokens based on a sequence of delimiters
     * Given delimiters (single characters) d1, d2, ..., dn, this
     * class recognises strings of the form s0[d1s1][d2s2]...[dnsn],
     * where s<i-1> does not contain character di
     * This is unambiguous if all di are distinct. If not, strings
     * are attributed to the earliest possible si (so if the delimiters
     * are : and :, and the input string is foo:bar, then s0 is foo,
     * s1 is bar and s2 is null
     */
package net.tinyos.packet;

class ParseArgs {
	String tokens[];
	int tokenIndex;

	ParseArgs(String s, String delimiterSequence) {
	    int count = delimiterSequence.length();
	    tokens = new String[count + 1];
	    tokenIndex = 0;

	    // Fill in the tokens
	    int i = 0, lastMatch = 0;
	    while (i < count) {
		int pos = s.indexOf(delimiterSequence.charAt(i++));

		if (pos >= 0) {
		    // When we finally find a delimiter, we know where
		    // the last token ended
		    tokens[lastMatch] = s.substring(0, pos);
		    lastMatch = i;
		    s = s.substring(pos + 1);
		}
	    }
	    tokens[lastMatch] = s;
	}

	String next() {
	    return tokens[tokenIndex++];
	}
}
