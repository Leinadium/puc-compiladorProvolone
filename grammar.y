%{
    /*
    Gramatica de Provol-One:

    program -> ENTRADA varlist SAIDA varlist cmds FIM
    varlist -> id varlist
             | id
    cmds    -> cmd cmds
             | cmd
    cmd     -> ENQUANTO id FACA cmds FIM
             | id = id
             | INC(id)
             | ZERA(id)
    */

    #define COMANDO_ENTRADA 0
    #define COMANDO_FINAL 1
    #define COMANDO_INCREMENTA 2
    #define COMANDO_ZERA 3
    #define COMANDO_ENQUANTO 4
    #define COMANDO_ATRIBUICAO 5
    #define COMANDO_REPETICAO 6
    #define COMANDO_SE 7
    #define COMANDO_SENAO 8

    #define COMANDO_END 100
    #define comando_t short
    
    #include <stdio.h>
    #include <stdlib.h>
    #include <errno.h>
    #include <string.h>

    struct linha{
        comando_t comando;      // comando principal
        char *var1;             // variavel 1
        char *var2;             // variavel 2
    };
    typedef struct linha Linha;

    typedef struct elemento Elemento;
    struct elemento {
        struct elemento *prev;
        struct elemento *next;
        Linha linha;
    };


    void insereElementoFinal(Elemento *e, Elemento *lista) {
        // andando ate o final
        Elemento *ultimo = lista;
        while (ultimo->next != NULL) {
            ultimo = ultimo->next;
        }
        ultimo->next = e;
        e->prev = ultimo; 
        return;
    }

    Elemento *insereElementoInicio(Elemento *e, Elemento *lista) {
        //andando ate o final do e
        Elemento *ultimo = e;

        while (ultimo->next != NULL) {
            ultimo = ultimo->next;
        }
        e->next = lista;
        lista->prev = e;
    }

    void exibeLinhas(Elemento *e) {
        while (e != NULL) {
            printf("%d [[%s]] [[%s]]\n", e->linha.comando, e->linha.var1, e->linha.var2);
            e = e->next;
        }
    }
    //void iniciarCodigo() {
    //    codigo = (Linha *) malloc (sizeof(Linha));
    //}


    extern int yylex();
    extern FILE *yyin;
    extern int yyparse();

    void yyerror(const char *s) {
        fprintf(stderr, "%s\n", s);
        exit(errno);
    };

    FILE *fileC;

    void iniciarArquivo() {
        fileC = fopen("resultado.c", "w+");
        if (fileC == NULL) {
            printf("Erro na criacao do arquivo temporario .c!\n");
            exit(-1);
        }
        fprintf(fileC, "#include <stdio.h>\nvoid main() {\n");
    }

    void fecharArquivo() {
        // fprintf(fileC, "printf(\"Saida: %s\\n\", saida);\nreturn;\n}\n", "%d");
        fclose(fileC);
        return;
    }

    void criaCodigoC(Elemento *e) {
        iniciarArquivo();
        while (e != NULL) {
            switch (e->linha.comando) {
                case COMANDO_ATRIBUICAO: {
                    fprintf(fileC, "%s = %s;\n", e->linha.var1, e->linha.var2);
                    break;
                }
                case COMANDO_ZERA: {
                    fprintf(fileC, "%s = 0;\n", e->linha.var1);
                    break;
                }
                case COMANDO_INCREMENTA: {
                    fprintf(fileC, "%s++;\n", e->linha.var1);
                    break;
                }
                case COMANDO_ENQUANTO: {
                    fprintf(fileC, "while (%s > 0) {\n", e->linha.var1);
                    break;
                }
                case COMANDO_END: {
                    fprintf(fileC, "}\n"); 
                    break;
                }
                case COMANDO_FINAL: {
                    // var1 eh a lista de variaveis
                    // splitando a lista de strings
                    
                    char *variavel = strtok(e->linha.var1, " ");  // faz um split na lista de variaveis
                    while (variavel != NULL) {
                        fprintf(fileC, "printf(\"Saida: [%s] = %s\\n\", %s);\n", variavel, "%d", variavel);  // imprime a saida
                        variavel = strtok(NULL, " ");   // proxima string da lista de variaveis
                    }
                    fprintf(fileC, "return;}"); // coloca as ultimas linhas
                    break;
                }
                case COMANDO_ENTRADA: {
                    // var1 eh a lista de variaveis a serem iniciadas
                    // splitando a lista de strings
                    char *variavel = strtok(e->linha.var1, " ");
                    while (variavel != NULL) {
                        // para cada variavel, sera inicializada e scaneada
                        fprintf(fileC, "int %s;\n", variavel);                      // inicia a variavel
                        fprintf(fileC, "printf(\"Entrada [%s]:\");\n", variavel);   // coloca um print
                        fprintf(fileC, "scanf(\"%s\",&%s);\n", "%d", variavel);      // coloca um scan
                        
                        variavel = strtok(NULL, " ");   // proxima string da lista de variaveis
                    }

                    // var2 eh a lista de variaveis finais, que devem ser inicializadas
                    variavel = strtok(e->linha.var2, " ");
                    while (variavel != NULL) {
                        // para cada variavel, ela deve ser inicializada
                        fprintf(fileC, "int %s = 0;\n", variavel);      // inicia a variavel
                        variavel = strtok(NULL, " ");               // proxima string da lista de variaveis
                    }
                    break;
                }
                case COMANDO_REPETICAO: {
                    fprintf(fileC, "for (int _i = 0; _i<%s; _i++) {\n", e->linha.var1);
                    break;
                }

                case COMANDO_SE: {
                    fprintf(fileC, "if (%s){ ", e->linha.var1);
                    break;
                }

                case COMANDO_SENAO: {
                    fprintf(fileC, "} else {\n");
                    break;
                }
            }
            e = e->next;
        }
        fecharArquivo();
    }

%}

