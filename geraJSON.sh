#!/usr/bin/env bash
#
# ------------------------------------------------------------------------ #
# geraJSON - 	Transforma um teste que insere na sps_solicitacao em 
#				teste de interface
# Autor:      Rafael Oliveira
# Manutencao: Rafael Oliveira
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
#	v1.13 28/09/2023, Rafael:
#		- Melhorado extrai_slice para funcionar dinamicamente
#		- Ajustado escreve_apn_json para imprimir as aspas
#	v1.14 28/09/2023, Rafael:
#		- Ajustado bug no act/prev do escreve_apn_json
#		- Alterado variavel telefone para msisdn
#		- Melhorado extrai_msisdn e extrai_imsi para buscar valor na 
#		lst_feature
#		- Melhorado a remocao do ".sql" do nome do arquivo
#		- Melhorado extrai_feature para aproveitar o codigo de 
#		possui_feature
#	v1.15 18/10/2023, Rafael:
#		- Adicionado condicional no escreve_apn_json e escreve_dnn_json
#		para só escrever os campos ipv4 e ipv6 quando for necessário
#		- Resolvido bug do extrai_slice, extrai_dnn e extrai_apn para 
#		que a contagem não seja duplicada
# ------------------------------------------------------------------------ #
# Testado em:
#	4.1.2(1)-release (x86_64-redhat-linux-gnu)
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

# ------------------------------- FUNCOES -------------------------------- #

extrai_req_id(){
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
        echo "$req_id"
}

# ------------------------------------------------------------------------ #

extrai_msisdn(){
	msisdn=$(extrai_feature "$1" "MSISDN=")
	echo $msisdn
}

# ------------------------------------------------------------------------ #

extrai_imsi(){
	imsi=$(extrai_feature "$1" "IMSI=")
	echo $imsi
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
	lista_slice=$(possui_feature "$lista_feature" "=SLICE")
	
	# Seleciona as SLICE da lst_feature(_prev)
	#lista_slice=$(echo "$slice" | cut -c7-14)
	
	#Conta o numero de slice
	num_slice=$(echo "$lista_slice" | grep -o "FTRCD=SLICE" | wc -l)
	contador=1
	limite=($num_slice)
	((limite++))
	declare -a slice
	
	echo "$num_slice"
	while [ "$contador" -lt "$limite" ]; do

		linha=$(echo "$lista_slice" | sed -n "${contador}p")
		
		slice=$(extrai_feature "$linha" "FTRCD=")
		slice_id=$(extrai_feature "$linha" "SLICEID=")
		slice_default=$(extrai_feature "$linha" "DEFAULT=")
		echo "$slice"
		echo "$slice_id"
		echo "$slice_default"

		((contador++))
	done
}

# ------------------------------------------------------------------------ #

extrai_dnn(){
	# $1 -> lst_feature(_prev)
	lista_feature=$1
	lista_dnn=$(possui_feature "$lista_feature" "=DNN")
	
	#Conta o numero de dnn
	num_dnn=$(echo "$lista_dnn" | grep -o "FTRCD=DNN" | wc -l)
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
	num_apn=$(echo "$lista_apn" | grep -o "FTRCD=APN0" | wc -l)
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

	# Loop para ler cada linha do arquivo
	while IFS= read -r linha; do
		# Verifica se a linha contém "FTRCD" ou "CUSTOMER"
		if [[ "$linha" == *"FTRCD"* || "$linha" == *"CUSTOMER"* ]]; then
			# Adiciona a linha à variável
			linhas_ftrcd="${linhas_ftrcd}${linha}\n"
		fi
	done < "$arquivo"

	feature="FTRCD"
	feature+="${linhas_ftrcd#*FTRCD}"
	
    # Retorna as linhas_ftrcd contendo "FTRCD" ou "CUSTOMER"
    echo -e "$feature"
}

# ------------------------------------------------------------------------ #

