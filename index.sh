#!/bin/bash

# Função de montagem do menu
Menu (){
clear
cat << !
--------------------------------------------------------------------------
	Menu de Usuario
1 - Carregar arquivo de log

2 - Número de sites diferentes acessados por cada cliente IP

3 - Número total de dados transferidos por cada cliente

4 - Percentual de sites encontrados na cache e de sites trazidos diretamente da internet

5 - Lista de sites com acesso negado para cada cliente

6 - Lista de sites acessados por um cliente em um determinado dia

7 - Lista de quantitativos, por conteúdo, dos sites acessados por um dado cliente

8 - Gerar Relatorio para $1 (RELATORIO.txt)

9 - Sair

Digite sua Opcao :

--------------------------------------------------------------------------
!
}

SubMenuItem() {
clear
cat << !
--------------------------------------------------------------------------
1 - Listar por IP

2 - Listar para todos os clientes IP

Sair - Qualquer outra tecla

Digite sua Opcao:
--------------------------------------------------------------------------
!
}

# FUNÇÃO RESPONSAVEL POR MONTAR UM ARQUIVO COM TODOS OS IPs DO ARQUIVO DE LOG (SEM REPETIÇÕES)
FoundIPs() {
	# BUSCA TODOS OS IPS (SEM REPETIÇÕES) CONTIDOS NO ARQUIVO DE LOG  E SALVA EM UM ARQUIVO AUXILIAR CHAMADO IPs.txt
	`cat $1 | awk -F ' ' '{print $3}' | sort | uniq > IPs.txt`
}

#################
# PRIMEIRO ITEM #
#################

NumSitesDifIp() { # PARAMETROS QUE DEVEM SER PASSADOS $1 - ENDEREÇO DO ARQUIVO(NOME) | $2 - IP BUSCADO
	# RETORNA PARA A VARIAVEL $numberSites O NUMERO DE SITES DIFERENTES ACESSADOS POR UM IP BUSCADO
	numberSites=`cat $1 | grep $2 | egrep -v "TCP_DENIED" | awk -F ' ' '{print $7}' | sort | uniq | wc -l`

	echo "$2 - $numberSites sites" # ESCREVE O IP PASSADO PARA A BUSCA SEGUIDO DO NUMERO DE SITES DIFERENTES QUE FORAM ACESSADOS POR ESTE IP
}

SearchNumSitesDifIP() { # RECEBE COMO PARAMETRO O ENDEREÇO/NOME DO ARQUIVO ONDE SERÁ EFETUADA A PESQUISA
	read -p "Digite o IP desejado: " searchIp # LER O IP PARA O QUAL SE DESEJA SABER O NUMERO DE SITES DIFERENTES ACESSADOS
	msg="******************\nSites diferentes por IP\n$(NumSitesDifIp $1 $searchIp)"

	echo -e "$msg" #IMPRIME A MENSAGEM COM O VALOR DE SITES DIFERENTES ACESSADOS POR UM CLIENTE NO CONSOLE
}

SearchNumSitesDifTodosIP() { # RECEBE COMO PARAMETRO O ENDEREÇO/NOME DO ARQUIVO ONDE SERÁ EFETUADA A PESQUISA
	FoundIPs $1 # CRIA ARQUIVO IPs.txt COM TODOS OS IPs CONTIDOS NO ARQUIVO

	msg="******************\nSites diferentes por IP"
	while read IP
	do
		msg+="\n$(NumSitesDifIp $1 $IP)"
	done < IPs.txt
	rm IPs.txt # REMOVE O ARQUIVO DE TEXTO COM A LISTAGEM DOS IPS

	echo -e "$msg" #IMPRIME A MENSAGEM COM O VALOR DE SITES DIFERENTES ACESSADOS POR UM CLIENTE NO CONSOLE
}

# FUNÇÃO RESPONSAVEL POR LISTAR O NUMERO DE SITES DIFERENTES ACESSADOS POR CADA CLIENTE IP
NumSitesDif() { # RECEBE COMO PARAMETRO O NOME/ENDEREÇO DO ARQUIVO ONDE SERÃO EFETUADAS AS PESQUISAS
	SubMenuItem
	tput cup 7 19 ; read opt
	
	case $opt in
		1) clear
		   SearchNumSitesDifIP $1 ;;
		2) clear
		   SearchNumSitesDifTodosIP $1 ;;
		*) clear ;;
	esac
}

#################
# SEGUNDO  ITEM #
#################
TotalBytesPorIP() { # RECEBE COMO PARAMETRO O ENDEREÇO/NOME DO ARQUIVO ONDE SERÁ EFETUADA A PESQUISA E O VALOR CORRESPONDENTE AO IP BUSCADO
	totalBytes=`cat $1 | grep $2 | awk -F ' ' 'BEGIN{total = 0}{total+=$5}END{print total}'`

	echo "$2 - $totalBytes bytes" # IMPRIME O TOTAL DE BYTES TRANSFERIDOS POR UM IP BUSCADO
}

