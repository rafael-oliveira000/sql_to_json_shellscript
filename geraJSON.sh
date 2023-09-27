#!/usr/bin/env bash
#
# ------------------------------------------------------------------------ #
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
#		- Versao inicial que extrai informacoes do .sql
#   v1.2 19/09/2023, Rafael:
#		- Adicionado funções para extrair o imsi e hlr e gerar
#		parcialmente o arquivo json
#		- Criado a melhoria extrai_feature para evitar repeticao
#		de codigo.
#   v1.3 20/09/2023, Rafael:
#       - Corrigido o bug da melhoria extrai_feature
#   v1.4 20/09/2023, Rafael:
#       - Corrigido o bug do HLR_P inexistente
#		- Adicionado extrai_profile
#   v1.5 20/09/2023, Rafael:
#       - Adicionado funcao possui_feature
#   v1.6 21/09/2023, Rafael:
#       - Adicionado tratamento para HSS, 5GNSA e 5GSA
#   v1.7 21/09/2023, Rafael:
#       - Ajustado as aspas do json de saida
#		- Adicionado escreve_json2 para tratar as features SLICE, DNN e APN
#   v1.8 25/09/2023, Rafael:
#		- Ajustado bug das virgulas no json
#   v1.9 26/09/2023, Rafael:
#		- Ajustado extrai_slice para até 2 slices
#		- Criado escreve_slice_json
#		- Criado tratamento para iccid
#		- Adicionado imsi e iccid no json
#	v1.10 26/09/2023, Rafael:
#		- Ajustado a organizacao dos campos slice
#		- Criado extrai_dnn
#		- Adicionado chamada ao escreve_dnn_json
#	v1.11 27/09/2023, Rafael:
#		- Ajustado escreve_dnn_json
#	v1.12 27/09/2023, Rafael:
#		- Criado extrai_apn
#		- Criado escreve_apn_json
# ------------------------------------------------------------------------ #
# Testado em:
#	4.1.2(1)-release (x86_64-redhat-linux-gnu)
# ------------------------------------------------------------------------ #
#
# -------------- MELHORIAS A SEREM FEITAS PARA geraJSON_2.0 -------------- #
#	- Criar uma função unica para testar a existencia do arquivo 
#	e testar apenas uma vez para cada arquivo.
#	- Melhorar a funcao extrai_slice para que o numero de slices seja
#	dinamico invés de no maximo 2. Tambem alterar a forma que o JSON
#	recebe essa informacao.
# ------------------------------------------------------------------------ #
#
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
        # Le o nome do arquivo a partir do primeiro argumento
        arquivo="$1"

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
        req_id="${req_id#?}"
        req_id="${req_id%?}"

        # Imprime o valor da variavel req_id na tela
        echo "$req_id"
}
# ------------------------------------------------------------------------ #

extrai_telefone(){
        # Le o nome do arquivo a partir do primeiro argumento
        arquivo="$1"

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
        telefone="${telefone#?}"
        telefone="${telefone%?}"

        #Imprime o numero do telefone
        echo "$telefone"
}
# ------------------------------------------------------------------------ #

extrai_imsi(){
        # Le o nome do arquivo a partir do primeiro argumento
        arquivo="$1"

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
        imsi="${imsi#?}"
        imsi="${imsi%?}"

        #Imprime o numero do imsi
        echo "$imsi"
}
# ------------------------------------------------------------------------ #

extrai_iccid(){
	iccid=$(extrai_feature "$1" "ICCID=")
	echo $iccid

}
# ------------------------------------------------------------------------ #

extrai_acao(){
	acao=$(extrai_feature "$1" "SRV_TRX_TP_CD=")
	echo $acao
}	
	
# ------------------------------------------------------------------------ #

extrai_HLR(){
	# $1 -> lst_feature(_prev)
	lista_feature=$1
	HLR=$(extrai_feature "$lista_feature" ";HLR=")
	echo $HLR
}

# ------------------------------------------------------------------------ #

extrai_profile(){
	#$1 -> lst_feature(_prev)
	lista_feature=$1
	profile=$(extrai_feature "$lista_feature" ";PROFILEID=")
	echo $profile
}