extrai_lst_feature() {
	lst_FTRCD=$(extrai_FTRCD $1)
	
	# Substring pré-determinada que sera encontrada
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
#	$1 -> $lst_feature(_prev)
#	$2 -> $feature (HLR, IMSI etc)
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
#	$2 -> $feature (HLR, IMSI etc)
	lista_feature=$1
	feature=$2
	
	linha=$(possui_feature "$lista_feature" "$feature")

	#Extrair o valor da feature
	valor=$(echo "$linha" | sed -n "s/.*$feature\([^;]*\).*/\1/p")
	echo "$valor"
}

# ------------------------------------------------------------------------ #

escreve_json(){
#	$1 -> $req_id
#	$2 -> $acao
#	$3 -> $msisdn
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

# ------------------------------------------------------------------------ #

escreve_slice_json(){
#	$1  -> $slice_N
#	$2	-> ACT/CAN

	slice_N=$1
	act_can=$2
	#								sed -n '1p' -> pega a primeira linha
	slice_N_qtd=$(echo "$slice_N" | sed -n '1p')
	#							sed '1d' -> apaga a primeira linha.
	slice_N=$(echo "$slice_N" | sed '1d')
	slice_json=""  
	if [ -n "$slice_N" ]; then
		for ((i = 1; i <= $slice_N_qtd; i++))
		do
			slice=$(echo "$slice_N" | sed -n '1p')
			slice_N=$(echo "$slice_N" | sed '1d')
			slice_id=$(echo "$slice_N" | sed -n '1p')
			slice_N=$(echo "$slice_N" | sed '1d')
			slice_default=$(echo "$slice_N" | sed -n '1p')
			slice_N=$(echo "$slice_N" | sed '1d')
			
			slice_json+=",
							{
								\"servico\":{
									\"id\":\"$slice\"
								},
								\"operacao\":{
									\"id\":\"$act_can\"
								},
								\"parametro\":[
									{
										\"nome\":\"SLICEID\",
										\"valor\":\"$slice_id\"
									},
									{
										\"nome\":\"DEFAULT\",
										\"valor\":\"$slice_default\"
									}
								]
							}"
		done
		echo "$slice_json"
	fi
}	# Essa chave fecha o escreve_slice_json

# ------------------------------------------------------------------------ #

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
                                }"

#	Se dnn_ipv4 nao estiver vazia, escrever o bloco com dnn_ipv4.
		testa_dnn_ipv4=""
		testa_dnn_ipv4=$dnn_ipv4
		if [ -n "$testa_dnn_ipv4" ]; then
			json+=",
                                {
                                    \"nome\":\"IPV4\",
                                    \"valor\":\"$dnn_ipv4\"
                                }"
		fi

#	Se dnn_ipv6 nao estiver vazia, escrever o bloco com dnn_ipv6.
		testa_dnn_ipv6=""
		testa_dnn_ipv6=$dnn_ipv6
		if [ -n "$testa_dnn_ipv6" ]; then
			dnn_json+=",
                                {
                                    \"nome\":\"IPV6\",
                                    \"valor\":\"$dnn_ipv6\"
                                }"
		fi
		dnn_json+=",
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

# ------------------------------------------------------------------------ #

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
		
		apn_json+=",
						{
                            \"servico\":{
                                \"id\":\"$apn\"
                            },
                            \"operacao\":{
                                \"id\":\"$act_can\"
                            },
                            \"parametro\":[
								{
									\"nome\":\"EQOSID\",
									\"valor\":\"$apn_eqosid\"
								},
                                {
                                    \"nome\":\"APNID\",
                                    \"valor\":\"$apn_id\"
                                },
								{
									\"nome\":\"APNNAME\",
									\"valor\":\"$apn_name\"
								},
                                {
                                    \"nome\":\"TIPOIP\",
                                    \"valor\":\"$apn_ip\" 
                                }"
#	Se apn_ipv4 nao estiver vazia, escrever o bloco com apn_ipv4.
	testa_apn_ipv4=""
	testa_apn_ipv4=$apn_ipv4
		if [ -n "$testa_apn_ipv4" ]; then
			apn_json+=",
                                {
                                    \"nome\":\"IPV4\",
                                    \"valor\":\"$apn_ipv4\"
                                }"
		fi

