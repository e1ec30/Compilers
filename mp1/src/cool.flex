/*
 *  The scanner definition for COOL.
 */

/*
 *  Stuff enclosed in %{ %} in the first section is copied verbatim to the
 *  output, so headers and global definitions are placed here to be visible
 * to the code in the file.  Don't remove anything that was here initially
 */
%{
#include <cool-parse.h>
#include <stringtab.h>
#include <utilities.h>
#include <math.h>
#include <ctype.h>
#include <string>

/* The compiler assumes these identifiers. */
#define yylval cool_yylval
#define yylex  cool_yylex

/* Max size of string constants */
#define MAX_STR_CONST 1025
#define YY_NO_UNPUT   /* keep g++ happy */

extern FILE *fin; /* we read from this file */

/* define YY_INPUT so we read from the FILE fin:
 * This change makes it possible to use this scanner in
 * the Cool compiler.
 */
#undef YY_INPUT
#define YY_INPUT(buf,result,max_size) \
  if ( (result = fread( (char*)buf, sizeof(char), max_size, fin)) < 0) \
    YY_FATAL_ERROR( "read() in flex scanner failed");

char string_buf[MAX_STR_CONST]; /* to assemble string constants */
char *string_buf_ptr;

extern int curr_lineno;

extern YYSTYPE cool_yylval;
int consume_comment();

IntTable *nums = new IntTable();
StrTable *strs = new StrTable();
IdTable *ids = new IdTable();



/*
 *  Add Your own definitions here
 */

%}

%option noyywrap

/*
 * Define names for regular expressions here.
 */

digit       [0-9]
upper       [A-Z]
lower       [a-z]
identifier  [a-zA-Z][a-zA-Z0-9_]*

%%

 /*
  * Define regular expressions for the tokens of COOL here. Make sure, you
  * handle correctly special cases, like:
  *   - Nested comments
  *   - String constants: They use C like systax and can contain escape
  *     sequences. Escape sequence \c is accepted for all characters c. Except
  *     for \n \t \b \f, the result is c.
  *   - Keywords: They are case-insensitive except for the values true and
  *     false, which must begin with a lower-case letter.
  *   - Multiple-character operators (like <-): The scanner should produce a
  *     single token for every such operator.
  *   - Line counting: You should keep the global variable curr_lineno updated
  *     with the correct line number
  */

(?i:class) {
					return CLASS;
}
(?i:else) {
					return ELSE;
}
(?i:fi) {
					return FI;
}
(?i:if) {
					return IF;
}
(?i:in) {
					return IN;
}
(?i:inherits) {
					return INHERITS;
}
(?i:let) {
					return LET;
}
(?i:loop) {
					return LOOP;
}
(?i:pool) {
					return POOL;
}
(?i:then) {
					return THEN;
}
(?i:while) {
					return WHILE;
}
(?i:case) {
					return CASE;
}
(?i:esac) {
					return ESAC;
}
(?i:of) {
					return OF;
}
(?i:new) {
					return NEW;
}
(?i:isvoid) {
					return ISVOID;
}
(?i:not) {
					return NOT;
}

t(?i:rue) {
        cool_yylval.boolean = 1;
        return BOOL_CONST;
}

f(?i:alse) {
        cool_yylval.boolean = 0;
        return BOOL_CONST;
}

"<=" {
    return LE;
}

"=>" {
    return DARROW;
}

"<-" {
    return ASSIGN;
}

\(\* {
        if (consume_comment())
            return ERROR;
}

--.* //{printf("Single line comment: %s\n", yytext);}

"+"|"/"|"-"|"*"|"="|"<"|"."|"~"|","|";"|":"|"("|")"|"@"|"{"|"}" {
    return (int)(*yytext);
}



({identifier}|self|SELF_TYPE) {
        cool_yylval.symbol = ids->add_string(yytext);
        if (isupper(*yytext))
            return TYPEID; // Types start with an uppercase letter
        else
            return OBJECTID;
}

{digit}+ {
          cool_yylval.symbol = nums->add_string(yytext);
          return INT_CONST;
}

\" {
    std::string s;
    int c;
    for (;;) {
        while((c = yyinput()) && c != '"' && c != 0x0 && c != EOF && c != '\n')
        {
            if (c == '\\') // Handle escapes
            {
                c = yyinput();
                if (c == 0x00) break;
                switch(c)
                {
                    case 'f': {s.push_back('\f'); break;}
                    case 't': {s.push_back('\t'); break;}
                    case 'n': {s.push_back('\n'); break;}
                    case 'b': {s.push_back('\b'); break;}
                    default : {s.push_back(c); break;} 
                }
            }
            else
            {
                s.push_back(c); // Otherwise copy into s
            }
        }
        if (c == '"') //End of String
        {
            //add s to stringTable
            cool_yylval.symbol = strs->add_string(s.c_str());
            return STR_CONST;
        }
        if (c == 0x00 || c == EOF)
        {
            cool_yylval.error_msg = "Unterminated String";
            return ERROR;
        }
        if (c == '\n')
        {
            cool_yylval.error_msg = "Unescaped newline";
            return ERROR;
        }
    }
}

\n curr_lineno++;
[ \t\f\r\v]+
. {
    cool_yylval.error_msg = strdup(yytext);
    return ERROR;
}
%%

int consume_comment() {
    int c;
    for (;;) {
        while ((c = yyinput()) != '*' && c != 0x0 && c != EOF) // Is 0x0 the new EOF??
        {
            if (c == '\n') curr_lineno++;
            if (c == '(')
            {
                c = yyinput();
                if (c == '\n') curr_lineno++;
                if (c == '*')
                {
                    consume_comment();
                }
            }
            // Eat up all the comment
        }
        if (c == '*')
        {
            while ((c = yyinput()) == '*')
                ; // all the asterisks
            if (c == ')')
                break; // Found the closing
            if (c == '\n') curr_lineno++;
        }
        if (c == 0x0 || c == EOF)
        {
            cool_yylval.error_msg = "EOF in comment";
            return ERROR;
        }
    }
    return 0x0;
}