# ------------------------------------------------------------------------ #

extrai_slice(){
	# $1 -> lst_feature(_prev)
	lista_feature=$1
	slice=$(possui_feature "$lista_feature" "=SLICE")
	
	# Seleciona os slices da lst_feature(_prev)
	#lista_slice=$(echo "$slice" | cut -c7-14)
	
	#Conta o numero de slices
	num_dnn=$(echo "$lista_slice" | grep -o "=SLICE" | wc -l)

	slice_name=$(echo "$slice" | cut -c7-14)
	slice_id=$(echo "$slice" | cut -c37-37)
	slice_default=$(extrai_feature "$slice" "DEFAULT=")
	
	slice_name_1=$(echo -e "$slice_name" | head -n 1)
	slice_name_2=$(echo -e "$slice_name" | sed -n '2p')
	slice_id_1=$(echo -e "$slice_id" | head -n 1)
	slice_id_2=$(echo -e "$slice_id" | sed -n '2p')
	slice_default_1=$(echo -e "$slice_default" | head -n 1)
	slice_default_2=$(echo -e "$slice_default" | sed -n '2p')
	
	echo "$slice_name_1"
	echo "$slice_id_1"
	echo "$slice_default_1"
	echo "$slice_name_2"
	echo "$slice_id_2"
	echo "$slice_default_2"
}

# ------------------------------------------------------------------------ #

extrai_dnn(){
	# $1 -> lst_feature(_prev)
	lista_feature=$1
	lista_dnn=$(possui_feature "$lista_feature" "=DNN")
	
	# Seleciona as DNN da lst_feature(_prev)
	#lista_dnn=$(echo "$dnn" | cut -c7-14)
	
	#Conta o numero de dnn
	num_dnn=$(echo "$lista_dnn" | grep -o "=DNN" | wc -l)
	contador=1
	limite=($num_dnn)
	((limite++))
	declare -a dnn
	
	echo "$num_dnn"
	while [ "$contador" -lt "$limite" ]; do

		linha=$(echo "$lista_dnn" | sed -n "${contador}p")
		
		dnn=$(extrai_feature "$linha" "FTRCD=")
		dnn_id=$(extrai_feature "$linha" "DNNID=")
		dnn_name=$(extrai_feature "$linha" "DNNNAME=")
		dnn_eqosid=$(extrai_feature "$linha" "EQOSID=")
		dnn_ip=$(extrai_feature "$linha" "TIPOIP=")
		dnn_ipv4=$(extrai_feature "$linha" "IPV4=")
		dnn_ipv6=$(extrai_feature "$linha" "IPV6=")
		dnn_default=$(extrai_feature "$linha" "DEFAULT=")
		dnn_sliceid=$(extrai_feature "$linha" "SLICEID=")
		
		echo "$dnn"
		echo "$dnn_id"
		echo "$dnn_name"
		echo "$dnn_eqosid"
		echo "$dnn_ip"
		echo "$dnn_ipv4"
		echo "$dnn_ipv6"
		echo "$dnn_default"
		echo "$dnn_sliceid"

		((contador++))
	done
}

# ------------------------------------------------------------------------ #

# Ajustar bug do teste T001_001. Tem a feature APN006 faltando valores.

