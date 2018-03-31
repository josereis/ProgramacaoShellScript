#!/bin/bash

# Função de montagem do menu
Menu (){
clear
cat << !
--------------------------------------------------------------------------
	Menu de Usuario
1 - Número de sites diferentes acessados por cada cliente IP

2 - Número total de dados transferidos por cada cliente

3 - Percentual de sites encontrados na cache e de sites trazidos diretamente da internet

4 - Lista de sites com acesso negado para cada cliente

5 - Lista de sites acessados por um cliente em um determinado dia

6 - Lista de quantitativos, por conteúdo, dos sites acessados por um dado cliente

7 - Sair

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
	while read row
		do
		echo $row |  awk -F ' ' '{print $3}' >> aux.txt
		sort aux.txt | uniq > IPs.txt
	done < log.txt
	rm aux.txt # REMOVE O ARQUIVO DE TEXTO AUXILIAR PARA LISTAGEM DOS IPS
}

#################
# PRIMEIRO ITEM #
#################

NumSitesDifIP() {

	#read -p "### Digite o IP desejado " searchIp # LER O IP PARA O QUAL SE DESEJA SABER O NUMERO DE SITES DIFERENTES ACESSADOS

	# PASSEIA POR TODO O ARQUIVO DE LOGs
	while read row
	do
		if [ "$1" = "`echo $row | awk -F ' ' '{print $3}'`" ]; then
			echo $row | awk -F ' ' '{print $7}' >> aux.txt # CAPTURA O VALOR/ENDERECO DO SITE ACESSADO PELO CLIENTE DA LINHA ATUAL E SALVA EM ARQUIVO AUXILIAR
			sort aux.txt | uniq > sites.txt
		fi
	done < log.txt
	rm aux.txt # REMOVE O ARQUIVO DE TEXTO AUXILIAR PARA LISTAGEM DOS IPS

	num=`wc -l sites.txt | awk -F ' ' '{print $1}'` #O COMANDO (wc -l) RETORNA A QUANTIDADE DE LINHAS DE UM ARQUIVO
	
	rm sites.txt # REMOVE O ARQUIVO DE TEXTO QUE CONTEM OS SITES ACESSADOS POR UM DETERMINADO CLIENTE IP

	echo "$1 - $num sites" # IMPRIME O NUMERO DE SITES DIFERENTES PARA O IP BUSCADO
}

SearchNumSitesDifIP() {
	read -p "### Digite o IP desejado " searchIp # LER O IP PARA O QUAL SE DESEJA SABER O NUMERO DE SITES DIFERENTES ACESSADOS

	msg="******************\nSites diferentes por IP:\n$(NumSitesDifIP $searchIp)"
	
	echo -e "$msg" #IMPRIME A MENSAGEM COM O VALOR DE SITES DIFERENTES ACESSADOS POR UM CLIENTE NO CONSOLE
	echo -e "$msg" >> RELATORIO.txt # IMPRIME A MESAGEM NO ARQUIVO DE RELATORIOS
}

# LISTA O NUMERO DE SITES DIFERENTES ACESSADOS POR CADA UM DOS CLIENTES IP DO ARQUIVO DE log.txt
SearchNumSitesDifClients() {
	FoundIPs # CRIA UM ARQUIVO 'IPs.txt' COM TODOS OS IPS EXISTENTES NO ARQUIVO DE LOG

	msg="******************\nSites diferentes por IP:"
	while read IP
	do
		msg+="\n$(NumSitesDifIP $IP)"
	done < IPs.txt
	rm IPs.txt # REMOVE O ARQUIVO DE TEXTO COM A LISTAGEM DOS IPS

	echo -e "$msg" #IMPRIME A MENSAGEM COM O VALOR DE SITES DIFERENTES ACESSADOS POR UM CLIENTE NO CONSOLE
	echo -e "$msg" >> RELATORIO.txt # IMPRIME A MESAGEM NO ARQUIVO DE RELATORIOS
}

# FUNÇÃO RESPONSAVEL POR LISTAR O NUMERO DE SITES DIFERENTES ACESSADOS POR CADA CLIENTE IP
NumSitesDif() {
	SubMenuItem
	tput cup 7 19 ; read opt
	
	case $opt in
		1) clear
		   SearchNumSitesDifIP ;;
		2) clear
		   SearchNumSitesDifClients ;;
		*) clear ;;
	esac
}

#################
# SEGUNDO  ITEM #
#################
TotalBytesPorIP() {
	totalBytes=0 # VARIAVEL QUE VAI ARMAZENAR A QUANTIDADE DE BYTES TOTAL
	
	# PASSEIA POR TODO O ARQUIVO DE LOGs
	while read row
	do
		if [ "$1" = "`echo $row | awk -F ' ' '{print $3}'`" ]; then
			bytes=`echo $row | awk -F ' ' '{print $5}'` # CAPTURA A QUANTIDADE DE BYTES TRANSFERIDAS
			totalBytes=`expr $totalBytes + $bytes`
		fi
	done < log.txt
	
	echo "$1 - $totalBytes bytes" # IMPRIME O TOTAL DE BYTES TRANSFERIDOS POR UM IP BUSCADO
}

