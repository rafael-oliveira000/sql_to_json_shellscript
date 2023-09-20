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

# Diretorio onde estão os arquivos
diretorio_origem="/projects/TestRunner/testcases/CLARO/HUB/RP_sps_solicitacao"

# Subdiretorio onde serão salvos os arquivos
subdiretorio_destino="/projects/TestRunner/testcases/CLARO/TESTERAFAEL"

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
        # Nome do arquivo de entrada
        arquivo="$1"

        # Verifica se o arquivo existe
        if [ -e "$arquivo" ]; then
            # Utiliza o comando 'grep' para encontrar a linha que cont��m "SRV_TRX_TP_CD_ORIG" e extrair a informa����o entre "=" e ";"
            acao=$(grep "SRV_TRX_TP_CD_ORIG" "$arquivo" | sed 's/.*=\(.*\);@/\1/')

            # Verifica se a vari��vel "acao" est�� vazia
            if [ -n "$acao" ]; then
		acao="${acao%?}"
		echo "$acao"
            else
		echo "acao nao encontrada no arquivo: $arquivo"
	    fi
	fi	
}

# ------------------------------------------------------------------------ #
#	$1 -> req_id
#	$2 -> acao
#	$3 -> telefone

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
      }
"

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
		
		acao=$(extrai_acao "$arquivo_origem")
		req_id=$(extrai_req_id "$arquivo_origem")
		telefone=$(extrai_telefone "$arquivo_origem")
		imsi=$(extrai_imsi "$arquivo_origem")
		
		
#		echo "------------------------"
#		echo $nome_arquivo
#		echo "REQ_ID: $req_id"
#		echo "Acao: $acao"
#		echo "Telefone: $telefone"
#		echo "IMSI: $imsi"
		echo "------------------------"
		
		
		
		escreve_json $req_id $acao $telefone > $arquivo_destino
		
		
		
    	fi
done

echo "Processo concluido"


# ------------------------------------------------------------------------ #
