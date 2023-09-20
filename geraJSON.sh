#!/usr/bin/env bash
#
# geraJSON - 	Transforma um teste que insere na sps_solicitacao em 
#				teste de interface
# Autor:      Rafael Oliveira
# Manutencao: Rafael Oliveira
#
# ------------------------------------------------------------------------ #
#	Este programa ira gerar um teste de interface JSON a partir de testes
#	da sps_solicitacao
#
#  Exemplo:
#      $ ./geraJSON.sh
#		Neste exemplo deve-se ajustar as variaveis diretorio_origem e
#		subdiretorio_destino
# ------------------------------------------------------------------------ #
# Historico:
#
#   v1.1 18/09/2023, Rafael:
#       - Versao inicial que extrai informacoes do .sql
# ------------------------------------------------------------------------ #
# Testado em:
#	4.1.2(1)-release (x86_64-redhat-linux-gnu)
# ------------------------------------------------------------------------ #

# ------------------------------- MELHORIAS ------------------------------ #
#	Ajustar as aspas do json de saida. Os campos chave-valor do json 
#	devem estar entre aspas.
# ------------------------------------------------------------------------ #

# ------------------------------- VARIAVEIS ------------------------------ #

# Diretorio onde estao os arquivos
diretorio_origem="/projects/TestRunner/testcases/CLARO/HUB/RP_sps_solicitacao"

# Subdiretorio onde serao salvos os arquivos
subdiretorio_destino="/projects/TestRunner/testcases/CLARO/TESTERAFAEL"

# Obter o dia, mes e ano separadamente e juntar em data
dia=$(date +"%d")
mes=$(date +"%m")
ano=$(date +"%Y")
data="$dia-$mes-$ano"

# Declarar LST_FEATURE,LST_FEATURE_PREV
lst_feature=""
lst_feature_prev=""

# ------------------------------- TESTES --------------------------------- #


# ------------------------------- FUNCOES -------------------------------- #

