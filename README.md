# Configura credenciais de acesso MFA para acesso via awscli

## Padrão para utilização - Configuração obrigatoria ~/.aws/credentials

Para cada perfil criado que utilize MFA, esse deve possuir a no final do nome do perfil o seguinte valor: `_mfa`
Segue exemplo:

```
[conta_mfa]
aws_access_key_id=<access key id>
aws_secret_access_key=<secret access key>
```

### Depedencias

É necessário instalar o pacote `jq` em seu sistema linux.

```
sudo apt install jq -y
```

ou

```
sudo apt yum install jq -y
```

### O que ele faz ?

Ao informar a conta (parametro obrigatorio), o script identifica qual perfil utilizar e criar um outro perfil com acesso temporario, sem o valor `_mfa` ao final do nome do perfil e assim se consegue utilizar varios perfis de acesso de MFA automaticamente

## Exemplo de utilização

```
./getTokenAWS.sh [-u <username>] [-p <profile>] [-d <duration time in seconds>] [-t <token mfa>] | [-h]
```

### Dicas

- Não esquecer de dar permissão de execução ao script: `chmod u+x getTokenAWS.sh`

## Vantagens de Uso

A configuração do cli simples e bem documentada, mas o uso de MFA pode dar trabalho para manutenção do arquivo de credenciais ou configuração via variaveis de ambiente e com isso houve a motivação para criação desse script que manipula as credenciais sempre que necessario facilitado assim o uso do awscli, mesmo com várias contas de acesso.
