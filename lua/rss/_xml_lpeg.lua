--- from TrollEdit
-- Simple XML grammar
require "lpeg"

-- TODO:
--   improve grammar for attributes
--   possible attribute encoding in header
--   opening and closing symbols of elements - for highlight
--   start and end tags can be different at the moment...

-- important fields for Analyzer class
extensions = { "xml" }
language = "XML"
full_grammar = "document"
other_grammars = {
   markup_element = "in_markup_element",
}
paired = { "<", ">", "start_element", "end_element" }
selectable = { "document", "xml_header", "markup_element", "attribute", "block", "unknown", "unknown_word" }
multi_text = { "multiline_comment", "unknown" }
floating = { "multiline_comment" }

-- does language support multiline comments?
multiline_support = "true"

-- start & end tokens for comments; if language does not support multiline comments, define custom tokens
line_tokens = {}
multiline_tokens = { "<!--", "-->" }

require "lpeg"

--patterns
local P, R, S, V = lpeg.P, lpeg.R, lpeg.S, lpeg.V
--captures
local C, Ct, Cc = lpeg.C, lpeg.Ct, lpeg.Cc

-- nonterminal, general node
function N(arg)
   return Ct(Cc(arg) * V(arg))
end

-- nonterminal, ignored in tree
function NI(arg)
   return V(arg)
end

-- terminal, text node
function T(arg)
   return N "whites" ^ -1 * TP(arg) * N "nl" ^ 0
end

-- terminal, plain node without comments or whitespaces
function TP(arg)
   return Ct(C(arg))
end

-- ***  GRAMMAR  ****
local grammar = {
   "S",

   -- ENTRY POINTS
   document = Ct(Cc "document" * (N "multiline_comment" + N "nl") ^ 0 * N "xml_header" ^ -1 * N "markup_element" ^ -1 *
   N "unknown" ^ 0 * N "whites" ^ -1 * -1),

   in_markup_element = Ct(N "nl" ^ 0 * (N "word" ^ 1 + N "markup_element" ^ 0) * N "unknown" ^ 0 * N "whites" ^ -1 * -1),

   -- NONTERMINALS
   xml_header = T "<?xml" * (T "version=" * N "version_number") ^ -1 * (T "encoding=" * N "attribute_value") ^ -1 *
   T "?>" * (N "multiline_comment") ^ 0,
   version_number = T '"' * NI "number" * T "." * NI "number" * T '"',
   markup_element = N "empty_element" * (N "multiline_comment") ^ 0 +
   N "start_element" * (N "multiline_comment") ^ 0 * N "block" ^ -1 * N "end_element" * (N "multiline_comment") ^ 0,
   block = N "word" ^ 1 + N "markup_element" ^ 1,
   start_element = T "<" * N "markup_tag" * N "attribute" ^ 0 * T ">",
   end_element = T "</" * N "markup_tag" * T ">",
   empty_element = T "<" * N "markup_tag" * N "attribute" ^ 0 * T "/>",
   attribute = N "attribute_key" * T "=" * N "attribute_value",
   attribute_key = NI "attribute_word",
   attribute_value = T '"' * NI "attribute_word" ^ 1 * T '"',

   -- TERMINALS
   markup_tag = T((NI "letter" + S "_:") * NI "markup_tag_char" ^ 0),
   word = T(NI "char" ^ 1),
   number = T(NI "digit" ^ 1),
   attribute_word = T((P(1) - S '="<>/') ^ 1),
   multiline_comment = T(P "<!--" * (1 - P "-->") ^ 0 * P "-->"),

   -- LITERALS
   unknown = N "unknown_word" ^ 1 * N "nl" ^ 0, -- anything divided to words
   unknown_word = N "whites" ^ -1 * TP((1 - S " \t\r\n") ^ 1),

   whites = TP(S " \t" ^ 1),                    -- spaces and tabs
   nl = S " \t" ^ 0 * TP(P "\r" ^ -1 * P "\n"), -- single newline, preceding spaces are ignored

   letter = R("az", "AZ"),
   digit = R "09",
   char = P(1) - S "<>/ \t\r\n",
   markup_tag_char = NI "letter" + NI "digit" + S ".-_:",
}
-- ***  END OF GRAMMAR  ****

-- *** POSSIBLE GRAMMARS (ENTRY POINTS) ****
grammar[1] = "document"
document = P(grammar)
grammar[1] = "in_markup_element"
in_markup_element = P(grammar)

--*******************************************************************
-- TESTING - this script cannot be used by Analyzer.cpp when these lines are uncommented !!!

-- dofile('default_grammar.lua')
-- test("../../input/carcassonne.xml", document)