extrai_req_id(){
        # Verifica se foi fornecido o nome do arquivo como argumento
        if [ $# -ne 1 ]; then
                echo "Uso: $0 <arquivo>"
                exit 1
        fi

        # Le o nome do arquivo a partir do primeiro argumento
        arquivo="$1"

        # Verifica se o arquivo existe
        if [ ! -e "$arquivo" ]; then
                echo "O arquivo '$arquivo' nao existe."
                exit 1
        fi

        # Extrai a linha com "values" ou "VALUES" do arquivo e a armazena na variavel "linha"
        linha=$(grep -i 'values' "$arquivo")

        # Verifica se a linha foi encontrada
        if [ -z "$linha" ]; then
                echo "Nenhuma linha contendo 'values' ou 'VALUES' foi encontrada no arquivo."
                exit 1
        fi

        #Extrai o valor do req_id
        req_id=$(echo "$linha" | cut -d ',' -f 56)

        #Remove as aspas
#        req_id="${req_id#?}"
#        req_id="${req_id%?}"

        # Imprime o valor da variavel req_id na tela
        echo "$req_id"
}
# ------------------------------------------------------------------------ #
extrai_telefone(){
        # Verifica se foi fornecido o nome do arquivo como argumento
        if [ $# -ne 1 ]; then
                echo "Uso: $0 <arquivo>"
                exit 1
        fi

        # Le o nome do arquivo a partir do primeiro argumento
        arquivo="$1"

        # Verifica se o arquivo existe
        if [ ! -e "$arquivo" ]; then
                echo "O arquivo '$arquivo' nao existe."
                exit 1
        fi

        # Extrai a linha com "values" ou "VALUES" do arquivo e a armazena na variavel "linha"
        linha=$(grep -i 'values' "$arquivo")

        # Verifica se a linha foi encontrada
        if [ -z "$linha" ]; then
                echo "Nenhuma linha contendo 'values' ou 'VALUES' foi encontrada no arquivo."
                exit 1
        fi
		
        #Extrair o numero de telefone
        telefone=$(echo "$linha" | cut -d ',' -f 58)

        #Remove as aspas
#        telefone="${telefone#?}"
#        telefone="${telefone%?}"

        #Imprime o numero do telefone
        echo "$telefone"
}
# ------------------------------------------------------------------------ #
extrai_imsi(){
        # Verifica se foi fornecido o nome do arquivo como argumento
        if [ $# -ne 1 ]; then
                echo "Uso: $0 <arquivo>"
                exit 1
        fi

        # Le o nome do arquivo a partir do primeiro argumento
        arquivo="$1"

        # Verifica se o arquivo existe
        if [ ! -e "$arquivo" ]; then
                echo "O arquivo '$arquivo' nao existe."
                exit 1
        fi

        # Extrai a linha com "values" ou "VALUES" do arquivo e a armazena na variavel "linha"
        linha=$(grep -i 'values' "$arquivo")

        # Verifica se a linha foi encontrada
        if [ -z "$linha" ]; then
                echo "Nenhuma linha contendo 'values' ou 'VALUES' foi encontrada no arquivo."
                exit 1
        fi
		
        #Extrair o numero imsi
        imsi=$(echo "$linha" | cut -d ',' -f 59)

        #Remove as aspas
#        imsi="${imsi#?}"
#        imsi="${imsi%?}"

        #Imprime o numero do imsi
        echo "$imsi"
}
# ------------------------------------------------------------------------ #
extrai_acao(){
	acao=$(extrai_feature "$1" "SRV_TRX_TP_CD_ORIG")
	echo $acao
}	
	
# ------------------------------------------------------------------------ #
extrai_HLR_N(){
	HLR_N=$(extrai_feature "$1" ";HLR=")
	echo $HLR_N
}	

# ------------------------------------------------------------------------ #
extrai_HLR_P(){
	HLR_P=$(extrai_feature "$1" ";HLR=")
	echo $HLR_P
}
# ------------------------------------------------------------------------ #

extrai_FTRCD() {
    local arquivo="$1"  # Nome do arquivo passado como parâmetro
    local linhas_ftrcd=""  # Variável para armazenar as linhas contendo "FTRCD" ou "CUSTOMER"

    # Verifica se o arquivo existe
    if [ -f "$arquivo" ]; then
        # Loop para ler cada linha do arquivo
        while IFS= read -r linha; do
            # Verifica se a linha contém "FTRCD" ou "CUSTOMER"
            if [[ "$linha" == *"FTRCD"* || "$linha" == *"CUSTOMER"* ]]; then
                # Adiciona a linha à variável
                linhas_ftrcd="${linhas_ftrcd}${linha}\n"
            fi
        done < "$arquivo"
    else
        echo "O arquivo '$arquivo' não existe."
        return 1
    fi
	feature="FTRCD"
	feature+="${linhas_ftrcd#*FTRCD}"
	
    # Retorna as linhas_ftrcd contendo "FTRCD"
    echo -e "$feature"

#	echo "lst_feature_prevFUNCAO"
}
# ------------------------------------------------------------------------ #
extrai_lst_feature() {
	lst_FTRCD=$(extrai_FTRCD $1)
	
	# Substring pré-determinada que você deseja encontrar
	substring=","
	
	# Use o comando 'expr' para encontrar a posição da substring
	posicao=$(expr index "$lst_FTRCD" "$substring")
	
	# Verifique se a substring foi encontrada
	if [ "$posicao" -gt 0 ]; then
	    # Use o comando 'expr' novamente para extrair a parte da string até a posição da substring
		lst_feature=$(expr substr "$lst_FTRCD" 1 "$posicao")
	fi
	echo "$lst_feature"
}
# ------------------------------------------------------------------------ #

extrai_lst_feature_prev() {
	lst_FTRCD=$(extrai_FTRCD $1)
	lst_feature_prev="${lst_FTRCD#*,}"
	echo "$lst_feature_prev"
}
# ------------------------------------------------------------------------ #

# Alterar pra usar lst_feature ou lst_feature_prev invés de 1 ou 2

extrai_feature(){
	#Funcao para extrair valor da feature.
	# $1 -> string
	# $2 -> feature
	
	string=$1

	# Utiliza o comando 'grep' para encontrar a linha que contem o primeiro "$2" e extrair a informacao entre "=" e ";"
	feature=$(grep -m 1 "$2" "$string" | sed 's/.*=\(.*\);@/\1/')
		
	# Verifica se a variavel "feature" esta vazia
	if [ -n "$feature" ]; then
		feature="${feature%?}"
		echo "$feature"
	else
		#Comentario para facilitar debug		

		echo ""
	fi


}
# ------------------------------------------------------------------------ #
#	$1 -> req_id
#	$2 -> acao
#	$3 -> telefone
#	$4 -> HLR_N
#	$5 -> HLR_P
#	$6 -> profile

escreve_json(){
	local json="
{
   "ordem":{
      "correlacao":[
         {
            "id":"$1",
            "sistema-origem":{
               "id":"SGIOT"
            },
            "endereco-resposta":"http://10.18.81.219:8004/FachadaWoaSgiot/rest"
         }
      ],
      "operacao":{
         "id":"$2",
         "situacao-operacao":{
            "data":"2023-05-30T08:00:10-03:00"
         },
         "motivo":{
            "id":"PROVISIONING"
         },
         "usuario":{
            "id":"SGIOT"
         },
         "prioridade":"10"
      },
      "cliente":{
         "id":"111008173"
      },
      "item-ordem":[
         {
            "produto-alvo":{
               "recurso-telefonia":{
                  "numeracao":{
                     "numero-telefone":"$3"
                  },
                  "simcard":{
                     "iccid":"89550031310007761975",
                     "imsi":"724003100569646",
                     "pin":"3636",
                     "puk":"3636",
                     "pin2":"3636",
                     "puk2":"3636",
                     "ki":"259146167291242D4F5127D9AC5CB8A5",
                     "tk":"178",
                     "chv5":"761446455758488D",
                     "op":"13"
                  },
                  "perfil-aprovisionamento":{
                     "id":"30",
                     "comando-aprovisionamento":[
                        {
                            "servico": {
                                "id": "EQPT"
                            },
                            "operacao": {
                                "id": "ACT"
                            },
                            "parametro": [
                                {
                                    "nome": "HLR",
                                    "valor": "$4"
                                },
                                {
                                    "nome": "HSSDRA",
                                    "valor": "HSSRJ3MG3"
                                }
                            ]
                        },"
#	Se HLR_P nao estiver vazia, escrever o bloco com HLR_P.
	testa_HLR_P=""
	testa_HLR_P=$5
	if [ -n "$testa_HLR_P" ]; then
	
	json+="
                        {
                            "servico": {
                                "id": "EQPT"
                            },
                            "operacao": {
                                "id": "CAN"
                            },
                            "parametro": [
                                {
                                    "nome": "HLR",
                                    "valor": "$5"
                                },
                                {
                                    "nome": "HSSDRA",
                                    "valor": "HSSRJ3MG3"
                                }
                            ]
                        },"
	fi
	json+="	
                        {
                            "servico":{
                                "id":"PROFILE"
                            },
                            "operacao":{
                                "id":"ACT"
                            },
                            "parametro":[
                                {
                                    "nome":"PROFILEID",
                                    "valor":"$6"
                                }
                            ]
                        },"

	echo "$json"
}

# ------------------------------------------------------------------------ #

# ------------------------------- EXECUCAO ------------------------------- #

# Verifica se o subdiretório de destino existe, senão cria
mkdir -p "$subdiretorio_destino"

# Loop para processar arquivos .sql e .js no diretório de origem
for arquivo_origem in "$diretorio_origem"/*.{sql,js}; do
	# Verifica se o arquivo é  uivo
	if [ -f "$arquivo_origem" ]; then
		# Obtém o nome do arquivo sem o caminho
		nome_arquivo=$(basename "$arquivo_origem")
		
		# Remove o .sql
		nome_arquivo="${nome_arquivo%?}"
		nome_arquivo="${nome_arquivo%?}"
		nome_arquivo="${nome_arquivo%?}"
		nome_arquivo="${nome_arquivo%?}"
		
		# Cria o caminho completo para o arquivo de destino no subdiretório
		arquivo_destino="$subdiretorio_destino/$nome_arquivo.js"
		
		# Cria o arquivo
		touch "$arquivo_destino"
		chmod 777 "$arquivo_destino"
		
		lst_feature=$(extrai_lst_feature "$arquivo_origem")
		lst_feature_prev=$(extrai_lst_feature_prev "$arquivo_origem")
		
		acao=$(extrai_acao "$arquivo_origem")
		req_id=$(extrai_req_id "$arquivo_origem")
		telefone=$(extrai_telefone "$arquivo_origem")
		imsi=$(extrai_imsi "$arquivo_origem")
		HLR_N=$(extrai_HLR_N "$lst_feature")
		HLR_P=$(extrai_HLR_P "$lst_feature_prev")

		
		echo "------------------------"
		echo $nome_arquivo
		echo "REQ_ID: $req_id"
		echo "Acao: $acao"
		echo "Telefone: $telefone"
		echo "IMSI: $imsi"
		echo "HLR_N: $HLR_N"
		echo "HLR_P: $HLR_P"
		echo "------------------------"
		echo "lst_feature: $lst_feature"
		echo "------------------------"
		echo "lst_feature_prev: $lst_feature_prev"
		echo "------------------------"
		
		
		escreve_json $req_id $acao $telefone $HLR_N $HLR_P > $arquivo_destino
		
		
		
    	fi
done

echo "Processo concluido"


# ------------------------------------------------------------------------ #