%token ENTRADA
%token SAIDA
%token FIM
%token ENQUANTO
%token FACA
%token INC
%token ZERA
%token FECHAPAR
%token ABREPAR
%token IGUAL
%token <sval> ID
%token VEZES
%token SE
%token SENAO


%union {
    int ival;
    char *sval;
    struct elemento *eval;
}

%type <ival> program
%type <sval> varlist
%type <eval> cmds
%type <eval> cmd


%start program
%%

program : ENTRADA varlist SAIDA varlist cmds FIM {
    Elemento *e = (Elemento *)malloc(sizeof(Elemento));
    if (e == NULL) {printf("Erro no while!\n");exit(-1);}
    e->linha.var1 = $2;
    e->linha.var2 = $4;
    e->linha.comando = COMANDO_ENTRADA;
    insereElementoInicio(e, $5);

    Elemento *ee = (Elemento *)malloc(sizeof(Elemento));
    if (ee == NULL) {printf("Erro no while!\n");exit(-1);}
    ee->linha.var1 = $4;
    ee->linha.comando = COMANDO_FINAL;
    insereElementoFinal(ee, e);
    
    // exibeLinhas(e);
    criaCodigoC(e);
}
    ;

varlist : varlist ID    {
        char buffer[100];
        snprintf(buffer, 100, "%s %s", $1, $2);
        $$ = buffer;
    }

    | ID            {$$ = $1;}
    ;
        

cmds : cmds cmd         { insereElementoFinal($2, $1); $$ = $1; }
     | cmd              { $$ = $1; }
     ;


