# Vector Store로서의 Oracle Database 26ai

## Introduction

RAG 구성의 핵심 요소인 Vector Store로 Oracle AI Database 26ai의 Vector Search 기능을 알아보고 실습하는 과정입니다.
Oracle AI Database 26ai을 직접 설치하거나, OCI에서 제공하는 서비스를 이용하는 등 개발환경을 구성할 수 있습니다.

필요한 환경 구성작업을 먼저 진행합니다. 데이터베이스에서 이루어 지는 주요 실습은 함께 제공하는 Oracle SQL Notebook 파일을 통해 진행합니다. 

실습 예상 시간: 10분

### Objectives

이 실습에서는 다음을 수행합니다:

* Oracle AI Database 26ai가 Vector Store로서 제공하는 주요 기능 소개

### 사전 준비 사항

* *Lab1을 반드시 완료할 것*

## Task 1: Oracle Autonomous AI Database 26ai 준비

1. [OCI Console](https://cloud.oracle.com/db/adbs)에 로그인하여, 데이터베이스를 생성합니다.

    - Display name: 예, oracle26aiatp
    - Database name: 예, oracle26aiatp
    - Workload type: Transaction Processing
    - database version: **26ai**

2. 생성된 인스턴스 정보에서 **Database connection**를 클릭후 wallet을 다운로드 받습니다.

3. wallet을 사용할 위치에 복사 또는 업로드합니다.

## Task 2: Visual Studio Code - DB Connection 만들기

1. Visual Studio Code에서 실행합니다.

2. 왼쪽 Activity Bar에서 제일 위 Explorer 아이콘을 클릭하고, Open Folder를 클릭하여, /home/opc/ 폴더를 선택합니다.

3. 다운받은 Wallet 선택을 /home/opc/ 폴더 밑에 드래앤 드랍해서 업로드합니다.

4. 왼쪽 Activity Bar에서 설치한 SQL Developer 아이콘을 클릭합니다.

    ![SQL Developer](./images/activity-bar-sql-developer.png)

5. **Create Connection**을 클릭하여 새 Connection을 추가합니다.

    - Connection Name: `Oracle 26ai - ATP - ADMIN`
    - Role: `Default`
    - Username: `ADMIN`
    - Password: `<YOUR_PASSWORD>`
    - Save Password: *체크*
    - Connection Type: `Cloud Wallet`
    - Configuration File: 다운받은 Wallet 선택

6. 아래 **Test**를 클릭하여, 연결을 확인합니다.

7. **Save**를 클릭하여, 저장합니다.

## Task 3: DB 유저 생성 및 권한 부여

1. connection 우클릭하면, **SQL Worksheet** 또는 **SQLcl**을 실행할 수 있습니다. 이후 실습과정의 설명에 따라 *SQL Worksheet* 또는 *SQLcl*을 실행하여, 명령을 수행할 것입니다.

    ![Connection](./images/sql-developer-connection-atp.png)

2. SQL Worksheet에서 vector 유저 생성 및 권한 부여합니다. `<YOUR_PASSWORD>`는 각자 사용하는 값으로 변경

    ```sql
    <copy>
    --CREATE TABLESPACE USERS DATAFILE 'USERS' SIZE 64M AUTOEXTEND ON;
    CREATE USER vector IDENTIFIED BY <YOUR_PASSWORD> DEFAULT TABLESPACE users TEMPORARY TABLESPACE temp QUOTA UNLIMITED ON users;
    GRANT CONNECT, RESOURCE TO vector;
    GRANT execute on sys.dbms_lock TO vector;

    -- dba_directories 테이블 접근 권한 부여
    GRANT SELECT_CATALOG_ROLE TO vector;

    -- ONNX 모델 업로드 권한 부여
    GRANT CREATE MINING MODEL TO vector;
    CREATE OR REPLACE DIRECTORY AI_ASSETS_DIR as 'AI_ASSETS_DIR';
    GRANT READ,WRITE ON DIRECTORY AI_ASSETS_DIR to vector;

    -- Oracle Text - KOREAN_MORPH_LEXER 사용하기 위해 권한 부여
    GRANT EXECUTE ON CTXSYS.CTX_DDL TO vector;

    -- OCI 서비스 접속을 위한 Credential 생성 권한 부여
    --GRANT CREATE CREDENTIAL TO vector;
    GRANT DB_DEVELOPER_ROLE TO vector;
    GRANT EXECUTE ON DBMS_CLOUD TO vector;
    GRANT execute on DBMS_CLOUD_AI to vector;
    </copy>
    ```

4. DB내에서 외부 Embedding 모델을 API로 호출하기 위해서는 네트워크 접근 허용을 설정해야 합니다. 다음 명령으로 생성한 vector 유저에게 허용합니다.

    ```shell
    <copy>
    BEGIN
       DBMS_NETWORK_ACL_ADMIN.APPEND_HOST_ACE(
             host => '*',
             ace =>  xs$ace_type( privilege_list => xs$name_list('http'),
                                  principal_name => 'VECTOR',
                                  principal_type => xs_acl.ptype_db));
    END;
    /
    </copy>
    ```

5. 만든 connection을 우클릭하고 **Clone**을 클릭하여, vector 유저를 위한 connection도 생성합니다.

    - *Connection Name*: `Oracle 26ai - ATP - vector`
    - Role: `Default`
    - *Username*: `vector`
    - Password: `<YOUR_PASSWORD>`
    - Save Password: *체크*
    - Connection Type: `Cloud Wallet`
    - Configuration File: 다운받은 Wallet 선택    

7. 아래 **Test**를 클릭하여, 연결을 확인하고, **Save**를 클릭하여, 저장합니다.

8. 새 connection 우클릭하면, **SQL Worksheet** 또는 **SQLcl**을 실행합니다.

    ```sql
    SQL> <copy>show user</copy>
    USER is "VECTOR"
    ```

6. 외부 호출이 되는지 확인합니다.

    ```sql
    SQL> <copy>SELECT UTL_HTTP.REQUEST(url => 'https://www.oracle.com/') FROM dual;</copy>
    ```

## Task 4: Credential 생성

데이터베이스에서 OCI Object Storage 또는 OCI Generative AI 서비스 호출 등 OCI 자원에 접근하기 위해 Credential을 먼저 생성해야 합니다.

1. OCI 자원에 접근하기 위해 사용하는 OCI IAM 유저에 대한 API key을 생성합니다. 이미 있는 경우, 기존 정보를 사용합니다.

    [Working with API Keys](https://docs.oracle.com/en-us/iaas/Content/Identity/access/working-with-console-passwords-and-API-keys.htm)

2. API Key를 포함한 연결시 사용할 다음 정보를 확인합니다.

    - "user_ocid"
    - "tenancy_ocid"
    - "compartment_ocid"
    - "private_key"
    - "fingerprint"

3. `private_key` (예, `~/.oci/oci_api_key.pem`)를 한줄 텍스트로 변경합니다.

    ```shell
    <copy>awk 'NF {sub(/\r/, ""); printf "%s\\n",$0;}' ~/.oci/oci_api_key.pem</copy>
    ```

    - 실행예시: _결과 문자열을 수정없이 그대로 복사해서 사용합니다_

        ```shell
        $ awk 'NF {sub(/\r/, ""); printf "%s\\n",$0;}' ~/.oci/oci_api_key.pem
        -----BEGIN RSA PRIVATE KEY-----\nMIIE........m84M=\n-----END RSA PRIVATE KEY-----\nOCI_API_KEY\n
        ```

4. API Key 정보를 사용하여 OCI_CRED 이름으로 Credential을 생성합니다.

    ```shell
    <copy>    
    declare
        jo json_object_t;

    begin
        jo := json_object_t();

        jo.put('user_ocid', '<user ocid>');
        jo.put('tenancy_ocid', '<tenancy ocid>');
        jo.put('compartment_ocid', '<compartment ocid>');
        jo.put('fingerprint', '<fingerprint>');
        jo.put('private_key', '<private key>');

        dbms_vector.create_credential(
            credential_name => 'OCI_CRED',
            params          => json(jo.to_string)
        );
    end;
    /
    </copy>    
    ```

    - 실행예시

        ```shell
        declare
            jo json_object_t;

        begin
            jo := json_object_t();

            jo.put('user_ocid', 'ocid1.user.oc1.....');
            jo.put('tenancy_ocid', 'ocid1.tenancy.oc1.....');
            jo.put('compartment_ocid', 'ocid1.compartment.oc1.....');
            jo.put('fingerprint', '31:8c:..');    
            jo.put('private_key', '-----BEGIN RSA PRIVATE KEY-----\nMIIE........m84M=\n-----END RSA PRIVATE KEY-----\nOCI_API_KEY\n');

            dbms_vector.create_credential(
                credential_name => 'OCI_CRED',
                params          => json(jo.to_string)
            );
        end;
        /
        ```

5. 생성결과를 확인합니다.

    ```shell
    <copy>    
    SELECT owner, credential_name, username
    FROM all_credentials
    ORDER BY owner, credential_name, username;
    </copy>    
    ```

    - 잘못 생성한 경우 아래 명령으로 삭제합니다.

        ```shell
        <copy>    
        BEGIN
        dbms_vector.DROP_CREDENTIAL(credential_name => 'OCI_CRED');
        EXCEPTION
        WHEN OTHERS THEN NULL;
        END;
        /
        </copy>    
        ```

6. Credential이 동작하는 지 테스트로 Bucket을 조회해 봅니다.

    ```shell
    <copy>    
    SELECT * FROM DBMS_CLOUD.LIST_OBJECTS('OCI_CRED', 'https://objectstorage.{region}.oraclecloud.com/n/{namespace}/b/{bucket_name}/o/');
    </copy>    
    ```

    - 예, 

        ```shell
        <copy>    
        SELECT * FROM DBMS_CLOUD.LIST_OBJECTS('OCI_CRED', 'https://objectstorage.us-chicago-1.oraclecloud.com/n/apackrsct01/b/oravs-bucket/o/');
        </copy>    
        ```    
    



## Task 5: Oracle AI Database 26ai Vector Search 주요 기능 알아보기

1. 준비된 환경(my-devday VM 또는 로컬환경)의 터미널 또는 명령창에서 진행합니다. 실습 코드를 다운로드 받습니다.

    ```shell
    <copy>
    git clone https://github.com/TheKoguryo/oracle-devday.git
    </copy>
    ```

2. 데이터 파일을 압축 해제 합니다.

    ```shell
    <copy>    
    cd oracle-devday/data/
    unzip DATAGO_SEOUL_2022.RSTR_INFO_KOREAN_10000_cohere.embed-v4.0.zip
    unzip DATAGO_SEOUL_2022.RSTR_INFO_KOREAN.zip
    </copy>    
    ```

3. Visual Studio Code에서 다운받은 실습 코드 폴더를 엽니다.

    - **File** 탭 > **Open Folder...** > **oracle-devday** 선택

    - 경고 창이 뜨는 신뢰한다고 *체크* 후 *Yes, I trust the authors*를 선택합니다.

4. notebooks 폴더 밑에 SQL Notebook(26ai-vector-search-lab*-atp*.sqlnb) 파일을 엽니다.

    ![SQL Notebook](./images/26ai-vector-search-lab-atp.sqlnb.png)

5. 이제 오른쪽에 열린 *SQL Notebook을 따라 순서대로 진행하면 됩니다.*

    - SQL Notebook은 Jupyter Notebook과 비슷합니다. Python 대신 SQL, PL/SQL을 실행할 수 있습니다.

    - 노트북을 따라 진행하고 PL/SQL Code 부분은 왼쪽 화살표를 클릭하면, 현재 연결된 connection에서 실행하고 그 아래에 결과가 표시됩니다.

        ![Execute Shell](./images/execute-cell.png)

## Acknowledgements

* **Author** - DongHee Lee, Principal Cloud Engineer, Oracle Korea
* **Last Updated By/Date** - DongHee Lee, November 6, 2025
