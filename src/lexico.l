%{
#include "semantico.tab.h"
#include <stdio.h>
#include <stdlib.h>
void error_lexico();

int errores_lexicos = 0;
void error_sobrecarga();
%}

digito              [0-9]
letra               [a-zA-Z]
entero              {digito}+
%option yylineno

%%
[ \n\t]+                            ;
"//"(.*)[\n]                        ;
"/ ∗ "([ˆ∗]|[∗]+[ˆ∗/])∗[∗]+"/" 	    ;
\"([^"\n"]|\\.)*\"                  {yylval.cadena = strdup(yytext); return STRING;}
var                                 {return VAR;}
const                               {return CONST;}
if                                  {return IF;}
else                                {return ELSE;}
while                               {return WHILE;}
print                               {return PRINT;}
read                                {return READ;}
do                                  {return DO;}
">="                                {return MAYIGUAL;}
"<="                                {return MENIGUAL;}
"<"                                 {return MENOR;}
">"                                 {return MAYOR;}
"&"                                 {return AND;}
"|"                                 {return OR;}
"("                                 {return PARI;}		
")"                                 {return PARD;}
";"                                 {return PTCOMA;}
","                                 {return COMA;}
"="                                 {return IGUAL;}
"+"                                 {return MAS;}
"-"                                 {return MENOS;}
"*"                                 {return POR;}
"/"                                 {return DIV;}
"{"                                 {return ALLAVE;}
"}"                                 {return CLLAVE;}

{letra}({letra}|{digito}|_)*        {yylval.cadena = strdup(yytext); return ID;}
{entero}+                           {yylval.entero = atoi(yytext); if ((yylval.entero) >= 2147483648) error_sobrecarga(); return NUM;}
.                                   error_lexico();

%%
//Se llama cuando el número es mayor que 2147483648, en este caso se imprimiría el error
void error_sobrecarga()
{
  errores_lexicos++;
  printf("ERROR léxico, el entero %s de la linea %d no se puede codificar con 32 bits\n", yytext, yylineno);
}
void error_lexico()
{
  errores_lexicos++;
  printf("ERROR léxico del símbolo no reconocido \"%s\" en la línea %d\n", yytext, yylineno);
}