cmd : ENQUANTO ID FACA cmds FIM { 
    Elemento *e = (Elemento *)malloc(sizeof(Elemento));
    if (e == NULL) {printf("Erro no while!\n");exit(-1);}

    e->linha.var1 = $2;
    e->linha.comando = COMANDO_ENQUANTO;
    insereElementoFinal($4, e);

    Elemento *ee = (Elemento *)malloc(sizeof(Elemento));
    if (ee == NULL) {printf("Erro no while!\n");exit(-1);}
    
    ee->linha.comando = COMANDO_END;
    insereElementoFinal(ee,e);
    $$ = e;
 }

    | ID IGUAL ID { 
        Elemento *e = (Elemento *)malloc(sizeof(Elemento));
        if (e == NULL) {printf("Erro na atribuicao!\n");exit(-1);}

        e->linha.var1 = $1;
        e->linha.var2 = $3;
        e->linha.comando = COMANDO_ATRIBUICAO;
        $$ = e;
    }

    | INC ABREPAR ID FECHAPAR { 
        Elemento *e = (Elemento *)malloc(sizeof(Elemento));
        if (e == NULL) {printf("Erro na incrementacao!\n");exit(-1);}
        e->linha.var1 = $3;
        e->linha.comando = COMANDO_INCREMENTA;
        $$ = e;
    }

    | ZERA ABREPAR ID FECHAPAR { 
        Elemento *e = (Elemento *)malloc(sizeof(Elemento));
        if (e == NULL) {printf("Erro no zerar!\n");exit(-1);}
        e->linha.var1 = $3;
        e->linha.comando = COMANDO_ZERA;
        $$ = e;
    }

    | FACA ID VEZES cmds FIM {

        Elemento *e = (Elemento *)malloc(sizeof(Elemento));
        if (e == NULL) {printf("Erro no VEZES!\n");exit(-1);}

        e->linha.var1 = $2;
        e->linha.comando = COMANDO_REPETICAO;
        insereElementoFinal($4, e);

        Elemento *ee = (Elemento *)malloc(sizeof(Elemento));
        if (ee == NULL) {printf("Erro no while!\n");exit(-1);}
    
        ee->linha.comando = COMANDO_END;
        insereElementoFinal(ee,e);
        $$ = e;
    }

    | SE ID cmds FIM {
        
        Elemento *e = (Elemento*)malloc(sizeof(Elemento ));
        if (e == NULL) {printf("Erro no VEZES!\n");exit(-1);}
        
        e->linha.comando = COMANDO_SE;
        e->linha.var1 = $2;

        insereElementoFinal($3, e);
        
        Elemento *ee = (Elemento *)malloc(sizeof(Elemento));
        if (ee == NULL) {printf("Erro no while!\n");exit(-1);}
    
        ee->linha.comando = COMANDO_END;
        insereElementoFinal(ee,e);
        $$ = e;
        
    }

    | SE ID cmds SENAO cmds FIM {

        Elemento *e = (Elemento *)malloc(sizeof(Elemento));
        if (e == NULL) {printf("Erro no SE-SENAO!\n");exit(-1);}

        e->linha.var1 = $2;
        e->linha.comando = COMANDO_SE;
        insereElementoFinal($3, e);

        Elemento *ee = (Elemento *)malloc(sizeof(Elemento));
        if (ee == NULL) {printf("Erro no SE-SENAO!\n");exit(-1);}

        ee->linha.comando = COMANDO_SENAO;
        insereElementoFinal(ee, e);
        insereElementoFinal($5, e);

        Elemento *eee = (Elemento *)malloc(sizeof(Elemento));
        if (eee == NULL) {printf("Erro no SE-SENAO!\n");exit(-1);}

        eee->linha.comando = COMANDO_END;
        insereElementoFinal(eee, e);

        $$ = e;
    }
    ;
%%


int main(int argc, char **argv) {
    if (argc != 2) {
        printf("Uso correto: %s arquivo.provolone", argv[0]);
        exit(-1);
    }
    printf("Criando arquivo temporario\n");
    FILE *arquivoInput = fopen(argv[1], "r");
    if (arquivoInput == NULL) {
        printf("Erro abrindo arquivo de leitura!\n");
        exit(-3);
    }
    
    iniciarArquivo();

    printf("Executando parser\n");
    yyin = arquivoInput;
    yyparse();

    printf("Finalizando parser\n");
    fclose(arquivoInput);
    return 0;
}