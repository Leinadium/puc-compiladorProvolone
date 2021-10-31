# Compilador para linguagem Provol-One

Compilador baseado em Yacc/Lex para compilar um arquivo escrito na linguagem Provol-One 
em um arquivo em C.

Criado para o trabalho final da disciplina INF1022 - Analisadores Léxicos e Sintáticos,
do semestre 2021.1, PUC-RIO.

## Linguagem

A linguagem Provol-One possui a seguinte gramática:

* *program* -> ENTRADA *varlist* SAIDA *varlist* *cmds* FIM
* *varlist* -> ID *varlist*
* *varlist* -> ID
* *cmds* -> *cmds* cmd
* *cmds* -> *cmd*
* *cmd* -> ENQUANTO ID FACA *cmds* FIM
* *cmd* -> ID = ID
* *cmd* -> INC(ID)
* *cmd* -> ZERA(ID)
* *cmd* -> FACA ID VEZES *cmds* FIM
* *cmd* -> SE ID *cmds* FIM
* *cmd* -> SE ID *cmds* SENAO *cmds* FIM

## Requerimentos

Para poder gerar o compilador, é preciso utilizar o *Bison* e *Flex* :

```shell
sudo apt-get install bison flex
```

## Execução

O compilador pode ser gerado através do script ```executar.sh```. Porém, ele também pode ser gerado manualmente:

```shell
yacc -d grammar.y
lex lexic.l
gcc -c lex.yy.c y.tab.c
gcc -o compilador lex.yy.o y.tab.o -ll
```

O compilador precisa de um parâmetro, o nome do arquivo da linguagem *Provol-One*

Também é possível escolher qual linguagem o compilador deve gerar. As linguagens possíveis são:

* C
* Python
* Java
* Lua

Para isso, basta passar um segundo parâmetro, no formato *c/py/lua/java*

Exemplo:

```shell
./compilador teste.provolone java
./compilador meu_arquivo.txt py
./compilador meu_outro_arquivo.txt  (sera gerado um programa em C)
```

## Autores

* Daniel Guimaraes
* Marcos Vinicius Araujo Almeida