extrai_apn(){
#	$1 -> lst_feature(_prev)
	lista_feature=$1
	lista_apn=$(possui_feature "$lista_feature" "=APN")
	
	# Seleciona as APN da lst_feature(_prev)
	#lista_apn=$(echo "$apn" | cut -c7-14)
	
	#Conta o numero de apn
	num_apn=$(echo "$lista_apn" | grep -o "=APN0" | wc -l)
	contador=1
	limite=($num_apn)
	((limite++))
	declare -a apn
	
	echo "$num_apn"
	while [ "$contador" -lt "$limite" ]; do

		linha=$(echo "$lista_apn" | sed -n "${contador}p")
		
		apn=$(extrai_feature "$linha" "FTRCD=")
		apn_eqosid=$(extrai_feature "$linha" "EQOSID=")
		apn_id=$(extrai_feature "$linha" "APNID=")
		apn_name=$(extrai_feature "$linha" "APNNAME=")
		apn_ip=$(extrai_feature "$linha" "TIPOIP=")
		apn_ipv4=$(extrai_feature "$linha" "IPV4=")
		apn_ipv6=$(extrai_feature "$linha" "IPV6=")

		echo "$apn"
		echo "$apn_eqosid"
		echo "$apn_id"
		echo "$apn_name"
		echo "$apn_ip"
		echo "$apn_ipv4"
		echo "$apn_ipv6"
		
		((contador++))
	done
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

possui_feature(){
	# $1 -> $lst_feature(_prev)
	# $2 -> $HSS, $5GNSA ou $5GSA
	lista_feature=$1
	feature=$2
	
	# Extrai a linha com feature da lista de feature e a armazena na variavel "linha"
	linha=$(echo "$lista_feature" | grep "$feature")

	# Verifica se a linha foi encontrada
	if [ -z "$linha" ]; then
		echo ""
	else
		echo "$linha"
	fi
}

# ------------------------------------------------------------------------ #

extrai_feature(){
#	$1 -> $lst_feature(_prev)
#	$2 -> $feature (HLR, acao)
	lista_feature=$1
	feature=$2
	
	# Extrai a linha com feature da lista de feature e a armazena na variavel "linha"
	linha=$(echo "$lista_feature" | grep "$feature")

	# Verifica se a linha foi encontrada
	if [ -z "$linha" ]; then
#		echo "Nenhuma linha contendo '$2' foi encontrada na lista de feature."
		echo ""
	fi
	#Extrair o valor da feature
	valor=$(echo "$linha" | sed -n "s/.*$feature\([^;]*\).*/\1/p")

	echo "$valor"
}

# ------------------------------------------------------------------------ #

escreve_json(){
#	$1 -> $req_id
#	$2 -> $acao
#	$3 -> $telefone
#	$4 -> $iccid
#	$5 -> $imsi
#	$6 -> $HLR_N
#	$7 -> $HLR_P
#	$8 -> $profile_N
#	$9 -> $profine_P
#	$10-> $HSS_N
#	$11-> $HSS_P
#	$12-> $_5GNSA_N
#	$13-> $_5GNSA_P
#	$14-> $_5GSA_N
#	$15-> $_5GSA_P

	local json="{
   \"ordem\":{
      \"correlacao\":[
         {
            \"id\":\"$1\",
            \"sistema-origem\":{
               \"id\":\"SGIOT\"
            },
            \"endereco-resposta\":\"http://10.18.81.219:8004/FachadaWoaSgiot/rest\"
         }
      ],
      \"operacao\":{
         \"id\":\"$2\",
         \"situacao-operacao\":{
            \"data\":\"2023-05-30T08:00:10-03:00\"
         },
         \"motivo\":{
            \"id\":\"PROVISIONING\"
         },
         \"usuario\":{
            \"id\":\"SGIOT\"
         },
         \"prioridade\":\"10\"
      },
      \"cliente\":{
         \"id\":\"111008173\"
      },
      \"item-ordem\":[
         {
            \"produto-alvo\":{
               \"recurso-telefonia\":{
                  \"numeracao\":{
                     \"numero-telefone\":\"$3\"
                  },
                  \"simcard\":{
                     \"iccid\":\"$4\",
                     \"imsi\":\"$5\",
                     \"pin\":\"3636\",
                     \"puk\":\"3636\",
                     \"pin2\":\"3636\",
                     \"puk2\":\"3636\",
                     \"ki\":\"259146167291242D4F5127D9AC5CB8A5\",
                     \"tk\":\"178\",
                     \"chv5\":\"761446455758488D\",
                     \"op\":\"13\"
                  },
                  \"perfil-aprovisionamento\":{
                     \"id\":\"30\",
                     \"comando-aprovisionamento\":[
                        {
                            \"servico\": {
                                \"id\": \"EQPT\"
                            },
                            \"operacao\": {
                                \"id\": \"ACT\"
                            },
                            \"parametro\": [
                                {
                                    \"nome\": \"HLR\",
                                    \"valor\": \"$6\"
                                },
                                {
                                    \"nome\": \"HSSDRA\",
                                    \"valor\": \"HSSRJ3MG3\"
                                }
                            ]
                        }"

