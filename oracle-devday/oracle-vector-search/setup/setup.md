# 환경 준비 - 로컬에 직접설치 (선택사항)

## Introduction

본 실습에 필요한 도구들이 개인 실습 PC에 설치되지 않은 경우 이하 Task들을 따라 설치합니다.

*Lab 1: 환경 준비 - Base 이미지 기반으로 진행하는 경우 건너 뜁니다.* 

실습에 필요한 도구 목록:

* Docker CLI (OS에 따라 Docker Desktop 또는 Rancher Desktop 설치)
* Ollama
* Python
* Git
* Visual Studio Code

*이미 설치된 경우 각 Task 끝에 있는 이미지, 모델 다운로드 작업만 수행합니다.*

실습 예상 시간: 10분

## Task 1: Docker CLI & 이미지 다운로드

1. 사용할 PC의 OS와 라이센스를 고려하여, 각자 선택하여 설치합니다.

    - [Docker Desktop](https://www.docker.com/products/docker-desktop/)
    - [Rancher Desktop](https://rancherdesktop.io/)
    - [Docker Engine](https://docs.docker.com/engine/install/)

    - 설치 예시

        * Linux - Oracle Linux 8,9

            ```bash
            <copy>    
            sudo yum install -y yum-utils
            sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
            
            sudo yum install -y docker-ce docker-ce-cli containerd.io
            
            sudo systemctl start docker
            sudo systemctl enable docker
            
            sudo usermod -aG docker $USER
            newgrp docker
            </copy>
            ```

            ```bash
            # Visual Studio Code - Remote SSH를 사용하고 있다면, 새 docker 그룹의 반영을 위해 vscode-server 재시작합니다.
            # https://github.com/microsoft/vscode-remote-release/issues/5813
            <copy> 
            ps uxa | grep .vscode-server | awk '{print $2}' | xargs kill -9
            </copy> 
            ```

2. 컨테이너가 잘 기동하는 지 확인합니다.

    ```bash
    <copy>
    docker run hello-world
    </copy>
    ```

3. Oracle AI Database 26ai Free 컨테이너 이미지 다운로드

    - [Oracle Database Free](https://container-registry.oracle.com/ords/f?p=113:4:5584340787588:::4:P4_REPOSITORY,AI_REPOSITORY,AI_REPOSITORY_NAME,P4_REPOSITORY_NAME,P4_EULA_ID,P4_BUSINESS_AREA_ID:1863,1863,Oracle%20Database%20Free,Oracle%20Database%20Free,1,0&cs=33ik6GYF_z4Zq66Qe9NBkb8UT7E51RmD_gBF8B8Lsf2mjLMJme3LDj458VtCPQZTZ9LPaDwUIJgne4yHnVkvUBA)

    ```bash
    <copy>      
    docker pull container-registry.oracle.com/database/free:23.26.0.0
    </copy>    
    ```

## Task 2: Ollama 설치 & 모델 다운로드

1. Ollama를 다운로드 사이트로 이동하여, 각 OS 가이드에 따라 설치합니다.

	[Download Ollama](https://ollama.com/download)

    - 설치예시

        * Linux 기준

            ```bash
            <copy>      
            curl -fsSL https://ollama.com/install.sh | sh
            </copy>    
            ```

2. 실습시 사용할 Text Embedding 모델을 미리 다운로드 받습니다.

    ```bash
    <copy>      
    ollama pull paraphrase-multilingual:latest
    </copy>    
    ```

3. 실습시 사용할 LLM 모델 미리 다운로드하고 실행합니다.

    ```bash
    <copy>      
    ollama pull llama3.1
    ollama run llama3.1

    # CPU Only
    ollama run llama3.2
    ollama run llama3.2:1b
    </copy>    
    ```

4. 호출 테스트합니다.

    - Linux 기준

        ```bash
        <copy>
        curl -v http://localhost:11434/api/embeddings \
          -H "Content-Type: application/json" \
          -d '{"model":"paraphrase-multilingual","prompt":"hello"}'
        </copy>
        ```

        ```bash
        <copy>
        curl -v http://localhost:11434/api/generate \
          -H "Content-Type: application/json" \
          -d '{"model":"llama3.1","prompt":"Why is the sky blue?"}'
        </copy>
        ```

    - Windows 기준: PowerShell에서 실행합니다.

        ```powershell
        <copy>
        (Invoke-WebRequest -method POST -Body '{"model":"paraphrase-multilingual", "prompt":"hello", "stream": false}' -uri http://localhost:11434/api/embeddings ).Content | ConvertFrom-json
        </copy>
        ```

        ```powershell
        <copy>
        (Invoke-WebRequest -method POST -Body '{"model":"llama3.1", "prompt":"Why is the sky blue?", "stream": false}' -uri http://localhost:11434/api/generate ).Content | ConvertFrom-json
        </copy>
        ```

4. Linux 기준 다음을 추가 작업합니다.

    - 다음 파일을 엽니다.

        ```bash
        <copy>      
        sudo vi /etc/systemd/system/ollama.service
        </copy>      
    ```

    - 다음 한 줄을 추가합니다. 이미 Environment이 있으면, 그 다음에 한 줄 더 추가합니다.

        ```bash
        <copy>      
        Environment="OLLAMA_HOST=0.0.0.0"
        </copy>    
        ```

    - 재시작합니다.

        ```bash
        <copy>      
        sudo systemctl daemon-reload
        sudo systemctl restart ollama
        </copy>
        ```

    - 0.0.0.0:11434 또는 :::11434로 수신하고 있는 확인합니다.

        ```bash
        <copy>       
        netstat -an | grep 11434
        </copy>   
        ```

## Task 3: Python

1. Python을 설치합니다.

    * Linux - Oracle Linux 8,9

        ```bash
        <copy>
        sudo yum install -y python3.11
        </copy>
        ```

        ```bash
        $ <copy>python3.11 --version</copy>
        Python 3.11.11
        ```

        ```bash
        <copy>
        sudo yum install python3.11-pip -y
        python3.11 -m ensurepip
        pip3.11 install --upgrade pip
        </copy>
        ```

        ```bash
        <copy>
        cat <<EOF >> ~/.bash_profile
        alias pip='pip3.11'
        alias python='python3.11'
        EOF

        source ~/.bash_profile
        </copy>
        ```

    * Windows

        1. https://www.python.org/downloads/ 에서 다운로드 받아 설치합니다.

## Task 4: Git

1. Git을 설치합니다.

    * Linux - Oracle Linux 8,9

        ```bash
        <copy>
        sudo yum install -y git
        </copy>
        ```

## Task 5: Visual Studio Code

1. 사이트에 접속하여, 각 OS에 맞게 설치합니다.

    [Visual Studio Code](https://code.visualstudio.com/)

2. Extensions 탭에서 `Oracle SQL Developer`을 찾아 설치합니다.

    ![Oracle SQL Developer Extension for VSCode](./images/sql-develooper-extension-for-vscode.png)

## Acknowledgements

* **Author** - DongHee Lee, Principal Cloud Engineer, Oracle Korea
* **Last Updated By/Date** - DongHee Lee, October 22, 2025