SearchTotalBytesIP() { # RECEBE COMO PARAMETRO O ENDEREÇO/NOME DO ARQUIVO ONDE SERÁ EFETUADA A PESQUISA
	read -p "Digite o IP desejado: " searchIp # LER O IP PARA O QUAL SE DESEJA SABER O NUMERO DE SITES DIFERENTES ACESSADOS

	msg="******************\nTotal de bytes transferidos por IP\n$(TotalBytesPorIP $1 $searchIp)"

	echo -e "$msg" #IMPRIME A MENSAGEM COM O VALOR DE SITES DIFERENTES ACESSADOS POR UM CLIENTE NO CONSOLE
}

SearchTotalBytesTodosIP() {
	FoundIPs $1 # CRIA ARQUIVO IPs.txt COM TODOS OS IPs CONTIDOS NO ARQUIVO

	msg="******************\nTotal de bytes transferidos por IP"
	
	while read IP
	do
		msg+="\n$(TotalBytesPorIP $1 $IP)"
	done < IPs.txt
	echo -e "$msg" #IMPRIME A MENSAGEM COM O VALOR DE SITES DIFERENTES ACESSADOS POR UM CLIENTE NO CONSOLE
}

TotalBytes() {
	SubMenuItem
	tput cup 7 19 ; read opt

	case $opt in
		1) clear
		   SearchTotalBytesIP $1 ;;
		2) clear
		   SearchTotalBytesTodosIP $1 ;;
		*) clear ;;
	esac
}

#################
# TERCEIRO ITEM # (TEM UM ERRO NO TRUNCAMENTO DO VALOR)
#################
PctSitesCacheAndDirect() { # RECEBE COMO PARAMETRO O ENDEREÇO/NOME DO ARQUIVO ONDE SERÁ EFETUADA A PESQUISA
	numberHit=`cat $1 | awk -F ' ' '{print $4}' | egrep 'TCP_HIT' | wc -l`
	numberMiss=`cat $1 | awk -F ' ' '{print $4}' | egrep 'TCP_MISS' | wc -l`
	totalHitMiss=`echo "scale=0 ; $numberHit + $numberMiss" | bc`
	
	pctHit=`echo "scale=2 ; ($numberHit * 100) / $totalHitMiss" | bc | awk '{$1=sprintf("%.0f", $1); print $1}'`
	pctMiss=`echo "scale=2 ; ($numberMiss * 100) / $totalHitMiss" | bc | awk '{$1=sprintf("%.0f", $1); print $1}'`

	echo -e "******************\nPercentual de sites na cache e de acesso direto\nCache: $pctHit%\nDireto: $pctMiss%" #IMPRIME A MENSAGEM
}

#################
# QUARTO   ITEM #
#################

ListSitesNegadosIP() {
	# MONTA UMA LISTA, SEPARADA POR ' ' DE SITES ACESSADOS POR UM DETERMINADO IP
	list=`cat $1 | grep $2 | egrep 'TCP_DENIED' | awk -F ' ' '{print $7}' | sort | uniq | tr ' ' '\n' | awk -F '/' '{print $3}' | uniq`

	if [[ $list != "" ]]; then
		echo "\n$2\n$list\n-" # IMPRIME A LISTA SUBSTITUINDO OS ' ' POR '\n'echo ""
	fi
}

SearchSitesNegadosIP() {
	read -p "Digite o IP desejado: " searchIp # LER O IP PARA O QUAL SE DESEJA SABER O NUMERO DE SITES DIFERENTES ACESSADOS

	msg="******************\nLista de sistes com acesso negado\n$(ListSitesNegadosIP $1 $searchIp)"

	echo -e "$msg" #IMPRIME A MENSAGEM
}

SearchSitesNegadosTodosIP() {
	FoundIPs $1 # CRIA UM ARQUIVO 'IPs.txt' COM TODOS OS IPS EXISTENTES NO ARQUIVO DE LOG

	msg="******************\nLista de sistes com acesso negado"
	while read IP
	do
		msg+="$(ListSitesNegadosIP $1 $IP)"
	done < IPs.txt
	rm IPs.txt # REMOVE O ARQUIVO DE TEXTO COM A LISTAGEM DOS IPS

	echo -e "$msg" #IMPRIME A MENSAGEM
}

SitesNegados() {
	SubMenuItem
	tput cup 7 19 ; read opt

	case $opt in
		1) clear
		   SearchSitesNegadosIP $1 ;;
		2) clear
		   SearchSitesNegadosTodosIP $1 ;;
		*) clear ;;
	esac
}

#################
# QUINTO   ITEM #
#################

# LISTA TODOS OS SITES ACESSADOS POR UM CLIENTE EM UM DETERMINADO DIA
ListSitesDateIP() {
	read -p "Digite o IP desejado: " searchIp # LER O IP PARA O QUAL SE DESEJA SABER O NUMERO DE SITES DIFERENTES ACESSADOS
	read -p "Digite a Data desejado(Formato: dd-mm-yyyy): " searchData # LER O IP PARA O QUAL SE DESEJA SABER O NUMERO DE SITES DIFERENTES ACESSADOS

	list=`cat $1 | grep $searchIp | egrep -v "TCP_DENIED" | awk -F ' ' '{$1=strftime("%d-%m-%Y", $1); print $1" " $7}' | grep $searchData | cut -d ' ' -f 2 | awk -F '/' '{print $3}' | sort | uniq`
	
	msg="******************\nLista de sistes por cliente em uma data\n$searchIp ($searchData):\n$list"
	
	echo -e "$msg" #IMPRIME A MENSAGEM
}