#	Se HLR_P nao estiver vazia, escrever o bloco com HLR_P.
	testa_HLR_P=""
	testa_HLR_P=$7
	if [ -n "$testa_HLR_P" ]; then
	
	json+=",
                        {
                            \"servico\": {
                                \"id\": \"EQPT\"
                            },
                            \"operacao\": {
                                \"id\": \"CAN\"
                            },
                            \"parametro\": [
                                {
                                    \"nome\": \"HLR\",
                                    \"valor\": \"$7\"
                                },
                                {
                                    \"nome\": \"HSSDRA\",
                                    \"valor\": \"HSSRJ3MG3\"
                                }
                            ]
                        }"
	fi
	
#	Se profile_N nao estiver vazia, escrever o bloco com profile_N.
	testa_profile_N=""
	testa_profile_N=$8
	if [ -n "$testa_profile_N" ]; then
		json+=",	
						{
							\"servico\":{
								\"id\":\"PROFILE\"
							},
							\"operacao\":{
								\"id\":\"ACT\"
							},
							\"parametro\":[
								{
									\"nome\":\"PROFILEID\",
									\"valor\":\"$8\"
								}
							]
						}"
	fi
	
#	Se profile_P nao estiver vazia, escrever o bloco com profile_P.
	testa_profile_P=""
	testa_profile_P=$9
	if [ -n "$testa_profile_P" ]; then
		json+=",
						{
							\"servico\":{
								\"id\":\"PROFILE\"
							},
							\"operacao\":{
								\"id\":\"CAN\"
							},
							\"parametro\":[
								{
									\"nome\":\"PROFILEID\",
									\"valor\":\"$9\"
								}
							]
						}"
	fi
	
#	Se HSS_N nao estiver vazia, escrever o bloco com HSS_N.
	testa_HSS_N=""
	testa_HSS_N=${10}
	if [ -n "$testa_HSS_N" ]; then
		json+=",
                        {
                           \"servico\":{
                              \"id\":\"HSS\"
                           },
                           \"operacao\":{
                              \"id\":\"ACT\"
                           }
                        }"
	fi
	
#	Se HSS_P nao estiver vazia, escrever o bloco com HSS_P.
	testa_HSS_P=""
	testa_HSS_P=${11}
	if [ -n "$testa_HSS_P" ]; then
		json+=",
                        {
                           \"servico\":{
                              \"id\":\"HSS\"
                           },
                           \"operacao\":{
                              \"id\":\"CAN\"
                           }
                        }"
	fi

#	Se _5GNSA_N nao estiver vazia, escrever o bloco com 5GNSA.
	testa_5GNSA_N=""
	testa_5GNSA_N=${12}
	if [ -n "$testa_5GNSA_N" ]; then
		json+=",
                        {
                           \"servico\":{
                              \"id\":\"5GNSA\"
                           },
                           \"operacao\":{
                              \"id\":\"ACT\"
                           }
                        }"
	fi

#	Se _5GNSA_P nao estiver vazia, escrever o bloco com 5GNSA.
	testa_5GNSA_P=""
	testa_5GNSA_P=${13}
	if [ -n "$testa_5GNSA_P" ]; then
		json+=",
                        {
                           \"servico\":{
                              \"id\":\"5GNSA\"
                           },
                           \"operacao\":{
                              \"id\":\"CAN\"
                           }
                        }"
	fi

#	Se _5GSA_N nao estiver vazia, escrever o bloco com 5GSA.
	testa_5GSA_N=""
	testa_5GSA_N=${14}
	if [ -n "$testa_5GSA_N" ]; then
		json+=",
                        {
                           \"servico\":{
                              \"id\":\"5GSA\"
                           },
                           \"operacao\":{
                              \"id\":\"ACT\"
                           }
                        }"
	fi

