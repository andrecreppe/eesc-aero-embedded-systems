# Execução do Projeto

## 1. Instalação das Bibliotecas Lely-core

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

3. Execute a sequência de configuração e compilação das bibliotecas em C++ para arm.

    ```bash
    $ autoreconf -i

    $ mkdir -p build && cd build

    $ ./configure --disable-cython

    $ make

    $ sudo make install
    ```

## 2. Criação do Docker

Navegando de volta para a pasta do dockerfile, execute o arquivo _Dockerfile_ para a criação do container Debian.

```bash
$ cd ../../

$ docker build . -t build_manopla -f ./Dockerfile
```

Após a criação do sistema de forma bem-sucedida, volte para a raíz do projeto e instancie o container copiando o projeto inteiro para uma pasta denominada "projeto".

```bash
$ cd ..

$ docker run --rm -it -v $(pwd):/projeto build_manopla bash
```

Essa última operação pode demorar um pouco, dependendo da máquina do usuário, porém assim que for concuida o container estará aberto pode-se trabalhar dentro dele.

## 3. Compilação Cruzada do Código Fonte

Agora dentro do container, navegaremos até a pasta "projeto" a qual contém os arquivos fonte e realizaremos a compilação do mesmo para a arquitetura "arm64" desejada.

```bash
$ cd /projeto

$ mkdir build_arm && cd build_arm

$ cmake -DARM_TARGET=1 ..

$ make
```

Para checar se a compilação foi bem-sucedida, execute o seguinte comando para verificar as propriedades do executável que acabou de ser gerado (segue abaixo do comando um exemplo de resposta esperada).

```bash
$ file eesc-aero-embedded-systems

eesc-aero-embedded-systems: ELF 32-bit LSB pie executable, ARM, EABI5 version 1 (GNU/Linux), dynamically linked, interpreter /lib/ld-linux-armhf.so.3, BuildID[sha1]=4b45a7d6be21fbbb5549f8df6f8c295996a03a85, for GNU/Linux 3.2.0, with debug_info, not stripped
```
Para finalmente enviar o executável dentro do container para o nosso sistema embarcado, primeiro precisamos garantir que ambos os dispositivos estão conectados a mesma rede de internet. Ademais, precisa-se saber o IP de conexão do dispositivo de destino bem como o seu usuário padrão de conexão.

```bash
$ scp [source username@IP]:/[directory and file name] [destination username@IP]:/[destination directory]
```

- Exemplo: gostariamos de enviar o arquivo "eesc-aero-embedded-systems" para a pasta "Documents" na Raspberry conectada no endereço "192.168.0.15" utilizando o usuário "glauco".

    ```bash
    $ scp ./eesc-aero-embedded-systems glauco@192.168.0.15:~/Documents
    ```
