%option yywrap
    /*
        Compilador de Provol-One
    */ 
    #include <stdio.h>
    #include "y.tab.h"
%%

ENTRADA     return (ENTRADA);
SAIDA       return (SAIDA);
FACA        return (FACA);
INC         return (INC);
ZERA        return (ZERA);
ENQUANTO    return (ENQUANTO);
FIM         return (FIM);
"("         return (ABREPAR);
")"         return (FECHAPAR);
"="         return (IGUAL);
[a-zA-Z][a-zA-Z0-9]*  {yylval.sval = yytext; return (ID);}