#	Se _5GSA_P nao estiver vazia, escrever o bloco com 5GSA.
	testa_5GSA_P=""
	testa_5GSA_P=${15}
	if [ -n "$testa_5GSA_P" ]; then
		json+=",
                        {
                           \"servico\":{
                              \"id\":\"5GSA\"
                           },
                           \"operacao\":{
                              \"id\":\"CAN\"
                           }
                        }"
	fi
	
	echo "$json"
}	# Essa chave fecha o escreve_json

#--------------------------------------------------------------------------------------------

escreve_slice_json(){
#	$1 -> $slice_N_name_1
#	$2 -> $slice_N_id_1
#	$3 -> $slice_N_default_1
#	$4 -> $slice_N_name_2
#	$5 -> $slice_N_id_2
#	$6 -> $slice_N_default_2
#	$7 -> $slice_P_name_1
#	$8 -> $slice_P_id_1
#	$9->  $slice_P_default_1
#	$10 ->$slice_P_name_2
#	$11-> $slice_P_id_2
#	$12-> $slice_P_default_2

json_slice=""

#	Se slice_N_name_1 nao estiver vazia, escrever o bloco com SLICE.
	testa_slice_N_1=""
	testa_slice_N_1=$1
	if [ -n "$testa_slice_N_1" ]; then
		json_slice+=",
							{
								\"servico\":{
									\"id\":\"$1\"
								},
								\"operacao\":{
									\"id\":\"ACT\"
								},
								\"parametro\":[
									{
										\"nome\":\"SLICEID\",
										\"valor\":\"$2\"
									},
									{
										\"nome\":\"DEFAULT\",
										\"valor\":\"$3\"
									}
								]
							}"
	fi
	
#	Se slice_N_name_2 nao estiver vazia, escrever o bloco com SLICE.
	testa_slice_N_2=""
	testa_slice_N_2=$4
	if [ -n "$testa_slice_N_2" ]; then
		json_slice+=",
							{
								\"servico\":{
									\"id\":\"$4\"
								},
								\"operacao\":{
									\"id\":\"ACT\"
								},
								\"parametro\":[
									{
										\"nome\":\"SLICEID\",
										\"valor\":\"$5\"
									},
									{
										\"nome\":\"DEFAULT\",
										\"valor\":\"$6\"
									}
								]
							}"
	fi
	
#	Se slice_P_name_1 nao estiver vazia, escrever o bloco com SLICE.
	testa_slice_P_1=""
	testa_slice_P_1=$7
	if [ -n "$testa_slice_P_1" ]; then
		json_slice+=",
							{
								\"servico\":{
									\"id\":\"$7\"
								},
								\"operacao\":{
									\"id\":\"CAN\"
								},
								\"parametro\":[
									{
										\"nome\":\"SLICEID\",
										\"valor\":\"$8\"
									},
									{
										\"nome\":\"DEFAULT\",
										\"valor\":\"$9\"
									}
								]
							}"
	fi
	
#	Se slice_P_name_2 nao estiver vazia, escrever o bloco com SLICE.
	testa_slice_P_2=""
	testa_slice_P_2=${10}
	if [ -n "$testa_slice_P_2" ]; then
		json_slice+=",
							{
								\"servico\":{
									\"id\":\"${10}\"
								},
								\"operacao\":{
									\"id\":\"CAN\"
								},
								\"parametro\":[
									{
										\"nome\":\"SLICEID\",
										\"valor\":\"${11}\"
									},
									{
										\"nome\":\"DEFAULT\",
										\"valor\":\"${12}\"
									}
								]
							}"
	fi
	
	echo "$json_slice"
}	# Essa chave fecha o escreve_slice_json

#--------------------------------------------------------------------------------------------