SearchTotalBytesIP() {
	read -p "### Digite o IP desejado " searchIp # LER O IP PARA O QUAL SE DESEJA SABER O NUMERO DE SITES DIFERENTES ACESSADOS

	msg="******************\nTotal de bytes transferidos por IP:\n$(TotalBytesPorIP $searchIp)"

	echo -e "$msg" #IMPRIME A MENSAGEM COM O VALOR DE SITES DIFERENTES ACESSADOS POR UM CLIENTE NO CONSOLE
	echo -e "$msg" >> RELATORIO.txt # IMPRIME A MESAGEM NO ARQUIVO DE RELATORIOS
}

SearchTotalBytesTodosIP() {
	FoundIPs # CRIA UM ARQUIVO 'IPs.txt' COM TODOS OS IPS EXISTENTES NO ARQUIVO DE LOG

	msg="******************\nTotal de bytes transferidos por IP:"
	while read IP
	do
		msg+="\n$(TotalBytesPorIP $IP)"
	done < IPs.txt
	rm IPs.txt # REMOVE O ARQUIVO DE TEXTO COM A LISTAGEM DOS IPS

	echo -e "$msg" #IMPRIME A MENSAGEM
	echo -e "$msg" >> RELATORIO.txt # IMPRIME A MESAGEM NO ARQUIVO DE RELATORIOS
}

TotalBytes() {
	SubMenuItem
	tput cup 7 19 ; read opt

	case $opt in
		1) clear
		   SearchTotalBytesIP ;;
		2) clear
		   SearchTotalBytesTodosIP ;;
		*) clear ;;
	esac
}

#################
# TERCEIRO ITEM #
#################

# CALCULA O TOTAL DE SITES ENCONTRADOS NA CACHE
PctSitesCacheAndDirect() {
	while read row
	do
		codigo=`echo $row | awk -F ' ' '{print $4}'` # CAPTURA O VALOR DO CODIGO RESULTANTE DO ACESSO

		if [[ "$codigo" = "TCP_HIT/200" ]]; then # VERIFICA SE FOI OBTIDO A PARTIR DA CACHE
			hit=`expr $hit + 1`
		else
			if [[ "$codigo" = "TCP_MISS/200" ]]; then # VERIFICA SE FOI OBTIDO DIRETAMENTE
				miss=`expr $miss + 1`
			fi
		fi
	done < log.txt

	totalHitMiss=`echo "scale=0 ; $hit + $miss" | bc`
	pctHit=`echo "scale=0 ; ($hit * 100) / $totalHitMiss" | bc`
	pctMiss=`echo "scale=0 ; ($miss * 100) / $totalHitMiss " | bc`

	echo -e "******************\nPercentual de sites na cache e de acesso direto:\nCache: $pctHit%\nDireto: $pctMiss%" #IMPRIME A MENSAGEM
	echo -e "******************\nPercentual de sites na cache e de acesso direto:\nCache: $pctHit%\nDireto: $pctMiss%" >> RELATORIO.txt # IMPRIME A MESAGEM NO ARQUIVO DE RELATORIOS
}

#################
# QUARTO   ITEM #
#################

# FUNCAO RESPONSAVEL POR LISTAR TODOS OS SITES COM PERMISSÃO DE ACESSO NEGADA PARA UM IP
ListSitesNegadosIP() {
	msg="$1"
	while read row
	do
		codigo=`echo $row | awk -F ' ' '{print $4}'` # CAPTURA O VALOR DO CODIGO DE ACESSO
		if [ "$1" = "`echo $row | awk -F ' ' '{print $3}'`" -a "$codigo" = "TCP_DENIED" ]; then
			msg+="\n`echo $row | awk -F ' ' '{print $7}'`"
		fi
	done < log.txt

	echo "$msg"
}

SearchSitesNegadosIP() {
	read -p "### Digite o IP desejado " searchIp # LER O IP PARA O QUAL SE DESEJA SABER O NUMERO DE SITES DIFERENTES ACESSADOS

	#ListSitesNegadosIP $searchIp
	msg="******************\nLista de sistes com acesso negado:$(ListSitesNegadosIP $searchIp)"

	echo -e "$msg" #IMPRIME A MENSAGEM
	echo -e "$msg" >> RELATORIO.txt # IMPRIME A MESAGEM NO ARQUIVO DE RELATORIOS
}

SearchSitesNegadosTodosIP() {
	FoundIPs # CRIA UM ARQUIVO 'IPs.txt' COM TODOS OS IPS EXISTENTES NO ARQUIVO DE LOG

	msg="******************\nLista de sistes com acesso negado:"
	while read IP
	do
		msg+="\n$(ListSitesNegadosIP $IP)\n-"
	done < IPs.txt
	rm IPs.txt # REMOVE O ARQUIVO DE TEXTO COM A LISTAGEM DOS IPS

	echo -e "$msg" #IMPRIME A MENSAGEM
	echo -e "$msg" >> RELATORIO.txt # IMPRIME A MESAGEM NO ARQUIVO DE RELATORIOS
}

