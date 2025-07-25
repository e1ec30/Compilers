/*
 *  cool.y
 *              Parser definition for the COOL language.
 *
 */
%{
#include <iostream>
#include "cool-tree.h"
#include "stringtab.h"
#include "utilities.h"

/* Add your own C declarations here */


/************************************************************************/
/*                DONT CHANGE ANYTHING IN THIS SECTION                  */

extern int yylex();           /* the entry point to the lexer  */
extern int curr_lineno;
extern char *curr_filename;
Program ast_root;            /* the result of the parse  */
Classes parse_results;       /* for use in semantic analysis */
int omerrs = 0;              /* number of errors in lexing and parsing */

/*
   The parser will always call the yyerror function when it encounters a parse
   error. The given yyerror implementation (see below) justs prints out the
   location in the file where the error was found. You should not change the
   error message of yyerror, since it will be used for grading puproses.
*/
void yyerror(const char *s);

/*
   The VERBOSE_ERRORS flag can be used in order to provide more detailed error
   messages. You can use the flag like this:

     if (VERBOSE_ERRORS)
       fprintf(stderr, "semicolon missing from end of declaration of class\n");

   By default the flag is set to 0. If you want to set it to 1 and see your
   verbose error messages, invoke your parser with the -v flag.

   You should try to provide accurate and detailed error messages. A small part
   of your grade will be for good quality error messages.
*/
extern int VERBOSE_ERRORS;

%}

/* A union of all the types that can be the result of parsing actions. */
%union {
  Boolean boolean;
  Symbol symbol;
  Program program;
  Class_ class_;
  Classes classes;
  Feature feature;
  Features features;
  Formal formal;
  Formals formals;
  Case case_;
  Cases cases;
  Expression expression;
  Expressions expressions;
  char *error_msg;
}

/* 
   Declare the terminals; a few have types for associated lexemes.
   The token ERROR is never used in the parser; thus, it is a parse
   error when the lexer returns it.

   The integer following token declaration is the numeric constant used
   to represent that token internally.  Typically, Bison generates these
   on its own, but we give explicit numbers to prevent version parity
   problems (bison 1.25 and earlier start at 258, later versions -- at
   257)
*/
%token CLASS 258 ELSE 259 FI 260 IF 261 IN 262 
%token INHERITS 263 LET 264 LOOP 265 POOL 266 THEN 267 WHILE 268
%token CASE 269 ESAC 270 OF 271 DARROW 272 NEW 273 ISVOID 274
%token <symbol>  STR_CONST 275 INT_CONST 276 
%token <boolean> BOOL_CONST 277
%token <symbol>  TYPEID 278 OBJECTID 279 
%token ASSIGN 280 NOT 281 LE 282 ERROR 283

/*  DON'T CHANGE ANYTHING ABOVE THIS LINE, OR YOUR PARSER WONT WORK       */
/**************************************************************************/
 
   /* Complete the nonterminal list below, giving a type for the semantic
      value of each non terminal. (See section 3.6 in the bison 
      documentation for details). */

/* Declare types for the grammar's non-terminals. */
%type <program> program
%type <classes> class_list
%type <class_> class

/* You will want to change the following line. */
%type <features> feature_list
%type <feature> feature
%type <expression> expr let_construct_inner
%type <expressions> expr_list_semi actuals
%type <formal> formal
%type <formals> formal_list
%type <case_> branch
%type <cases> branch_list

/* Precedence declarations go here. */
%right ASSIGN
%left NOT
%precedence LET
%nonassoc LE '<' '='
%left '+' '-'
%left '*' '/'
%left ISVOID
%left '~'
%left '@'
%left '.'

%%
/* 
   Save the root of the abstract syntax tree in a global variable.
*/
program : class_list { ast_root = program($1); }
        ;

class_list
        : class            /* single class */
                { $$ = single_Classes($1); }
        | class_list class /* several classes */
                { $$ = append_Classes($1,single_Classes($2)); }
        | class_list error
        ;

/* If no parent is specified, the class inherits from the Object class. */
class  : CLASS TYPEID '{' feature_list '}' ';'
                { $$ = class_($2,idtable.add_string("Object"),$4,
                              stringtable.add_string(curr_filename)); }
        | CLASS TYPEID INHERITS TYPEID '{' feature_list '}' ';'
                { $$ = class_($2,$4,$6,stringtable.add_string(curr_filename)); }
        ;

/* Feature list may be empty, but no empty features in list. */
feature_list: { $$ = nil_Features(); }
        | feature_list feature ';' { $$ = append_Features($1, single_Features($2)); } /* Or a list of them */
        | feature_list error
        ;
/* What's a feature */
feature: OBJECTID ':' TYPEID { $$ = attr($1, $3, no_expr()); } /* An attribute without an initializer*/
        | OBJECTID ':' TYPEID ASSIGN expr { $$ = attr($1, $3, $5); } /* Or an attribute with an initializing expression */
        | OBJECTID '(' formal_list ')' ':' TYPEID '{' expr '}' { $$ = method($1, $3, $6, $8); } /* Or a method */
        ;

