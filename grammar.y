%{
    /*

    Daniel Schreiber Guimaraes     -> 1910462
    Marcos Vinicius Araujo Almeida -> 1910869

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
             | FACA ID VEZES cmds FIM
             | SE ID cmds FIM
             | SE ID cmds SENAO cmds FIM 

    O parser ao detectar uma regra, irá adicionar mais um nó em uma lista encadeada,
    uma lista de Elementos, em que cada elemento possui uma Linha. 

    Essa linha é uma estrutura com as seguintes variáveis:
        char *var1 -> nome da primeira variavei da instrucao
        char *var2 -> nome da segunda variavel da instrucao, caso precise
        comando_t comando -> nome do comando

    Após gerar a lista encadeada, o código final é gerado por alguma das funções
    chamadas de "gerarCodidoXXXX", em que "XXXX" é a linguagem escolhida.
    Como a leitura agora é linear, não há problemas como a identação do python (que
    é complicado de fazer com um parser ascendente)
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

    #define LINGUAGEM_C 1
    #define LINGUAGEM_PY 2
    #define LINGUAGEM_JAVA 3
    #define LINGUAGEM_LUA 4
    
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

    /*
        Insere o elemento 'e' no final da lista cujo primeiro
        elemento é o 'lista'.
    */
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

    /*
        Insere o elemento 'e' (e todos os elementos seguintes dele) 
        no inicio da lista cujo primeiro elemento é o 'lista'
    */
    void insereElementoInicio(Elemento *e, Elemento *lista) {
        //andando ate o final do e
        Elemento *ultimo = e;

        while (ultimo->next != NULL) {
            ultimo = ultimo->next;
        }
        e->next = lista;
        lista->prev = e;
    }

    /*
        Exibe cada linha da lista encadeada, para testes
    */
    void exibeLinhas(Elemento *e) {
        while (e != NULL) {
            printf("%d [[%s]] [[%s]]\n", e->linha.comando, e->linha.var1, e->linha.var2);
            e = e->next;
        }
    }

    extern int yylex();
    extern FILE *yyin;      // arquivo de entrada 
    extern int yyparse();   
    FILE *fileC;
    int tipoArquivo;

    void yyerror(const char *s) {
        fprintf(stderr, "%s\n", s);
        exit(errno);
    };

    /*
        Abre o arquivo e salva o FILE na variavel "fileC" global
    */
    void iniciarArquivo() {
        if (tipoArquivo == LINGUAGEM_C) {
            fileC = fopen("resultado.c", "w+");
        } else if (tipoArquivo == LINGUAGEM_PY) {
            fileC = fopen("resultado.py", "w+");
        } else if (tipoArquivo == LINGUAGEM_JAVA) {
            fileC = fopen("resultado.java", "w+");
        } else if (tipoArquivo == LINGUAGEM_LUA) {
            fileC = fopen("resultado.lua", "w+");
        }

        if (fileC == NULL) {
            printf("Erro na criacao do arquivo temporario .c!\n");
            exit(-1);
        }
    }

    /*
        Fecha o arquivo na variavel global "fileC"
    */
    void fecharArquivo() {
        fclose(fileC);
        return;
    }

    /*
        Recebe uma quantidade de tabs, e retorna uma string contendo
        os tabs (exemplo para q=3: "\t\t\t\0")
        Usando para o Python, mas pode ser usado nos outros códigos para
        melhorar o código gerado
    */
    char *criaIdent(int q) {
        char *tabs = (char *) malloc (sizeof(char) * (q+1));
        for (int i = 0 ; i <= q ; i++) {
            tabs[i] = '\t';
        }
        tabs[q] = '\0';
        return tabs;
    }

    /*
        A seguir estao as funcoes que geram o código a partir do primeiro elemento
        da lista encadeada.
        criaCodigoLua
        criaCodigoJava
        criaCodigoPython
        criaCodigoC
    */

    void criaCodigoLua(Elemento *e) {
        iniciarArquivo();
        while (e != NULL) {
            switch (e->linha.comando) {
                case COMANDO_ATRIBUICAO: {
                    fprintf(fileC, "%s = %s\n", e->linha.var1, e->linha.var2);
                    break;
                }
                case COMANDO_ZERA: {
                    fprintf(fileC, "%s = 0\n", e->linha.var1);
                    break;
                }
                case COMANDO_INCREMENTA: {
                    fprintf(fileC, "%s = %s + 1\n", e->linha.var1, e->linha.var1);
                    break;
                }
                case COMANDO_ENQUANTO: {
                    fprintf(fileC, "while %s > 0 do \n", e->linha.var1);
                    break;
                }
                case COMANDO_END: {
                    fprintf(fileC, "end\n"); 
                    break;
                }
                case COMANDO_FINAL: {
                    // var1 eh a lista de variaveis
                    // splitando a lista de strings
                    
                    char *variavel = strtok(e->linha.var1, " ");  // faz um split na lista de variaveis
                    while (variavel != NULL) {
                        fprintf(fileC, "io.write(\"Saida [%s]: \", %s, \"\\n\")", variavel, variavel);  // imprime a saida
                        variavel = strtok(NULL, " ");   // proxima string da lista de variaveis
                    }
                    break;
                }
                case COMANDO_ENTRADA: {
                    // var1 eh a lista de variaveis a serem iniciadas
                    // splitando a lista de strings
                    char *variavel = strtok(e->linha.var1, " ");
                    while (variavel != NULL) {
                        // para cada variavel, sera inicializada e scaneada
                        fprintf(fileC, "local %s\n", variavel);                      // inicia a variavel
                        fprintf(fileC, "io.write(\"Entrada [%s]:\")\n", variavel);   // coloca um print
                        fprintf(fileC, "%s = io.read(\"*number\")\n", variavel);      // coloca um scan
                        
                        variavel = strtok(NULL, " ");   // proxima string da lista de variaveis
                    }

                    // var2 eh a lista de variaveis finais, que devem ser inicializadas
                    variavel = strtok(e->linha.var2, " ");
                    while (variavel != NULL) {
                        // para cada variavel, ela deve ser inicializada
                        fprintf(fileC, "local %s = 0\n", variavel);      // inicia a variavel
                        variavel = strtok(NULL, " ");               // proxima string da lista de variaveis
                    }
                    break;
                }
                case COMANDO_REPETICAO: {
                    fprintf(fileC, "for _i=0,%s do\n", e->linha.var1);
                    break;
                }

                case COMANDO_SE: {
                    fprintf(fileC, "if %s then\n", e->linha.var1);
                    break;
                }

                case COMANDO_SENAO: {
                    fprintf(fileC, "else\n");
                    break;
                }
            }
            e = e->next;
        }
        fecharArquivo();
    }

    void criaCodigoJava(Elemento *e) {
        iniciarArquivo();
        fprintf(fileC, "import java.util.Scanner;\n\n");
        fprintf(fileC, "public class Resultado {\npublic static void main(int argc, String[] argv) {\n");
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
                        fprintf(fileC, "System.out.printf(\"Saida: [%s] = %s\\n\", %s);\n", variavel, "%d", variavel);  // imprime a saida
                        variavel = strtok(NULL, " ");   // proxima string da lista de variaveis
                    }
                    fprintf(fileC, "}\n}\n"); // coloca as ultimas linhas
                    break;
                }
                case COMANDO_ENTRADA: {
                    // var1 eh a lista de variaveis a serem iniciadas
                    // splitando a lista de strings
                    fprintf(fileC, "Scanner _sc = new Scanner(System.in);\n");
                    
                    char *variavel = strtok(e->linha.var1, " ");
                    
                    while (variavel != NULL) {
                        // para cada variavel, sera inicializada e scaneada
                        fprintf(fileC, "System.out.printf(\"Entrada [%s]:\");\n", variavel);   // coloca um print
                        fprintf(fileC, "int %s = _sc.next();\n", variavel);      // coloca um scan
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

    void criaCodigoPython(Elemento *e) {
        iniciarArquivo();
        int tabs = 0;
        while (e != NULL) {
            switch (e->linha.comando) {
                case COMANDO_ATRIBUICAO: {
                    fprintf(fileC, "%s%s=%s\n", criaIdent(tabs), e->linha.var1, e->linha.var2);
                    break;
                }
                case COMANDO_ZERA: {
                    fprintf(fileC, "%s%s = 0\n", criaIdent(tabs), e->linha.var1);
                    break;
                }
                case COMANDO_INCREMENTA: {
                    fprintf(fileC, "%s%s += 1\n", criaIdent(tabs), e->linha.var1);
                    break;
                }
                case COMANDO_ENQUANTO: {
                    fprintf(fileC, "%swhile %s > 0:\n", criaIdent(tabs), e->linha.var1);
                    tabs += 1;
                    break;
                }
                case COMANDO_END: { 
                    tabs -= 1; 
                    break;
                }
                case COMANDO_FINAL: {
                    char *variavel = strtok(e->linha.var1, " ");  // faz um split na lista de variaveis
                    while (variavel != NULL) {
                        fprintf(fileC, "%sprint(\"Saida: [%s] = %s\\n\" %% %s)\n", criaIdent(tabs), variavel, "%d", variavel);  // imprime a saida
                        variavel = strtok(NULL, " ");   // proxima string da lista de variaveis
                    }
                    break;
                }
                case COMANDO_ENTRADA: {
                    char *variavel = strtok(e->linha.var1, " ");
                    while (variavel != NULL) {
                        // para cada variavel, sera inicializada e scaneada
                        fprintf(fileC, "%s%s = int(input(\"Entrada [%s]:\"))\n", criaIdent(tabs), variavel, variavel);   // coloca um print      
                        variavel = strtok(NULL, " ");   // proxima string da lista de variaveis
                    }

                    // var2 eh a lista de variaveis finais, que devem ser inicializadas
                    variavel = strtok(e->linha.var2, " ");
                    while (variavel != NULL) {
                        // para cada variavel, ela deve ser inicializada
                        fprintf(fileC, "%s%s = 0\n", criaIdent(tabs), variavel);      // inicia a variavel
                        variavel = strtok(NULL, " ");               // proxima string da lista de variaveis
                    }
                    break;
                }
                case COMANDO_REPETICAO: {
                    fprintf(fileC, "%sfor _ in range(len(%s)):\n", criaIdent(tabs), e->linha.var1);
                    tabs += 1;
                    break;
                }
                case COMANDO_SE: {
                    fprintf(fileC, "%sif %s > 0:\n", criaIdent(tabs), e->linha.var1);
                    tabs += 1;
                    break;
                }
                case COMANDO_SENAO: {
                    fprintf(fileC, "%selse:\n", criaIdent(tabs-1));
                    break;
                }
            }
            e = e->next;
        }
        fecharArquivo();
    }

    void criaCodigoC(Elemento *e) {
        iniciarArquivo();
        fprintf(fileC, "#include <stdio.h>\nvoid main() {\n");
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
    if (tipoArquivo == LINGUAGEM_C) {
        criaCodigoC(e);
    } else if (tipoArquivo == LINGUAGEM_PY) {
        criaCodigoPython(e);
    } else if (tipoArquivo == LINGUAGEM_JAVA) {
        criaCodigoJava(e);
    } else if (tipoArquivo == LINGUAGEM_LUA) {
        criaCodigoLua(e);
    }
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
    /* faz a leitura dos argumentos */
    if (argc != 2 && argc != 3) {
        printf("Uso correto: %s arquivo.provolone [c/py/java/lua]", argv[0]);
        exit(-1);
    }
    FILE *arquivoInput = fopen(argv[1], "r");
    if (arquivoInput == NULL) {
        printf("Erro abrindo arquivo de leitura!\n");
        exit(-3);
    }
    if (argc == 3 && strcmp(argv[2], "py") == 0) {
        tipoArquivo = LINGUAGEM_PY;
        printf("Linguagem usada: PYTHON\n");
    } else if (argc == 3 && strcmp(argv[2], "java") == 0) {
        tipoArquivo = LINGUAGEM_JAVA;
        printf("Linguagem usada: JAVA\n");
    
    } else if (argc == 3 && strcmp(argv[2], "lua") == 0) {
        tipoArquivo = LINGUAGEM_LUA;
        printf("Linguagem usada: LUA\n");
    } else { 
        printf("Linguagem usada: C\n");
        tipoArquivo = LINGUAGEM_C; 
    }
    
    /* abre o arquivo final para salvar o código */
    iniciarArquivo();

    printf("Executando parser\n");
    yyin = arquivoInput;
    yyparse();

    printf("Finalizando parser\n");
    return 0;
}