escreve_dnn_json(){
#	$1  -> $dnn_N(P)
#	$2	-> ACT/CAN

	dnn_N=$1
	act_can=$2
	
	#							sed -n '1p' -> pega a primeira linha
	dnn_N_qtd=$(echo "$dnn_N" | sed -n '1p')
	#						sed '1d' -> apaga a primeira linha.
	dnn_N=$(echo "$dnn_N" | sed '1d')
	
	dnn_json=""  

	for ((i = 1; i <= $dnn_N_qtd; i++))
	do
		dnn=$(echo "$dnn_N" | sed -n '1p')
		dnn_N=$(echo "$dnn_N" | sed '1d')
		dnn_id=$(echo "$dnn_N" | sed -n '1p')
		dnn_N=$(echo "$dnn_N" | sed '1d')
		dnn_name=$(echo "$dnn_N" | sed -n '1p')
		dnn_N=$(echo "$dnn_N" | sed '1d')
		dnn_eqosid=$(echo "$dnn_N" | sed -n '1p')
		dnn_N=$(echo "$dnn_N" | sed '1d')
		dnn_ip=$(echo "$dnn_N" | sed -n '1p')
		dnn_N=$(echo "$dnn_N" | sed '1d')
		dnn_ipv4=$(echo "$dnn_N" | sed -n '1p')
		dnn_N=$(echo "$dnn_N" | sed '1d')
		dnn_ipv6=$(echo "$dnn_N" | sed -n '1p')
		dnn_N=$(echo "$dnn_N" | sed '1d')
		dnn_default=$(echo "$dnn_N" | sed -n '1p')
		dnn_N=$(echo "$dnn_N" | sed '1d')
		dnn_sliceid=$(echo "$dnn_N" | sed -n '1p')
		dnn_N=$(echo "$dnn_N" | sed '1d')

#		echo "$i"
#		echo "$dnn"
#		echo "$dnn_id"
#		echo "$dnn_name"
#		echo "$dnn_eqosid"
#		echo "$dnn_ip"
#		echo "$dnn_ipv4"
#		echo "$dnn_ipv6"
#		echo "$dnn_default"
#		echo "$dnn_sliceid"
	
	dnn_json+=",
                        {
                            \"servico\":{
                                \"id\":\"$dnn\"
                            },
                            \"operacao\":{
                                \"id\":\"$act_can\"
                            },
                            \"parametro\":[
                                {
                                    \"nome\":\"DNNID\",
                                    \"valor\":\"$dnn_id\"
                                },
                                {
                                    \"nome\":\"DNNNAME\",
                                    \"valor\":\"$dnn_name\"
                                },
                                {
                                    \"nome\":\"EQOSID\",
                                    \"valor\":\"$dnn_eqosid\"
                                },
                                {
                                    \"nome\":\"SCHAR\",
                                    \"valor\":\"1\"
                                },
                                {
                                    \"nome\":\"TIPOIP\",
                                    \"valor\":\"$dnn_ip\" 
                                },
                                {
                                    \"nome\":\"IPV4\",
                                    \"valor\":\"$dnn_ipv4\"
                                },
                                {
                                    \"nome\":\"IPV6\",
                                    \"valor\":\"$dnn_ipv6\"
                                },
                                {
                                    \"nome\":\"DEFAULT\",
                                    \"valor\":\"$dnn_default\"
                                },
                                {
                                    \"nome\":\"SLICEID\",
                                    \"valor\":\"$dnn_sliceid\"
                                }
                            ]
                        }"
	done

	echo "$dnn_json"
	
}	# Essa chave fecha o escreve_dnn_json

#--------------------------------------------------------------------------------------------