/* What's an expression */
/* FIXME: LET construct rule rule is incorrect. Currently only works with one binding */
expr: INT_CONST { $$ = int_const($1); }; /* Could be an int by itself */
        | BOOL_CONST { $$ = bool_const($1); } /* Just a boolean */
        | STR_CONST { $$ = string_const($1); } /* Just a string */
        | OBJECTID { $$ = object($1); } /* Just an object */
        | NEW TYPEID { $$ = new_($2); } /* New expression */
        | expr '+' expr { $$ = plus($1, $3); } /* Addition */
        | expr '-' expr { $$ = sub($1, $3); } /* Subtraction */
        | expr '*' expr { $$ = mul($1, $3); } /* Multiplication */
        | expr '/' expr { $$ = divide($1, $3); } /* Division */
        | ISVOID expr { $$ = isvoid($2); } /* isvoid expr */
        | expr '<' expr { $$ = lt($1, $3); } /* less than */
        | expr '=' expr { $$ = eq($1, $3); } /* equal to */
        | expr LE expr { $$ = leq($1, $3); } /* less than equal to */
        | OBJECTID ASSIGN expr { $$ = assign($1, $3); } /* An Assignment */
        | '~' expr { $$ = neg($2); } /* Complement */
        | NOT expr { $$ = comp($2); } /* Negation */
        | '(' expr ')' { $$ = $2; } /* An expression wrapped in parens */
        | '{' expr_list_semi '}' { $$ = block($2); } /* a block */
        | WHILE expr LOOP expr POOL { $$ = loop($2, $4); } /* while */
        | IF expr THEN expr ELSE expr FI { $$ = cond($2, $4, $6); } /* if then else */
        | OBJECTID '(' actuals ')' { $$ = dispatch(object(idtable.add_string("self")), $1, $3); } /* id(e, e, ..., e) */
        | expr '.' OBJECTID '(' actuals ')' { $$ = dispatch($1, $3, $5); } /* <expr>.id(e, e, ..., e) */
        | expr '@' TYPEID '.' OBJECTID '(' actuals ')' { $$ = static_dispatch($1, $3, $5, $7); } /* <expr>@<type>.id(e, ..., e) */
        | CASE expr OF branch_list ESAC { $$ = typcase($2, $4); } /* case expr of [[ID : TYPE => expr; ]]+esac */
        // | LET OBJECTID ':' TYPEID ASSIGN expr IN expr {$$ = let($2, $4, $6, $8); } %prec LET/* let with initializer */
        // | LET OBJECTID ':' TYPEID IN expr {$$ = let($2, $4, no_expr(), $6); } %prec LET/* let without initializer */
        // | LET error IN expr %prec LET {}
        | LET let_construct_inner { $$ = $2; }
        | LET error let_construct_inner { }
        ;




/* A ';' delimited list of expressions */
expr_list_semi: expr ';' { $$ = single_Expressions($1); }
        | expr_list_semi expr ';' { $$ = append_Expressions($1, single_Expressions($2)); }
        | expr_list_semi error

/* Comma separated list of exprs for dispatch's */
actuals: /* empty */ { $$ = nil_Expressions(); }
        | expr { $$ = single_Expressions($1); }
        | actuals ',' expr { $$ = append_Expressions($1, single_Expressions($3)); }

formal: OBJECTID ':' TYPEID { $$ = formal($1, $3); }

formal_list: { $$ = nil_Formals(); }
        | formal { $$ = single_Formals($1); }
        | formal_list ',' formal { $$ = append_Formals($1, single_Formals($3)); }

branch: OBJECTID ':' TYPEID DARROW expr ';' { $$ = branch($1, $3, $5); }

branch_list: branch { $$ = single_Cases($1); }
        | branch_list branch { $$ = append_Cases($1, single_Cases($2)); }

let_construct_inner: OBJECTID ':' TYPEID IN expr  %prec LET { $$ = let($1, $3, no_expr(), $5); }
        | OBJECTID ':' TYPEID ASSIGN expr IN expr %prec LET { $$ = let($1, $3, $5, $7); }
        | OBJECTID ':' TYPEID ',' let_construct_inner %prec LET { $$ = let($1, $3, no_expr(), $5); }
        | OBJECTID ':' TYPEID ASSIGN expr ',' let_construct_inner %prec LET { $$ = let($1, $3, $5, $7); }
/* end of grammar */
%%

/* This function is called automatically when Bison detects a parse error. */
void yyerror(const char *s)
{
  cerr << "\"" << curr_filename << "\", line " << curr_lineno << ": " \
    << s << " at or near ";
  print_cool_token(yychar);
  cerr << endl;
  omerrs++;

  if(omerrs>20) {
      if (VERBOSE_ERRORS)
         fprintf(stderr, "More than 20 errors\n");
      exit(1);
  }
}

