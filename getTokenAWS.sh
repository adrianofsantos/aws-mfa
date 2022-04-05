#!/bin/bash

usage     () { echo "USAGE: $0 [-u <username>] [-p <profile>] [-d <duration time in seconds>] | [-h] | [-c]" ; exit 1 ; }
help      () { echo -e "Utilitario para geração de acesso temporario para awscli.\n\
  -u: Username\n  -d: Duração (em secundos) da chave temporaria\n  -p: Nome do profile configurado no arquivo credentials\n\
  -t: Token MFA\n  -h: Essa descrição de uso\n  -c: Configura valores default em arquivo para variaveis com username e duração da chave\n\
  -a: Configura nomes de profiles com ID de contas AWS"; exit 0 ; }
configure () {  \
  echo "Informe o usuario default" ; read user ; echo "Informe a duração (em secundos) do token temporario" ; read duration ; \
  if [ -f $HOME/.gettokenaws/config ] ; then 
    sed -i "s/\(AWSUSER=\).*/\1${user}/" $HOME/.gettokenaws/config; sed -i "s/\(AWSDURATIONSECONDS=\).*/\1${duration}/"  $HOME/.gettokenaws/config
  else 
    mkdir -pv $HOME/.gettokenaws/  ; touch $HOME/.gettokenaws/config ; echo -e "AWSUSER=${user}\nAWSDURATIONSECONDS=${duration}" | tee $HOME/.gettokenaws/config 
    echo -e "Conta=123456789012\nConta2=123456789012\nConta3=123456789012" | tee -a $HOME/.gettokenaws/config
  fi 
  echo "Variaveis criadas" ; exit 0 ; }
#TODO refatorar codigo para setar dinamicamente as contas 
#accounts () { if [ -f $HOME/.gettokenaws/config ] then; exit 0 ; }

if [ -f $HOME/.gettokenaws/config ] ; then
  . $HOME/.gettokenaws/config
  username=${AWSUSER}
  durationSeconds=${AWSDURATIONSECONDS}
fi

while getopts ":u:d:p:t:h:c:a:" option; do
  case "${option}" in
    u)
      username=$OPTARG}
      ;;
    d)
      durationSeconds=${OPTARG}
      ;;
    p)
      profile=${OPTARG}
      ;;
    t)
      tokenCode=${OPTARG}
      ;;
    h)
      help;
      ;;
    c)
      configure;
      ;;
    *)
      usage;
      ;;
    :)
      echo "Invalid Argument"
      usage
      ;;
  esac
done
shift $((OPTIND -1))

if [ -z $username ] || [ -z $tokenCode ] || [ -z $profile ]  ; then
  usage
fi

account=$(awk -v p=$profile -F= '$1==p {print $2}' $HOME/.gettokenaws/config)

# Testa se a duração é menor que 15 minutos (900 secundos) para evitar erro na requisição da sessão
if [ ${durationSeconds} -lt 900 ]; then
  durationSeconds=900
  echo -e "Duração da sessão menor que o permitido. Alterando automaticamente para o tempo minimo de criação da sessão, 15 minutos."
fi

# getSessionToken
json=$(aws sts get-session-token --serial-number arn:aws:iam::$account:mfa/${username} --token-code ${tokenCode} --duration-seconds ${durationSeconds} --profile ${profile}_mfa  --output json)
if [ $? -ne 0  ]; then
  exit 1
fi

aws configure set --profile $profile aws_access_key_id $(echo ${json} |  jq .Credentials.AccessKeyId | sed 's/"//g')
aws configure set --profile $profile aws_secret_access_key $(echo ${json} | jq .Credentials.SecretAccessKey | sed 's/"//g')
aws configure set --profile $profile aws_session_token $(echo ${json} | jq .Credentials.SessionToken | sed 's/"//g')

# Saida de sucesso da operação de geração de sessão para uso do awscli
echo -e 'Expiração da sessão em: '$(echo ${json} | jq .Credentials.Expiration | xargs date -d)
exit 0