#	Se apn_ipv6 nao estiver vazia, escrever o bloco com apn_ipv6.
	testa_apn_ipv6=""
	testa_apn_ipv6=$apn_ipv6
		if [ -n "$testa_apn_ipv6" ]; then
			apn_json+=",
                                {
                                    \"nome\":\"IPV6\",
                                    \"valor\":\"$apn_ipv6\"
                                }"
		fi
		apn_json+="
                            ]
                        }"
	done
	echo "$apn_json"
}	# Essa chave fecha o escreve_apn_json

# ------------------------------------------------------------------------ #

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
	# Verifica se o arquivo existe
	if [ -f "$arquivo_origem" ]; then
		# Obtém o nome do arquivo sem o caminho
		nome_arquivo=$(basename "$arquivo_origem")
		
		# Remove o .sql
		nome_arquivo="${nome_arquivo%????}"
		
		# Cria o caminho completo para o arquivo de destino no subdiretório
		arquivo_destino="$subdiretorio_destino/$nome_arquivo.js"
		
		# Cria o arquivo
		touch "$arquivo_destino"
		
		# Atribui valor as variaveis
		lst_feature=$(extrai_lst_feature "$arquivo_origem")
		lst_feature_prev=$(extrai_lst_feature_prev "$arquivo_origem")
		req_id=$(extrai_req_id "$arquivo_origem")
		msisdn=$(extrai_msisdn "$lst_feature")
		imsi=$(extrai_imsi "$lst_feature")
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
		slice_P=$(extrai_slice "$lst_feature_prev")
		dnn_N=$(extrai_dnn "$lst_feature")
		dnn_P=$(extrai_dnn "$lst_feature_prev")
		apn_N=$(extrai_apn "$lst_feature")
		apn_P=$(extrai_apn "$lst_feature_prev")
		
		echo "# ------------------------------$nome_arquivo----------------------------- #"
#		echo "REQ_ID: $req_id"
#		echo "ACAO: $acao"
#		echo "MSISDN: $msisdn"
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
#		if [ "$nome_arquivo" = "T9999_999" ]; then
#			echo "-----SLICE N-----"
#			echo "$slice_N"
#			echo "-----SLICE P-----"
#			echo "$slice_P"
#			echo "-----------------"
#			echo "-----DNN N-----"
#			echo "$dnn_N"
#			echo "-----DNN P-----"
#			echo "$dnn_P"
#			echo "-----APN N-----"
#			echo "$apn_N"
#			echo "-----APN P-----"
#			echo "$apn_P"
#			echo "-----------------"
#		fi
#		echo "------lst_feature------"
#		echo "$lst_feature"
#		echo "------------------------"
#		echo "----lst_feature_prev----"
#		echo "$lst_feature_prev"
#		echo "------------------------"

		# Gerar JSON
		#Funcao1 	  $1		$2		$3		  $4	   $5	   $6	    $7		 $8			  $9		   ${10}	${11}	 ${12}	     ${13}	  	 ${14}		${15}
		escreve_json "$req_id" "$acao" "$msisdn" "$iccid" "$imsi" "$HLR_N" "$HLR_P" "$profile_N" "$profile_P" "$HSS_N" "$HSS_P" "$_5GNSA_N" "$_5GNSA_P" "$_5GSA_N" "$_5GSA_P"  > $arquivo_destino

		#Funcao 2, 3 e 4 escrevendo primeiro o NEW e depois o PREV do APN, SLICE e DNN
		escreve_apn_json "$apn_N" "ACT" >> $arquivo_destino
		escreve_slice_json "$slice_N" "ACT" >> $arquivo_destino
		escreve_dnn_json "$dnn_N" "ACT" >> $arquivo_destino

		escreve_apn_json "$apn_P" "CAN" >> $arquivo_destino
		escreve_slice_json "$slice_p" "CAN" >> $arquivo_destino
		escreve_dnn_json "$dnn_P" "CAN" >> $arquivo_destino

		#Funcao5
		fecha_json >> $arquivo_destino
    fi
done
echo "# -------------------------------------------------------------------- #"
echo "# --------------------------Processo concluido------------------------ #"
echo "# -------------------------------------------------------------------- #"
# ------------------------------------------------------------------------ #