escreve_apn_json(){
#	$1  -> $apn_N(P)
#	$2	-> ACT/CAN

	apn_N=$1
	act_can=$2
	
	#							sed -n '1p' -> pega a primeira linha
	apn_N_qtd=$(echo "$apn_N" | sed -n '1p')
	#						sed '1d' -> apaga a primeira linha.
	apn_N=$(echo "$apn_N" | sed '1d')
	
	apn_json=""  

	for ((i = 1; i <= $apn_N_qtd; i++))
	do
		apn=$(echo "$apn_N" | sed -n '1p')
		apn_N=$(echo "$apn_N" | sed '1d')
		apn_id=$(echo "$apn_N" | sed -n '1p')
		apn_N=$(echo "$apn_N" | sed '1d')
		apn_name=$(echo "$apn_N" | sed -n '1p')
		apn_N=$(echo "$apn_N" | sed '1d')
		apn_eqosid=$(echo "$apn_N" | sed -n '1p')
		apn_N=$(echo "$apn_N" | sed '1d')
		apn_ip=$(echo "$apn_N" | sed -n '1p')
		apn_N=$(echo "$apn_N" | sed '1d')
		apn_ipv4=$(echo "$apn_N" | sed -n '1p')
		apn_N=$(echo "$apn_N" | sed '1d')
		apn_ipv6=$(echo "$apn_N" | sed -n '1p')
		apn_N=$(echo "$apn_N" | sed '1d')

#		echo "$i"
#		echo "$apn"
#		echo "$apn_eqosid"
#		echo "$apn_id"
#		echo "$apn_name"
#		echo "$apn_ip"
#		echo "$apn_ipv4"
#		echo "$apn_ipv6"
	
	apn_json+=",
						{
                            "servico":{
                                "id":"$apn"
                            },
                            "operacao":{
                                "id":"ACT"
                            },
                            "parametro":[
								{
									"nome":"EQOSID",
									"valor":"$apn_eqosid"
								},
                                {
                                    "nome":"APNID",
                                    "valor":"$apn_id"
                                },
								{
									"nome":"APNNAME",
									"valor":"$apn_name"
								},
                                {
                                    "nome":"TIPOIP",
                                    "valor":"$apn_ip" 
                                },
                                {
                                    "nome":"IPV4",
                                    "valor":"$apn_ipv4"
                                },
                                {
                                    "nome":"IPV6",
                                    "valor":"$apn_ipv6"
                                }
                            ]
                        }"
	done

	echo "$apn_json"
	
}	# Essa chave fecha o escreve_apn_json

#--------------------------------------------------------------------------------------------

fecha_json(){
	final="                    ]
                  }
               }
            }
         }
      ]
   }
}"
	echo "$final"
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
		
		lst_feature=$(extrai_lst_feature "$arquivo_origem")
		lst_feature_prev=$(extrai_lst_feature_prev "$arquivo_origem")
		
		req_id=$(extrai_req_id "$arquivo_origem")
		telefone=$(extrai_telefone "$arquivo_origem")
		imsi=$(extrai_imsi "$arquivo_origem")
		iccid=$(extrai_iccid "$lst_feature")
		acao=$(extrai_acao "$lst_feature")
		HLR_N=$(extrai_HLR "$lst_feature")
		HLR_P=$(extrai_HLR "$lst_feature_prev")
		profile_N=$(extrai_profile "$lst_feature")
		profile_P=$(extrai_profile "$lst_feature_prev")
		HSS_N=$(possui_feature "$lst_feature" "=HSS;")
		HSS_P=$(possui_feature "$lst_feature_prev" "=HSS;")
		_5GNSA_N=$(possui_feature "$lst_feature" "=5GNSA;")
		_5GNSA_P=$(possui_feature "$lst_feature_prev" "=5GNSA;")
		_5GSA_N=$(possui_feature "$lst_feature" "=5GSA;")
		_5GSA_P=$(possui_feature "$lst_feature_prev" "=5GSA;")
		slice_N=$(extrai_slice "$lst_feature")
		slice_N_name_1=$(echo "$slice_N" | sed -n '1p')
		slice_N_id_1=$(echo "$slice_N" | sed -n '2p')
		slice_N_default_1=$(echo "$slice_N" | sed -n '3p')
		slice_N_name_2=$(echo "$slice_N" | sed -n '4p')
		slice_N_id_2=$(echo "$slice_N" | sed -n '5p')
		slice_N_default_2=$(echo "$slice_N" | sed -n '6p')
		slice_P=$(extrai_slice "$lst_feature_prev")
		slice_P_name_1=$(echo "$slice_P" | sed -n '1p')
		slice_P_id_1=$(echo "$slice_P" | sed -n '2p')
		slice_P_default_1=$(echo "$slice_P" | sed -n '3p')
		slice_P_name_2=$(echo "$slice_P" | sed -n '4p')
		slice_P_id_2=$(echo "$slice_P" | sed -n '5p')
		slice_P_default_2=$(echo "$slice_P" | sed -n '6p')
		dnn_N=$(extrai_dnn "$lst_feature")
		dnn_P=$(extrai_dnn "$lst_feature_prev")
