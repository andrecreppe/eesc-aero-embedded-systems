# Projeto Final da Disciplina

Projeto para a disciplina de _Sistemas Embarcados para Veículos Aéreos_ (SAA0356), realizada durante o 2o semestre de 2024, sob mentoria do Professor Glauco Caurin.


## Autores

- André Zanardi Creppe (11802972)
- Gabriel de Oliveira Maia (11819790)
- Pedro Lenci de Souza Aguiar (11802519)
- Victor Henrique D'Avila (11821521)


## Sobre o Projeto

A partir do código fonte do projeto de pesquisa [eesc-aero-embedded-systems](https://github.com/griloHBG/eesc-aero-embedded-systems), a proposta do projeto da disciplina era de realizar mudanças no código ou na forma de compilação para explorar o ambiente de sistemas embarcados reais.

Dessa forma, o grupo propôs como principal alteração a troca da placa de desenvolvimento _Beaglebone Black_ (arquitetura arm) para uma **Raspberry Pi 3** (arm64). Tal alteração nos obrigou a pesquisar e atualizar as bibliotecas do nosso container e outros arquivos automáticos de compiação. O objetivo do grupo é incluir ao projeto _eesc-aero-embedded-systems_ a possiblidade de se realizar o teste em outras placas de desenvolvimento com arquitetura de 64 bits.


## Execução do Projeto

### 1. Instalação das Bibliotecas Lely-core

Para realizar a compilação do código-fonte, precisamos garantir que as bibliotecas da [Lely-core](https://github.com/lely-industries/lely-core) estão instaladas na nossa máquina Linux principal. O tutorial completo e expandido para outros sitemas operacionais (como Windows) e de destino (arm 32-bits) se encontra na [documentação](https://opensource.lely.com/canopen/docs/cross-compilation/) da prórpria Lely-core, porém abaixo podemos encontrar a sequência de comandos necessários compilados de forma resumida.

1. Certifique-se que você possui as ferramentas de desenvolvimento instaladas na sua máquina.

    - GNU Build System (configure, make, make install)
    - autotools (autoconf, automake and libtool)
    - Toolchain:
        ```bash
        $ sudo apt-get install crossbuild-essential-arm64
        ```

2. Começando da raíz do projeto, clone o repositório da Lely-core dentro da pasta _dockerfile_ e acesse a sua pasta.

    ```bash
    $ cd /dockerfile

    $ git clone https://gitlab.com/lely_industries/lely-core.git

    $ cd lely-core
    ```

3. Execute a sequência de configuração e compilação das bibliotecas em C++ para arm64.

    ```bash
    $ autoreconf -i

    $ mkdir -p build && cd build

    $ ../configure --host=aarch64-linux-gnu --disable-python

    $ make

    $ sudo make install
    ```

### 2. Criação do Docker

Navegando de volta para a pasta do dockerfile, execute o arquivo _Dockerfile_ para a criação do container Debian.

```bash
$ cd ../../

$ docker build . -t build_manopla_64 -f ./Dockerfile_64
```

Após a criação do sistema de forma bem-sucedida, volte para a raíz do projeto e instancie o container copiando o projeto inteiro para uma pasta denominada "projeto".

```bash
$ cd ..

$ docker run --rm -it -v $(pwd):/projeto build_manopla_64 bash
```

Essa última operação pode demorar um pouco, dependendo da máquina do usuário, porém assim que for concuida o container estará aberto pode-se trabalhar dentro dele.

### 3. Compilação Cruzada do Código Fonte

Agora dentro do container, navegaremos até a pasta "projeto" a qual contém os arquivos fonte e realizaremos a compilação do mesmo para a arquitetura "arm64" desejada.

```bash
$ cd /projeto

$ mkdir build_arm64 && cd build_arm64

$ cmake -DARM64_TARGET=1 ..

$ make
```

Para checar se a compilação foi bem-sucedida, execute o seguinte comando para verificar as propriedades do executável que acabou de ser gerado (segue abaixo do comando um exemplo de resposta esperada).

```bash
$ file eesc-aero-embedded-systems

eesc-aero-embedded-systems: ELF 64-bit LSB pie executable, ARM aarch64, version 1 (GNU/Linux), dynamically linked, interpreter /lib/ld-linux-aarch64.so.1, BuildID[sha1]=b2ccb23c64d4db758b0113ce1929e05d85969ebe, for GNU/Linux 3.7.0, with debug_info, not stripped
```
Para finalmente enviar o executável dentro do container para o nosso sistema embarcado, primeiro precisamos garantir que ambos os dispositivos estão conectados a mesma rede de internet. Ademais, precisa-se saber o IP de conexão do dispositivo de destino bem como o seu usuário padrão de conexão.

```bash
$ scp [source username@IP]:/[directory and file name] [destination username@IP]:/[destination directory]
```

- Exemplo: gostariamos de enviar o arquivo "eesc-aero-embedded-systems" para a pasta "Documents" na Raspberry conectada no endereço "192.168.0.15" utilizando o usuário "glauco".

    ```bash
    $ scp ./eesc-aero-embedded-systems glauco@192.168.0.15:~/Documents
    ```

### 4. Preparo da Raspberry

Antes de testar a execução do código, precisamos garantir que as bibliotecas utilizadas no projeto estão instaladas na Raspberry também.Com o container _ainda em execução_, vamos enviar as bibliotecas da lely-core compiladas para arm64 para a Raspberry utilizando novamente o comando `scp`.

Para isso, retorne a raiz do container e envie a pasta lely-core para o caminho desejado na Raspberry.

```bash
$ cd ../../

$ scp -r ./lely-core/ <USERNAME>@<IP>:<PASTA_DESTINO_LELYCORE>
$ scp -r ./lely-core/ glauco@192.168.0.15:~/Documents
```

Caso queira-se copiar tais binários para a máquina padrão do usuário, basta identificar o container em execução utilizando `docker ps` e copiar essa pasta para fora do container.

```bash
$ docker ps

$ docker cp <NOME_CONTAINER>:/lely-core <CAMINHO_MAQUINA_USUARIO>
$ docker cp pedantic_liskov:/lely-core /home/kali/Documents/lely-core
```

Agora, _encerre a execução do container_ e retorne ao sistema operacional padrão. Para facilitar a instalação das bibliotecas matemáticas, fora preparado um arquivo shell contendo todas as rotinas necessárias a serem executadas Raspberry, o qual se encontra na pasta "raspberry" na árvore do projeto.

Dessa forma, envie o arquivo utilizando novamente o comando `scp`

```bash
$ scp ./raspberry/libs_install.sh glauco@192.168.0.15:~/Documents
```

e, dentro de um terminal (remoto ou direto) da Raspberry, dê permissão de execução ao arquivo e o execute como administrador.

```bash
$ cd ~/Documents

$ sudo chmod +x ./libs_install.sh

$ sudo ./libs_install.sh
```


### 5. Executar o Programa

Depois do código ter sido compilado para ARM64, enviado para a Raspberry junto com as bibliotecas da lely-core, e as demais bibliotecas instaladas utilizando o script shell, finalmente podemos executar o nosso programa.

Porém antes de rodar o programa em si, é necessário adicionar a uma das variáveis de ambiente o caminho das bibliotecas da lely-core, enviadas no começo do item #4. Para isso, adicione ao `LD_LIBRARY_PATH` o caminho definido anteriormente.

```bash
$ export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:<PASTA_DESTINO_LELYCORE>/lely-core/install-arm64-docker-debian-11/lib
$ export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/home/glauco/Documents/lely-core/install-arm64-docker-debian-11/lib
```

Por fim, execute o código compilado, e se tudo tiver sido feito corretamente, uma mensagem de "Hello, World!" deve aparecer!

```bash
$ ./eesc-aero-embedded-systems
```


## Problemas Comuns

Segue abaixo uma lista com perguntas que ajudam a entender e resolver problemas comuns encontrados ao seguir o passo-a-passo para a execução do projeto:

- As bibliotecas foram corretamente instaladas?
- Você está na pasta certa?
- Você encaminhou os caminhos pra pasta certa?
- O Raspberry está ligado na alimentação e conectado à rede?


## Agradecimentos

Agradecemos ao professor Glauco pela ideia desafiadora e "hands-on" do projeto. Agradecemos ao Henrique/Grilo pelo código e pela imensa ajuda e apoio a resvoler os bugs e desbravar as formas de realizar o projeto.