#################
# SEXTO    ITEM #
#################

# FUNÇÃO RESPONSAVEL POR FAZER A LISTAGEM DOS QUANTITATIVOS, POR CONTEUDO DOS SITES ACESSADOS POR UM CLIENTE
QntAcessoConteudo() {
	read -p "Digite o IP desejado: " searchIp # LER O IP PARA O QUAL SE DESEJA SABER O NUMERO DE SITES DIFERENTES ACESSADOS
	#tiposConteudo=`cat access.log | grep 10.2.2.48 | awk -F ' ' '{print $10}' | sort | uniq` # LISTA DE TODOS OS TIPOS DE CONTEUDO BUSCADOS PARA O IP PESQUISADO
	cat $1 | grep $searchIp | awk -F ' ' '{print $10}' | sort | uniq > tipos.txt
	msg="******************\nQuantitativos de acessos por conteúdo\n"
	while read tipo
	do
		msg+="$tipo - `cat $1 | grep $searchIp| egrep -v "TCP_DENIED" | awk -F ' ' '{print $7 " " $10}' | sort | uniq | cut -d ' ' -f 2 | grep $tipo | wc -l`\n"
	done < tipos.txt
	rm tipos.txt

	echo -e "$msg"
}

QntAcessoConteudoTodosClientes() {
	msg="******************\nQuantitativos de acessos por conteúdo\n"
	
	cat $1 | awk -F ' ' '{print $10}' | sort | uniq > tipos.txt
	while read tipo
	do
		msg+="$tipo - `cat $1 | egrep -v "TCP_DENIED" | awk -F ' ' '{print $7 " " $10}' | sort | uniq | cut -d ' ' -f 2 | grep $tipo | wc -l`\n"
	done < tipos.txt
	rm tipos.txt

	echo -e "$msg"	
}

# FUNÇÃO RESPONSAVEL POR SALVAR O RELATORIO EM UM ARQUIVO DE TEXTO
salveFile() {
	SearchNumSitesDifTodosIP $1 >> RELATORIO.txt
	SearchTotalBytesTodosIP $1 >> RELATORIO.txt
	PctSitesCacheAndDirect $1 >> RELATORIO.txt
	SearchSitesNegadosTodosIP $1 >> RELATORIO.txt
	QntAcessoConteudoTodosClientes $1 >> RELATORIO.txt
	echo "******************" >> RELATORIO.txt
}

CheckOptions() { # RECEBE COMO PARAMETRO O NOME/ENDEREÇO DO ARQUIVO ONDE SERÃO EFETUADAS AS PESQUISAS E O VALOR CORRESPONDENTE A QUAL FUNÇÃO SERÁ ACIONADA
	case $1 in
		1) clear
		   read -p "DIGITE O CAMINHO DE ACESSO PARA O ARQUIVO DE LOG: " fileName ;;
		2) clear
		   NumSitesDif $2;;
		3) clear
		   TotalBytes $2 ;;
		4) clear
		   PctSitesCacheAndDirect $2 ;;
		5) clear
		   SitesNegados $2 ;;
		6) clear
		   ListSitesDateIP $2 ;;
		7) clear
		   QntAcessoConteudo $2 ;;
		8) clear
		   salveFile $2 ;;		
		9) clear
		   exit 0 ;;
		*) clear
		   echo "$1 é uma opção invalida !!!"
		   sleep 0.5 ;;
	esac
}

# GRAVA O NOME DO ARQUIVO ONDE SERÃO FEITAS AS PESQUISAS
read -p "DIGITE O CAMINHO DE ACESSO PARA O ARQUIVO DE LOG: " fileName

test -f $fileName # COMANDO PARA TESTAR SE O ARQUIVO DE LOG EXISTE OU NÃO
# TESTA O VALOR RETORNADO PARA A VERIFICAÇÃO DA EXISTENCIA DO ARQUIVO DE LOG
if [[ $? -eq 0 ]]; then
	# DANDO INICIO AO LOOP DE EXECUÇÃO DO SISTEMA
	while [[ true ]]; do
		# CHAMADA DA FUNÇÃO DE EXIBIÇÃO DOS ITENS DO MENU
		Menu $fileName
		
		tput cup 20 19 ; read opt

		# CHAMA A FUNÇÃO RESPONSAVEL POR ACIONAR A FUNÇÃO RESPECTIVA AO VALOR ESCOLHIDO PELO USUARIO NO MENU
		CheckOptions $opt $fileName

		read -p "tecle ENTER para continuar" cont
	done
else
	echo "	#########################################################################################
	# Carregue/Adicione ao diretorio o arquivo de LOG (log.txt) antes de usar o sistema !!! #
	#########################################################################################"
fi