#		--
		apn_N=$(extrai_apn "$lst_feature")
		apn_P=$(extrai_apn "$lst_feature_prev")
#		--		
		
		echo "------------------------"
		echo "$nome_arquivo"
#		echo "REQ_ID: $req_id"
#		echo "Acao: $acao"
#		echo "Telefone: $telefone"
#		echo "IMSI: $imsi"
#		echo "ICCID: $iccid"
#		echo "HLR_N: $HLR_N"
#		echo "HLR_P: $HLR_P"
#		echo "profile_N: $profile_N"
#		echo "profile_P: $profile_P"
#		echo "HSS_N:----$HSS_N"
#		echo "HSS_P:----$HSS_P"
#		echo "5GNSA_N:--$_5GNSA_N"
#		echo "5GNSA_P:--$_5GNSA_P"
#		echo "5GSA_N:---$_5GSA_N"
#		echo "5GSA_P:---$_5GSA_P"
#		echo "SLICE_N: $slice_N"
#		echo "SLICE_P: $slice_P"
#		if [ "$nome_arquivo" = "T0050_004" ]; then
			echo "----------------------------------------$nome_arquivo----------------------------------------$"
#			echo "slice N: $slice_N_name_1 $slice_N_id_1 $slice_N_default_1 / $slice_N_name_2 $slice_N_id_2 $slice_N_default_2"
#			echo "slice P: $slice_P_name_1 $slice_P_id_1 $slice_P_default_1 / $slice_P_name_2 $slice_P_id_2 $slice_P_default_2"
#			echo "$dnn_N"
#			echo "$dnn_P"
#			echo "--------- apn_New"
#			echo "$apn_N"
#			echo "--------- apn_Prev"
#			echo "$apn_P"
#		fi
#		echo "$dnn_N_qtd"
#
#
#		echo "------------------------"
#		echo "lst_feature: $lst_feature"
#		echo "------------------------"
#		echo "lst_feature_prev: $lst_feature_prev"
#		echo "------------------------"

		#Funcao1 	  $1		$2		$3			$4		 $5		 $6		  $7	   $8			$9			 ${10}	  ${11}	   ${12}	   ${13}	   ${14}	  ${15}
		escreve_json "$req_id" "$acao" "$telefone" "$iccid" "$imsi" "$HLR_N" "$HLR_P" "$profile_N" "$profile_P" "$HSS_N" "$HSS_P" "$_5GNSA_N" "$_5GNSA_P" "$_5GSA_N" "$_5GSA_P"  > $arquivo_destino
		
		#Funcao2	 	  	$1				  $2			  $3				   $4				 $5			     $6					  $7				$8				$9					 ${10}			   ${11}		   ${12}
		escreve_slice_json "$slice_N_name_1" "$slice_N_id_1" "$slice_N_default_1" "$slice_N_name_2" "$slice_N_id_2" "$slice_N_default_2" "$slice_P_name_1" "$slice_P_id_1" "$slice_P_default_1" "$slice_P_name_2" "$slice_P_id_2" "$slice_P_default_2" >> $arquivo_destino

		#Funcao3		  $1	   $2
		escreve_dnn_json "$dnn_N" "ACT" >> $arquivo_destino
		escreve_dnn_json "$dnn_P" "CAN" >> $arquivo_destino

		#Funcao4
		escreve_apn_json "$apn_N" "ACT" >> $arquivo_destino
		escreve_apn_json "$apn_P" "CAN" >> $arquivo_destino

		#Funcao5
		fecha_json >> $arquivo_destino
		
    fi
done

echo "------------------------"
echo "Processo concluido"

# ------------------------------------------------------------------------ #
