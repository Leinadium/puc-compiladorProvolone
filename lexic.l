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
VEZES       return (VEZES);
SE          return (SE);
SENAO       return (SENAO);
"("         return (ABREPAR);
")"         return (FECHAPAR);
"="         return (IGUAL);
[a-zA-Z]    {yylval.sval =strdup(yytext); return (ID);}
[ /t]       {}
