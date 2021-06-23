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

    #include <stdio.h>
    #include <stdlib.h>
    #include <math.h>

    extern int yylex();
    extern FILE *yyin;
    extern int yyparse();

    void yyerror(const char *s) {
        fprintf(stderr, "%s\n", s);
    };
    void texto(char *palavra) {
        printf("%s\n", palavra);
    }

    void print(char *text) {
        printf("%s\n", text);
    }

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
        // a variavel de saida eh sempre "int saida";
        fprintf(fileC, "printf(\"Saida: %s\\n\", saida);\nreturn;\n}\n", "%d");
        fclose(fileC);
        return;
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

%union {
    int ival;
    char *sval;
}

%type <ival> program
%type <sval> varlist
%type <ival> cmds
%type <ival> cmd


%start program
%%

program : ENTRADA varlist SAIDA varlist cmds FIM {
    printf("executando program\n");
    fprintf(fileC, "\nint saida = %s;\n", $4);
    fecharArquivo();

}
        ;

varlist : varlist ID    {printf("Executando varlist1\n"); fprintf(fileC, "int %s = 0;\n", $2); $$=$2;}
        | ID            {printf("Executando varlist2\n"); fprintf(fileC, "int %s = 0;\n", $1); $$=$1;}
        ;
        

cmds : cmds cmd         {printf("Executando cmds1\n"); }
     | cmd              {printf("Executando cmds2\n"); }
     ;


cmd : ENQUANTO ID FACA cmds FIM     { printf("Executando cmd1\n"); fprintf(fileC, "while (%s > 0) {\n$4\n}\n", $2); }
    | ID IGUAL ID                   { printf("Executando cmd2\n"); fprintf(fileC, "%s = %s;\n", $1, $3); }
    | INC ABREPAR ID FECHAPAR       { printf("Executando cmd3\n"); fprintf(fileC, "%s++;\n", $3); }
    | ZERA ABREPAR ID FECHAPAR      { printf("Executando cmd4\n"); fprintf(fileC, "%s = 0;\n", $3); }
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