SitesNegados() {
	SubMenuItem
	tput cup 7 19 ; read opt

	case $opt in
		1) clear
		   SearchSitesNegadosIP ;;
		2) clear
		   SearchSitesNegadosTodosIP ;;
		*) clear ;;
	esac
}

#################
# QUINTO   ITEM #
#################

# LISTA TODOS OS SITES ACESSADOS POR UM CLIENTE EM UM DETERMINADO DIA
ListSitesDateIP() {
	read -p "### Digite o IP desejado: " searchIp # LER O IP PARA O QUAL SE DESEJA SABER O NUMERO DE SITES DIFERENTES ACESSADOS
	read -p "### Digite a Data desejado(Formato: AAAA-MM-DD): " searchData # LER O IP PARA O QUAL SE DESEJA SABER O NUMERO DE SITES DIFERENTES ACESSADOS

	msg="******************\nLista de sistes por cliente em uma data:"
	while read row
	do
		aux=`echo $row | awk -F ' ' '{print $1}'` ; data=`date --date=@$aux +%F`
		
		if [ "$searchIp" = "`echo $row | awk -F ' ' '{print $3}'`" -a "$searchData" = "$data" ]; then
			msg+="\n$data - `echo $row | awk -F ' ' '{print $7}'`"
		fi
	done < log.txt

	echo -e "$msg"
	echo -e "$msg" >> RELATORIO.txt
}

#################
# QUINTO   ITEM #
#################

# FUNÇÃO RESPONSAVEL POR FAZER A LISTAGEM DOS QUANTITATIVOS, POR CONTEUDO DOS SITES ACESSADOS POR UM CLIENTE
QntAcessoConteudo() {
	read -p "### Digite o IP desejado: " searchIp # LER O IP PARA O QUAL SE DESEJA SABER O NUMERO DE SITES DIFERENTES ACESSADOS
	
	msg="******************\nQuantitativos de acessos por conteúdo:"
	# CRIA UM ARQUIVO COM TODOS OS SITES E SEUS RESPECTIVOS TIPOS PARA UM IP PASSADO
	while read row
	do
		if [[ "$searchIp" = "`echo $row | awk -F ' ' '{print $3}'`" ]]; then
			echo -e "`echo $row | awk -F ' ' '{print $10}'` - `echo $row | awk -F ' ' '{print $7}'`" >> aux.txt
			sort aux.txt | uniq > tipoConteudo.txt;
		fi
	done < log.txt
	# ADICONA AO ARQUIVO TODOS OS TIPOS DE CONTEUDO EXISTENTES NO ARQUIVO 'tipoConteudo.txt'
	cat tipoConteudo.txt | awk -F ' ' '{print $1}' | sort | uniq > aux.txt
	
	# PARA CADA TIPO DE CONTEUDO EXISTENTE CALCULA A QUANTIDADE TOTAL DOS MESMO
	while read tipo
	do
		msg+="\n$tipo - $(grep -c $tipo tipoConteudo.txt)"
	done < aux.txt
	rm aux.txt ; rm tipoConteudo.txt

	echo -e "$msg"
	echo -e "$msg" >> RELATORIO.txt
}

CheckOptions() {
	case $1 in
		1) clear
		   NumSitesDif ;;
		2) clear
		   TotalBytes ;;
		3) clear
		   PctSitesCacheAndDirect ;;
		4) clear
		   SitesNegados ;;
		5) clear
		   ListSitesDateIP ;;
		6) clear
		   QntAcessoConteudo ;;
		7) clear
		   echo "******************" >> RELATORIO.txt
		   exit 0 ;;
		*) clear
		   echo "$1 é uma opção invalida !!!"
		   sleep 0.5 ;;
	esac
}


test -f "log.txt" # COMANDO PARA TESTAR SE O ARQUIVO DE LOG EXISTE OU NÃO
# TESTA O VALOR RETORNADO PARA A VERIFICAÇÃO DA EXISTENCIA DO ARQUIVO DE LOG
if [[ $? -eq 0 ]]; then
	# DANDO INICIO AO LOOP DE EXECUÇÃO DO SISTEMA
	while [[ true ]]; do
		# CHAMADA DA FUNÇÃO DE EXIBIÇÃO DOS ITENS DO MENU
		Menu
		
		tput cup 16 19 ; read opt

		# CHAMA A FUNÇÃO RESPONSAVEL POR ACIONAR A FUNÇÃO RESPECTIVA AO VALOR ESCOLHIDO PELO USUARIO NO MENU
		CheckOptions $opt

		read -p "### Continuar no Menu Principal? (S/N) " cont

		if [ $cont = "N" ] || [ $cont = "n" ]; then
			echo -e "Finalizando processos. Saindo em 3, 2, 1..."
			sleep 1;
			exit 1
		fi
	done
else
	echo "	#########################################################################################
	# Carregue/Adicione ao diretorio o arquivo de LOG (log.txt) antes de usar o sistema !!! #
	#########################################################################################"
fi